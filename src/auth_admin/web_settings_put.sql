create type auth_admin.web_settings_put_it as (
    _auth jsonb,
    setting jsonb -- new/update: { key: {[key:new_key], [value:new_value], [description:new_description] }}
                  -- delete    : { key: null }
);

create function auth_admin.web_settings_put(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_settings_put_it = jsonb_populate_record(null::auth_admin.web_settings_put_it, auth_admin.auth(req));
    r record;
    s auth_.setting;
    v auth_.setting;
begin
   for r in
        select rs.key, rs.value
        from jsonb_each(it.setting) rs
    loop
        if jsonb_typeof(r.value) = 'null' then
            delete from auth_.setting where key = r.key::ltree;
            continue;
        end if;

        v = jsonb_populate_record(null::auth_.setting, r.value);

        select * into s from auth_.setting where key = r.key::ltree;
        if not found then
            insert into auth_.setting (key, value, description)
            values (
                r.key::ltree,
                coalesce(v.value, s.value),
                coalesce(v.description, s.description)
            );
            continue;
        else
            update auth_.setting set
                value = coalesce(v.value, s.value),
                description = coalesce(v.description, s.description)
            where key = r.key::ltree;
            continue;
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
        res jsonb;
    begin
        res = auth_admin.web_settings_get(sid || jsonb_build_object(
            'key', 'test.*'
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
\endif
