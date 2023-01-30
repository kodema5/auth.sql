
drop type if exists web.session_data_it cascade;
create type web.session_data_it as (
    delete text[],
    set jsonb, -- { [key] = value,... }
    get text[]
);

create or replace function web.session_data (
    it web.session_data_it
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    sid text = util.get_config('session.session_id');
begin
    if sid=''
    then
        raise exception 'web.session_data.unrecognized_session';
    end if;

    return session.data(
        sid,
        it.set,
        it.get,
        it.delete
    );
end;
$$;

create or replace function web.session_data (
    it jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select web.session_data(jsonb_populate_record(
        null::web.session_data_it,
        session.auth(it)
    ))
$$;

\if :test
    create function tests.test_web_session_data()
        returns setof text
        language plpgsql
    as $$
    declare
        u user_.user = "user".new('foo@example.com','bar');
        s jsonb = session.head(u.id);
        req jsonb;
        res jsonb;
    begin
        req = s || jsonb_build_object(
            'set', jsonb_build_object(
                'foo', jsonb_build_object('a', 1),
                'bar', jsonb_build_object('b', 2),
                'baz', jsonb_build_object('c', 3)
            )
        );
        res = web.session_data(req);

        req = s || jsonb_build_object(
            'delete', array['bar']::text[],
            'get', array['foo', 'bar', 'baz']::text[]
        );
        res = web.session_data(req);



        return next ok((
            select array_agg(a)
            from jsonb_object_keys(res) a
        ) = array['baz', 'foo'],
        'able to set, get, delete session-data');

        perform session.end();
    end;
    $$;
\endif


