\if :{?auth_web_setting_sql}
\else
\set auth_web_setting_sql true

\ir ../setting.sql

    create function auth.web_settings(jsonb)
        returns jsonb
        language plpgsql
        security definer
        strict
        set search_path=auth, public
    as $$
    declare
        req jsonb = request_t($1, '{
            "is-sys"
        }'::text[]);
    begin
        return response_t((
            select jsonb_object_agg(a.setting_id, a)
            from auth_.setting a
        ));
    end;
    $$;

    create function auth.web_setting_set(jsonb)
        returns jsonb
        language plpgsql
        security definer
        strict
        set search_path=auth, public
    as $$
    declare
        req jsonb = request_t($1, '{
            "is-sys"
        }'::text[]);
        a auth_.setting = setting(req);
    begin
        return response_t(set(a));
    end;
    $$;

    create function auth.web_setting_delete(jsonb)
        returns jsonb
        language plpgsql
        security definer
        strict
        set search_path=auth, public
    as $$
    declare
        req jsonb = request_t($1, '{
            "is-sys"
        }'::text[]);
    begin
        return response_t(delete(setting(req->>'setting_id')));
    end;
    $$;

\if :{?test}
    create function tests.test_auth_web_setting_sql() returns setof text language plpgsql
    set search_path=auth, public
    as $$
    declare
        res jsonb;
        a text;
    begin
        res = web_setting_set(header_t_as('test::sys') ||
            '{
                "typeof": "auth_.user",
                "ref_id": "test::user",
                "app_id": "auth",
                "value": {
                    "sys_access":true
                }
            }');
        a = res->>'setting_id';

        res = web_settings(header_t_as('test::sys'));
        return next ok(
            res ? a and res->a->'value'->>'sys_access' = 'true',
            'can create setting');

        res = web_setting_set(header_t_as('test::sys') ||
            ('{
                "setting_id": "'|| a || '",
                "value": {
                    "sys_access":false
                }
            }')::jsonb);

        res = web_settings(header_t_as('test::sys'));
        return next ok(
            res ? a and res->a->'value'->>'sys_access' = 'false',
            'can update setting');

        res = web_setting_delete(header_t_as('test::sys') ||
            ('{
                "setting_id": "'|| a || '"
            }')::jsonb);

        res = web_settings(header_t_as('test::sys'));
        return next ok(
            not (res ? a),
            'can delete setting');


    end;
    $$;
\endif

\endif
