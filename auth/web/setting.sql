\if :{?auth_web_setting_sql}
\else
\set auth_web_setting_sql true

\ir ../setting.sql

    create function auth.web_settings(
        jsonb,
        jsonb default null,
        out res jsonb,
        out res_ jsonb
    )
        language plpgsql
        security definer
        set search_path=auth, public
    as $$
    declare
        req jsonb = web_request_t($1, $2, '{
            "is-sys"
        }');
        ret jsonb;
    begin
        ret = jsonb_object_agg(a.setting_id, a)
            from auth_.setting a;

        select *
        from web_response_t(ret) into $3, $4;
    end;
    $$;


    create function auth.web_setting_set(
        jsonb,
        jsonb default null,
        out res jsonb,
        out res_ jsonb
    )
        language sql
        security definer
        set search_path=auth, public
    as $$
        select *
        from web_response_t (
            set (
                setting (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }'))))
    $$;


    create function auth.web_setting_delete(
        jsonb,
        jsonb default null,
        out res jsonb,
        out res_ jsonb
    )
        language sql
        security definer
        set search_path=auth, public
    as $$
        select *
        from web_response_t (
            delete (
                setting (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }')->>'setting_id')))
    $$;


\if :{?test}
    create function tests.test_auth_web_setting_sql()
        returns setof text
        language plpgsql
        set search_path=auth, public
    as $$
    declare
        head jsonb = web_headers_t_as('test#sys');
        a jsonb;
        t text;
    begin
        a = res from web_setting_set(
            '{
                "typeof": "auth_.user",
                "ref_id": "test#user",
                "app_id": "auth",
                "value": {
                    "sys_access":true
                }
            }', head);
        t = a->>'setting_id';
        a = res from web_settings(null, head);
        return next ok(
            a ? t and a->t->'value'->>'sys_access' = 'true',
            'can create setting');

        a = res from web_setting_set(
            ('{
                "setting_id": "'|| t || '",
                "value": {
                    "sys_access":false
                }
            }')::jsonb, head);
        a = res from web_settings(null, head);
        return next ok(
            a ? t and a->t->'value'->>'sys_access' = 'false',
            'can update setting');


        a = res from web_setting_delete(
            ('{
                "setting_id": "'|| t || '"
            }')::jsonb, head);
        a = res from web_settings(null, head);
        return next ok(
            not (a ? t),
            'can delete setting');

    end;
    $$;
\endif

\endif
