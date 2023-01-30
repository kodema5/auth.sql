
drop type if exists web.user_data_it cascade;
create type web.user_data_it as (
    delete text[],
    set jsonb, -- { [key] = value,... }
    get text[]
);

create or replace function web.user_data (
    it web.user_data_it
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    uid text = util.get_config('session.user_id');
begin
    if uid=''
    then
        raise exception 'web.user_data.unrecognized_user';
    end if;

    return "user".data(
        uid,
        it.set,
        it.get,
        it.delete
    );
end;
$$;

create or replace function web.user_data (
    it jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select web.user_data(jsonb_populate_record(
        null::web.user_data_it,
        session.auth(it)
    ))
$$;

\if :test
    create function tests.test_web_user_data()
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
        res = web.user_data(req);

        req = s || jsonb_build_object(
            'delete', array['bar']::text[],
            'get', array['foo', 'bar', 'baz']::text[]
        );
        res = web.user_data(req);



        return next ok((
            select array_agg(a)
            from jsonb_object_keys(res) a
        ) = array['baz', 'foo'],
        'able to set, get, delete session-data');

        perform session.end();
    end;
    $$;
\endif


