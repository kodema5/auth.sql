create type auth_admin.web_settings_get_it as (
    _auth jsonb,
    keys text[], -- default '*'
    namespace text,
    user_id text
);

create type auth_admin.web_settings_get_t as (
    setting jsonb
);

create function auth_admin.web_settings_get(
    it auth_admin.web_settings_get_it)
returns auth_admin.web_settings_get_t
as $$
declare
    a auth_admin.web_settings_get_t;
begin
    select jsonb_object_agg(t.key, jsonb_strip_nulls(to_jsonb(t)))
    into a.setting
    from (
        select aa.key,
            aa.description,
            coalesce(cc.value, bb.value, aa.value) as value,
            aa.value as default_value,
            bb.value as namespace_value,
            cc.value as user_value
        from (select unnest(array['*'])) as keys (k),
        auth_.setting aa
        left outer join auth_.setting_namespace bb
            on bb.key = aa.key
            and bb.ns_id = coalesce(it.namespace, (
                select ns_id
                from auth_.user
                where id=it.user_id))
        left outer join auth_.setting_user cc
            on cc.key = aa.key
            and cc.user_id = it.user_id
        where aa.key ~ (keys.k::lquery)
    ) t;

    return a;
end;
$$ language plpgsql;


create function auth_admin.web_settings_get(req jsonb)
returns jsonb
as $$
    select to_jsonb(auth_admin.web_settings_get(
        jsonb_populate_record(
            null::auth_admin.web_settings_get_it,
            auth_admin.auth(req))
    ))
$$ language sql stable;


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

