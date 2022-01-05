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
        and (value)::text = 'null';

    return jsonb_build_object('setting', res);
end;
$$ language plpgsql;



\if :test
    create function tests.test_auth_setting() returns setof text as $$
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
    $$ language plpgsql;

\endif