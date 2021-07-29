-- a config is a generic key-values for user
-- it can be used profile

-- used_ts can determine expired session
create table auth.config (
    id text primary key default uuid_generate_v4()::text,
    ns text not null,
    key ltree not null,
    val jsonb,
    unique (ns, key)
);

-- used_ts can determine expired session
create table auth.config_value (
    id text not null references auth.config (id) on delete cascade,
    usr text not null,
    val jsonb,
    primary key (id, usr)
);

------------------------------------------------------------------------------
-- adds new key
create function auth.new_config (
    key_ ltree,
    val_ jsonb,
    ns_ text default coalesce(current_setting('auth.namespace', true), 'test')
)
returns auth.config as $$
    insert into auth.config (ns, key, val)
    values (ns_, key_, val_)
    on conflict (ns, key)
        do update set val=val_
    returning *
$$ language sql security definer;

------------------------------------------------------------------------------
-- removes a key

create function auth.end_config (
    key_ ltree,
    ns_ text default coalesce(current_setting('auth.namespace', true), 'test')
)
returns auth.config as $$
    delete from auth.config
    where ns = ns_ and key = key_
    returning *
$$ language sql security definer;

------------------------------------------------------------------------------
-- returns id (stable)

create function auth.get_config_id (
    key_ ltree,
    ns_ text default coalesce(current_setting('auth.namespace', true), 'test')
)
returns text as $$
    select id from auth.config where ns=ns_ and key=key_
$$ language sql stable security definer;

------------------------------------------------------------------------------
-- sets config data

create function auth.set_config (
    key_ ltree,
    usr_ text,
    val_ jsonb,
    ns_ text default coalesce(current_setting('auth.namespace', true), 'test')
)
returns boolean as $$
    with insertion as (
        insert into auth.config_value (id, usr, val)
        values (auth.get_config_id(key_, ns_), usr_, val_)
        on conflict (id, usr)
            do update set val = val_
        returning *
    )
    select exists (select 1 from insertion d);
$$ language sql security definer;


------------------------------------------------------------------------------
-- removes config data of a user

create function auth.set_config (
    key_ ltree,
    usr_ text,
    ns_ text default coalesce(current_setting('auth.namespace', true), 'test')
)
returns boolean as $$
    with deletion as (
        delete from auth.config_value
        where id = auth.get_config_id(key_,ns_) and usr=usr_
        returning *
    )
    select exists (select 1 from deletion d);
$$ language sql security definer;

------------------------------------------------------------------------------
-- get the config data

create function auth.get_config (
    usr_ text default null,
    key_ text default '*',
    ns_ text default coalesce(current_setting('auth.namespace', true), 'test')
)
returns jsonb as $$

    select jsonb_object_agg(k.key, coalesce(v.val, k.val))
    from (
        select k.*
        from auth.config k,
            (select unnest (string_to_array(key_, ','))) as keys (k)
        where k.ns = ns_ and k.key ~ (keys.k::lquery)
    ) k
    left outer join auth.config_value v on v.id = k.id and v.usr=usr_;
$$ language sql security definer;


------------------------------------------------------------------------------
-- some test
\if :test
    create or replace function tests.test_auth_config() returns setof text as $$
    declare
        a jsonb;
    begin
        perform set_config('auth.namespace', 'test', true);

        perform auth.new_config('test.aaa', to_jsonb(111));
        perform auth.new_config('test.bbb', to_jsonb(222));
        perform auth.set_config('test.bbb', 'ccc', to_jsonb(333));

        -- gets all default value
        a = auth.get_config();
        return next ok(a->>'test.aaa'='111' and a->>'test.bbb'='222', 'gets all default');

        -- gets user specific values
        a = auth.get_config('ccc');
        return next ok(a->>'test.aaa'='111' and a->>'test.bbb'='333', 'gets user values');

        -- updates a config for a user
        perform auth.set_config('test.bbb', 'ccc', to_jsonb(444));
        a = auth.get_config('ccc');
        return next ok(a->>'test.aaa'='111' and a->>'test.bbb'='444', 'updates existing value');

        -- deletes a config of a user
        perform auth.set_config('test.bbb', 'ccc');
        a = auth.get_config('ccc');
        return next ok(a->>'test.aaa'='111' and a->>'test.bbb'='222', 'deletes existing value');

        -- removes a global config key
        perform auth.end_config('test.bbb');
        a = auth.get_config('ccc');
        return next ok((select array_agg(ks) from jsonb_object_keys(a) ks) = array['test.aaa'], 'deletes a key');

        perform auth.new_config('test2.aaa', to_jsonb(100));
        a = auth.get_config();
        return next ok((select array_agg(ks) from jsonb_object_keys(a) ks) = array['test.aaa', 'test2.aaa'], 'gets all key');
        a = auth.get_config(null, 'test.*');
        return next ok((select array_agg(ks) from jsonb_object_keys(a) ks) = array['test.aaa'], 'gets specified keys');
        a = auth.get_config(null, 'test2.*');
        return next ok((select array_agg(ks) from jsonb_object_keys(a) ks) = array['test2.aaa'], 'gets specified keys');

    end;
    $$ language plpgsql;
\endif



------------------------------------------------------------------------------
-- possible future improvements
-- add kind to key
-- add validation for kind


