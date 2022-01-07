create type auth_admin.web_settings_get_it as (
    _auth jsonb,
    keys text[], -- default '*'
    namespace text,
    user_id text
);

create function auth_admin.web_settings_get(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_settings_get_it = jsonb_populate_record(null::auth_admin.web_settings_get_it, auth_admin.auth(req));
    res jsonb;
    keys_ text[] = coalesce(it.keys, array['*']);
begin

    return jsonb_build_object(
        'setting',
        (select jsonb_object_agg(s.key, jsonb_strip_nulls(to_jsonb(s)))
        from (
            select a.key,
                a.description,
                coalesce(c.value, b.value, a.value) as value,
                a.value as default_value,
                b.value as namespace_value,
                c.value as user_value
            from (select unnest(array['*'])) as keys (k),
            auth_.setting a
            left outer join auth_.setting_namespace b on b.key = a.key
                and b.ns_id = coalesce(it.namespace, (select ns_id from auth_.user where id=it.user_id))
            left outer join auth_.setting_user c on c.key = a.key and c.user_id = it.user_id
            where a.key ~ (keys.k::lquery)
        ) s)
    );
end;
$$ language plpgsql;


\if :test
    create function tests.test_auth_admin_web_settings_get() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_admin();
        a jsonb;
        t text;
    begin
        a = auth_admin.web_settings_get(sid);
        return next ok(a->'setting'->'test.a' is not null, 'returns settings by default');

        a = auth_admin.web_settings_get(sid || jsonb_build_object(
            'keys', array['test.a']
        ));
        return next ok(a->'setting'->'test.a' is not null, 'returns specified key');

    end;
    $$ language plpgsql;
\endif

