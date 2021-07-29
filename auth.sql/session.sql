------------------------------------------------------------------------------

-- used_ts can determine expired session
create table auth.session (
    id text primary key default md5(uuid_generate_v4()::text),
    usr text not null,
    created_ts bigint default auth.current_ts(),
    used_ts bigint,
    val jsonb
);


-- having variable, one can have server-side states
create table auth.session_var (
    sid text references auth.session (id) on delete cascade,
    key ltree not null,
    val jsonb,
    primary key (sid, key)
);


------------------------------------------------------------------------------
-- creates a session

create function auth.new_session (usr_ text, val_ jsonb default null)
returns text as $$
    with t as (
        insert into auth.session (id, usr, val, used_ts)
        values (default, usr_, val_, auth.current_ts())
        returning *
    )
    select t.id from t; -- into res from s;
$$ language sql security definer;

------------------------------------------------------------------------------
-- ends a session

create function auth.end_session (sid_ text) returns boolean as $$
    with t as (
        delete from auth.session
        where id = sid_
        returning *
    )
    select count(1)>0  from t;
$$ language sql security definer;

------------------------------------------------------------------------------
-- returns a session data

create function auth.get_session (
    sid_ text,
    key_ text default null
) returns jsonb as $$
    with
    base as (
        select coalesce(val, '{}'::jsonb) a
            from auth.session
            where id=sid_
    ),
    stored as (
        select jsonb_object_agg( key, val) a
            from auth.session_var,
            (select unnest (string_to_array(key_, ','))) as keys (k)
            where sid=sid_
            and key ~ (keys.k::lquery)
    )
    select (select coalesce(a, '{}'::jsonb) from base)
        || (select coalesce(a, '{}'::jsonb) from stored)

$$ language sql security definer;


------------------------------------------------------------------------------
-- sets data

create function auth.set_session (
    sid_ text,
    key_ text,
    val_ jsonb
) returns jsonb as $$
    with insertion as (
        insert into auth.session_var (sid, key, val)
        values ( sid_, key_::ltree, val_)
        on conflict (sid, key) do update set val = val_
        returning *
    )
    select jsonb_agg(to_jsonb(t)) from insertion t;
$$ language sql strict security definer;

------------------------------------------------------------------------------
-- cuts data

create function auth.set_session (
    sid_ text,
    key_ text
) returns jsonb as $$
    with deletion as (
        delete from auth.session_var
        where sid = sid_ and key ~ (key_::lquery)
        returning *
    )
    select jsonb_agg(to_jsonb(t)) from deletion t;

$$ language sql security definer;

------------------------------------------------------------------------------
-- use updates last access-field and gets data
-- to be used, as first line in page/call with auth needed

create function auth.use_session (
    sid_ text,
    key_ text default null
) returns jsonb as $$
    with
    update_used_ts as (
        update auth.session
        set used_ts = auth.current_ts()
        where id = sid_
    )
    select auth.get_session(sid_, key_);
$$ language sql security definer;

------------------------------------------------------------------------------
-- using session

\if :test
    create function tests.test_auth_session() returns setof text as $$
    #variable_conflict use_variable
    declare
        a jsonb;
        sid text;
    begin
        perform set_config('auth.namespace', 'test', true);

        -- null checks
        return next ok(auth.use_session(null) is null, 'null check use');
        return next ok(auth.set_session(null, null, null) is null, 'null check set');
        return next ok(auth.set_session(null, null) is null, 'null check empty set');
        return next ok(auth.get_session(null) is null, 'null check get');
        return next ok(auth.end_session(null) = false, 'null check end');

        -- first create data
        sid = auth.new_session('foo', '{"aaa":0}'::jsonb);
        return next ok(sid is not null, 'creates session');
        -- sid = a->>'id';

        -- subsequent calls requiring sid
        a = auth.use_session(sid);
        return next ok(a ? 'aaa', 'use gets base values when null key');

        -- sets session variables
        perform auth.set_session(sid, 'test.aaa', '111'::jsonb);
        perform auth.set_session(sid, 'test.bbb', '222'::jsonb);
        perform auth.set_session(sid, 'test.ccc', null);
        a = auth.get_session(sid, 'test.*');

        -- deletes session variable by not passing value
        perform auth.set_session(sid, 'test.bbb');
        a = auth.get_session(sid, 'test.*');
        return next ok(a ? 'test.aaa' and (not a ? 'test.bbb'), 'deletes key');

        perform auth.set_session(sid, 'test2.ccc', '333'::jsonb);
        perform auth.set_session(sid, 'test3.ddd', '444'::jsonb);

        -- retrieiving variables with multiple keys
        a = auth.get_session(sid, 'test2.*,test3.*');
        return next ok(not (a ? 'test.aaa') and a ? 'test2.ccc' and a ? 'test3.ddd', 'gets multiple keys');

        -- retrievies all variables
        a = auth.get_session(sid, '*');
        return next ok(a ? 'test.aaa' and a ? 'test2.ccc' and a ? 'test3.ddd', 'gets all * keys');

        a = auth.get_session(sid, 'invalid.*');
        return next ok(a ? 'aaa', 'only get base on invalid key');

        -- when session ends
        perform auth.end_session(sid);
        a = auth.get_session(sid, 'test.*');
        return next ok(a is null, 'deletes session');

    end;
    $$ language plpgsql;
\endif


------------------------------------------------------------------------------
-- possible future improvements:
-- auto-partition session table, since usually only active session matters
-- an automation to clean-up "old" sessions
-- a session log can be useful for tracing issue (can be incorporated with use.)
