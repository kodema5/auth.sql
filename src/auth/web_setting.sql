create type auth.web_setting_get_it as (
    _auth auth.auth_t,
    setting_key text -- pass 'prefix.*,prefix.*'
);

create function auth.web_setting_get(req jsonb) returns jsonb as $$
declare
    it auth.web_setting_get_it = jsonb_populate_record(null::auth.web_setting_get_it, auth.auth(req));
begin
    return jsonb_build_object('setting', auth.get_setting(
        coalesce(it.setting_key, '*'),
        (it._auth).namespace,
        (it._auth).user_id
    ));
end;
$$ language plpgsql;



create type auth.web_setting_put_it as (
    _auth auth.auth_t,
    setting jsonb
);

create function auth.web_setting_put(req jsonb) returns jsonb as $$
declare
    it auth.web_setting_put_it = jsonb_populate_record(null::auth.web_setting_put_it, auth.auth(req));
    res jsonb;
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
    into res
    from updated u;

    delete from auth_.setting_user
    where user_id = (it._auth).user_id
    and value is null;

    return jsonb_build_object('setting', res);
end;
$$ language plpgsql;



\if :test
    create function tests.test_auth_setting() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_user();
        res jsonb;
        req jsonb;
        r record;
    begin
        res = auth.web_setting_get(sid || jsonb_build_object('setting_key', 'test.*'));
        return next ok(res->'setting'->>'test.a' = '100', 'has test.a setting = 100');

        res = auth.web_setting_put(sid || jsonb_build_object('setting',
            jsonb_build_object('test.a', 200)
        ));

        res = auth.web_setting_get(sid || jsonb_build_object('setting_key', 'test.*'));
        return next ok(res->'setting'->>'test.a' = '200', 'has test.a setting = 200');

        res = auth.web_setting_put(sid || jsonb_build_object('setting',
            jsonb_build_object('test.a', null)
        ));

        res = auth.web_setting_get(sid || jsonb_build_object('setting_key', 'test.*'));
        return next ok(res->'setting'->>'test.a' is null, 'can reset test.a 100');
    end;
    $$ language plpgsql;

\endif