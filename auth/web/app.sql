\if :{?auth_web_app_sql}
\else
\set auth_web_app_sql true

    create function auth.web_apps(
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
        ret = jsonb_object_agg(a.app_id, a)
            from auth_.app a;

        select * from web_response_t(ret) into $3, $4;
    end;
    $$;

    comment on function auth.web_apps(jsonb, jsonb)
        is 'to find related apps';


    create function auth.web_app_set(
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
                app (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }'))))
    $$;

    comment on function auth.web_app_set(jsonb, jsonb)
        is 'sets an app (auth_.app).';


    create function auth.web_app_delete(
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
            delete(
                app(
                    web_request_t($1, $2, '{
                        "is-sys"
                    }')->>'app_id')))
    $$;

    comment on function auth.web_app_delete(jsonb, jsonb)
        is 'deletes an app (auth_.app).';


\if :{?test}

    create function tests.test_auth_web_app_sql()
        returns setof text
        language plpgsql
        set search_path=auth, public
    as $$
    declare
        head jsonb = web_headers_t_as('test#sys');
        a jsonb;
    begin
        a = res from web_apps('{}'::jsonb, head);
        return next ok(
            a ? 'auth' and a ? 'test',
            'has applications');

        a = res from web_app_set(
            '{
                "app_id": "test2",
                "name": "test2"
            }'::jsonb, head);
        -- call auth.debug(res);
        a = res from web_apps('{}'::jsonb, head);
        return next ok(a ? 'test2', 'can create an app');

        a = res from web_app_delete(
            '{
                "app_id": "test2"
            }'::jsonb, head);
        a = res from web_apps('{}'::jsonb, head);
        return next ok(not (a ? 'test2'), 'can delete an app');
    end;
    $$;

\endif



\endif
