\if :{?auth_web_app_sql}
\else
\set auth_web_app_sql true

    create function auth.web_apps(jsonb)
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
        res jsonb;
    begin
        res = jsonb_object_agg(a.app_id, a)
            from auth_.app a;

        return response_t(res);
    end;
    $$;

    comment on function auth.web_apps(jsonb)
        is 'to find related apps';


    create function auth.web_app_set(jsonb)
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
        app auth_.app = app(req);
    begin
        return response_t(set(app));
    end;
    $$;

    comment on function auth.web_app_set(jsonb)
        is 'sets an app (auth_.app).';


    create function auth.web_app_delete(jsonb)
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
        return response_t(delete(app(req->>'app_id')));
    end;
    $$;

    comment on function auth.web_app_delete(jsonb)
        is 'deletes an app (auth_.app).';

\if :{?test}

    create function tests.test_auth_web_app_sql() returns setof text language plpgsql
    set search_path=auth, public
    as $$
    declare
        res jsonb;
    begin
        res = web_apps(header_t_as('test::sys'));
        return next ok(
            res ? 'auth' and res ? 'test',
            'has applications');

        res = web_app_set(
            auth.header_t_as('test::sys') ||
            '{
                "app_id": "test2",
                "name": "test2"
            }');
        -- call auth.debug(res);

        res = web_apps(header_t_as('test::sys'));
        return next ok(res ? 'test2', 'can create an app');

        res = web_app_delete(
            auth.header_t_as('test::sys') ||
            '{
                "app_id": "test2"
            }');

        res = web_apps(header_t_as('test::sys'));
        return next ok(not (res ? 'test2'), 'can delete an app');
    end;
    $$;

\endif



\endif
