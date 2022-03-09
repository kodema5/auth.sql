
create type auth.web_setting_put_it as (
    _auth auth.auth_t,
    setting jsonb
);


create type auth.web_setting_put_t as (
    setting jsonb
);


create function auth.web_setting_put(
    it auth.web_setting_put_it
)
    returns auth.web_setting_put_t
    language plpgsql
    security definer
as $$
declare
    a auth.web_setting_put_t;
begin
    with updated as (
        insert into auth_.setting_user (user_id, key, value)
            (
                select (it._auth).user_id, s.key::ltree, s.value
                from jsonb_each(it.setting) s
                join auth_.setting ss on ss.key = s.key::ltree
            )
        on conflict (user_id, key)
        do update set value = excluded.value
        returning *
    )
    select jsonb_object_agg(u.key, u.value)
    into a.setting
    from updated u;


    delete from auth_.setting_user
    where user_id = (it._auth).user_id
        and (value)::text = 'null';

    return a;
end;
$$;


create function auth.web_setting_put (
    req jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select to_jsonb(auth.web_setting_put(
        jsonb_populate_record(
            null::auth.web_setting_put_it,
            auth.auth(req))
    ))
$$;



\if :test
    create function tests.test_auth_web_setting_put()
        returns setof text
        language plpgsql
    as $$
    declare
        sid jsonb = tests.session_as_foo_user();
        a jsonb;
    begin
        a = sid || jsonb_build_object('setting', jsonb_build_object(
            'test.a', 1, -- override
            'test.x', 2  -- unknown setting
        ));
        a = auth.web_setting_put(a);
        a = auth.web_setting_get(sid || jsonb_build_object('keys', jsonb_build_array('test.*')));
        return next ok(a->'setting'->>'test.a' = '1', 'able to update');
        return next ok(a->'setting'->>'test.x' is null, 'ignores unknown value');

        a = sid || jsonb_build_object('setting', jsonb_build_object(
            'test.a', null -- removes
        ));
        a = auth.web_setting_put(a);
        a = auth.web_setting_get(sid || jsonb_build_object('keys', jsonb_build_array('test.*')));
        return next ok(a->'setting'->>'test.a' = '100', 'removes override');
    end;
    $$;
\endif