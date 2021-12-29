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
