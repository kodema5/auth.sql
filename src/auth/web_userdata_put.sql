create type auth.web_userdata_put_it as (
    _auth auth.auth_t,
    userdata jsonb
);

create type auth.web_userdata_put_t as (
    userdata jsonb
);

create function auth.web_userdata_put(
    it auth.web_userdata_put_it
)
returns auth.web_userdata_put_t
as $$
declare
    a auth.web_userdata_put_t;
begin
    with updated as (
        insert into auth_.userdata (user_id, key, value)
            (
                select (it._auth).user_id, s.key::ltree, s.value
                from jsonb_each(it.userdata) s
            )
        on conflict (user_id, key)
        do update set value = excluded.value
        returning *
    )
    select jsonb_object_agg(u.key, u.value)
    into a.userdata
    from updated u;

    delete from auth_.userdata
    where user_id = (it._auth).user_id
    and (value)::text = 'null';

    return a;
end;
$$ language plpgsql;


create function auth.web_userdata_put(req jsonb)
returns jsonb as $$
    select to_jsonb(auth.web_userdata_put(
        jsonb_populate_record(
            null::auth.web_userdata_put_it,
            auth.auth(req))
    ))
$$ language sql stable;


\if :test
    create function tests.test_auth_web_userdata() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_user();
        a jsonb;
    begin
        a = sid || jsonb_build_object('userdata', jsonb_build_object(
            'test.a', 1, -- override
            'test.x', 2  -- unknown setting
        ));
        a = auth.web_userdata_put(a);
        a = auth.web_userdata_get(sid || jsonb_build_object('keys', jsonb_build_array('test.*')));
        return next ok(a->'userdata'->>'test.a' = '1', 'able to add');
        return next ok(a->'userdata'->>'test.x' = '2', 'able to add');

        a = sid || jsonb_build_object('userdata', jsonb_build_object(
            'test.a', null, -- removes
            'test.x', 3
        ));
        a = auth.web_userdata_put(a);
        a = auth.web_userdata_get(sid || jsonb_build_object('keys', jsonb_build_array('test.*')));
        return next ok(a->'userdata'->>'test.a' is null, 'removes userdata');
        return next ok(a->'userdata'->>'test.x' = '3', 'overrides userdata');
    end;
    $$ language plpgsql;

\endif