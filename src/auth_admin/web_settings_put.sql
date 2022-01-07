
create function auth_admin.delete_setting(key_ ltree) returns void as $$
    delete from auth_.setting where key = key_;
$$ language sql;

create function auth_admin.delete_setting_namespace(ns_id_ text, key_ ltree) returns void as $$
    delete from auth_.setting_namespace where ns_id = ns_id_ and key = key_;
$$ language sql;

create function auth_admin.delete_setting_user(user_id_ text, key_ ltree) returns void as $$
    delete from auth_.setting_user where user_id  = user_id_ and key = key_;
$$ language sql;


create function auth_admin.put_setting(key_ ltree, value_ jsonb, description_ text) returns void as $$
    insert into auth_.setting (key, value, description)
        values (key_, value_, description_)
        on conflict (key)
        do update set
            value = coalesce(excluded.value, setting.value),
            description = coalesce(excluded.description, setting.description);
$$ language sql;

create function auth_admin.put_setting_namespace(ns_id_ text, key_ ltree, value_ jsonb) returns void as $$
    insert into auth_.setting_namespace (ns_id, key, value)
        values (ns_id_, key_, value_)
        on conflict (ns_id, key)
        do update set
            value = coalesce(excluded.value, setting_namespace.value);
$$ language sql;

create function auth_admin.put_setting_user (user_id_ text, key_ ltree, value_ jsonb) returns void as $$
    insert into auth_.setting_user (user_id, key, value)
        values (user_id_, key_, value_)
        on conflict (user_id, key)
        do update set
            value = coalesce(excluded.value, setting_user.value);
$$ language sql;


create type auth_admin.web_settings_put_it as (
    _auth jsonb,
    setting jsonb,  -- new/update: { key: {[key:new_key], [value:new_value], [description:new_description] }}
                    -- delete    : { key: null }
    namespaces text[],
    user_ids text[]
);

create function auth_admin.web_settings_put(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_settings_put_it = jsonb_populate_record(null::auth_admin.web_settings_put_it, auth_admin.auth(req));
    r record;
    v auth_.setting;
    is_ns boolean = it.namespaces is not null and cardinality(it.namespaces)>0;
    is_usr boolean = it.user_ids is not null and cardinality(it.user_ids)>0;
    is_sys boolean = not is_ns and not is_usr;
    is_del boolean;
    t text;
begin
    for r in
        select rs.key, rs.value
        from jsonb_each(it.setting) rs
    loop
        is_del = jsonb_typeof(r.value) = 'null';
        if not is_del then
            if jsonb_typeof(r.value) = 'object' then
                v = jsonb_populate_record(null::auth_.setting, r.value);
            else
                v.value = r.value;
            end if;
        end if;
        v.key = r.key;

        if is_sys then
            if is_del then
                perform auth_admin.delete_setting(v.key);
            else
                perform auth_admin.put_setting(v.key, v.value, v.description);
            end if;
        end if;

        if is_ns then
            foreach t in array it.namespaces loop
                if is_del then
                    perform auth_admin.delete_setting_namespace(t, v.key);
                else
                    perform auth_admin.put_setting_namespace(t, v.key, v.value);
                end if;
            end loop;
        end if;

        if is_usr then
            foreach t in array it.user_ids loop
                if is_del then
                    perform auth_admin.delete_setting_user(t, v.key);
                else
                    perform auth_admin.put_setting_user(t, v.key, v.value);
                end if;
            end loop;
        end if;
    end loop;

    return (select jsonb_build_object('setting', jsonb_object_agg( ss.key, to_jsonb(ss)))
    from auth_.setting ss);

end;
$$ language plpgsql;



\if :test
    create function tests.test_auth_admin_web_settings_put() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_admin();
        a jsonb;
    begin
        a = auth_admin.web_settings_get(sid || jsonb_build_object(
            'key', 'test.*'
        ));
        return next ok(a->'setting'->'test.a' is not null, 'returns settings');

        a = auth_admin.web_settings_put(sid || jsonb_build_object(
            'setting', jsonb_build_object(
                'test.x', jsonb_build_object(
                    'value', 999, 'description', 'xxxx'
                )
            )
        ));
        return next ok(a->'setting'->'test.x'->>'description' = 'xxxx', 'creates new setting');

        a = auth_admin.web_settings_put(sid || jsonb_build_object(
            'setting', jsonb_build_object(
                'test.x', jsonb_build_object(
                    'value', 1000,
                    'description', 'yyyy'
                )
            )
        ));
        return next ok(a->'setting'->'test.x'->>'description' = 'yyyy', 'updates existing setting');

        a = auth_admin.web_settings_put(sid || jsonb_build_object(
            'setting', jsonb_build_object(
                'test.x', null
            )
        ));
        return next ok(a->'setting'->'test.x' is null, 'deletes existing setting');
    end;
    $$ language plpgsql;


    create function tests.test_auth_admin_web_settings_put_namespace() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_admin();
        a jsonb;
    begin
        a = auth_admin.web_settings_get(sid || jsonb_build_object('namespace', 'dev'));
        return next ok (a->'setting'->'test.a'->>'value' = '100', 'gets default value');

        a = auth_admin.web_settings_put(sid || jsonb_build_object(
            'namespaces', array['dev'],
            'setting', jsonb_build_object('test.a', 200)
        ));
        a = auth_admin.web_settings_get(sid || jsonb_build_object('namespace', 'dev'));
        return next ok (a->'setting'->'test.a'->>'value' = '200', 'able to set namespace value');

        a = auth_admin.web_settings_put(sid || jsonb_build_object(
            'namespaces', array['dev'],
            'setting', jsonb_build_object('test.a', 300)
        ));
        a = auth_admin.web_settings_get(sid || jsonb_build_object('namespace', 'dev'));
        return next ok (a->'setting'->'test.a'->>'value' = '300', 'able to update namespace value');

        a = auth_admin.web_settings_put(sid || jsonb_build_object(
            'namespaces', array['dev'],
            'setting', jsonb_build_object('test.a', null)
        ));
        a = auth_admin.web_settings_get(sid || jsonb_build_object('namespace', 'dev'));
        return next ok (a->'setting'->'test.a'->>'value' = '100', 'able to delete namespace value (got default back)');
    end;
    $$ language plpgsql;


    create function tests.test_auth_admin_web_settings_put_user() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_admin();
        uid text = auth.get_user_id('dev', 'foo.user');
        t text;
        a jsonb;
    begin
        a = auth_admin.web_settings_get(sid || jsonb_build_object('user_id', uid));
        return next ok (a->'setting'->'test.a'->>'value' = '100', 'gets default value');

        a = auth_admin.web_settings_put(sid || jsonb_build_object(
            'user_ids', array[uid],
            'setting', jsonb_build_object('test.a', 200)
        ));
        a = auth_admin.web_settings_get(sid || jsonb_build_object('user_id', uid));
        return next ok (a->'setting'->'test.a'->>'value' = '200', 'able to set user value');

        a = auth_admin.web_settings_put(sid || jsonb_build_object(
            'user_ids', array[uid],
            'setting', jsonb_build_object('test.a', 300)
        ));
        a = auth_admin.web_settings_get(sid || jsonb_build_object('user_id', uid));
        return next ok (a->'setting'->'test.a'->>'value' = '300', 'able to update user value');

        a = auth_admin.web_settings_put(sid || jsonb_build_object(
            'user_ids', array[uid],
            'setting', jsonb_build_object('test.a', null)
        ));
        a = auth_admin.web_settings_get(sid || jsonb_build_object('user_id', uid));
        return next ok (a->'setting'->'test.a'->>'value' = '100', 'able to delete user value');

    end;
    $$ language plpgsql;


\endif
