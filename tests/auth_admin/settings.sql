
create function tests.test_auth_admin_settings() returns setof text as $$
declare
    sid jsonb = tests.session_as_foo_admin();
    res jsonb;
begin
    res = auth_admin.web_settings_get(sid || jsonb_build_object(
        'setting_key', 'test.*'
    ));
    return next ok(res->'setting'->'test.a' is not null, 'returns settings');

    -- add new
    res = auth_admin.web_settings_put(sid || jsonb_build_object(
        'setting', jsonb_build_object(
            'test.x', jsonb_build_object(
                'value', 999, 'description', 'xxxx'
            )
        )
    ));
    return next ok(res->'setting'->'test.x'->>'description' = 'xxxx', 'creates new setting');

    -- update
    res = auth_admin.web_settings_put(sid || jsonb_build_object(
        'setting', jsonb_build_object(
            'test.x', jsonb_build_object(
                'value', 1000,
                'description', 'yyyy'
            )
        )
    ));
    return next ok(res->'setting'->'test.x'->>'description' = 'yyyy', 'updates existing setting');

    -- delete
    res = auth_admin.web_settings_put(sid || jsonb_build_object(
        'setting', jsonb_build_object(
            'test.x', null
        )
    ));
    return next ok(res->'setting'->'test.x' is null, 'deletes existing setting');
end;
$$ language plpgsql;