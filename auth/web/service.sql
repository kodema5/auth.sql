\if :{?auth_web_service_sql}
\else
\set auth_web_service_sql true

    create function auth.web_services(jsonb)
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
        res = jsonb_object_agg(a.service_id, a)
            from auth_.service a;

        return response_t(res);
    end;
    $$;

    create function auth.web_service_set(jsonb)
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
        svc auth_.service = service(req);
    begin
        return response_t(set(svc));
    end;
    $$;

    create function auth.web_service_delete(jsonb)
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
        return response_t(delete(service(req->>'service_id')));
    end;
    $$;

\if :{?test}

    create function tests.test_auth_web_service_sql() returns setof text language plpgsql
    set search_path=auth, public
    as $$
    declare
        res jsonb;
    begin
        res = web_service_set(header_t_as('test::sys') || '{
            "service_id":"foo",
            "name":"bar"
        }');
        res = web_services(header_t_as('test::sys'));
        return next ok(res ? 'foo', 'can create service');


        res = web_service_set(header_t_as('test::sys') || '{
            "service_id":"foo",
            "name":"baz"
        }');
        res = web_services(header_t_as('test::sys'));
        return next ok(res -> 'foo' ->>'name' = 'baz', 'can delete service');


        res = web_service_delete(header_t_as('test::sys') || '{
            "service_id":"foo"
        }');
        res = web_services(header_t_as('test::sys'));
        return next ok(not (res ? 'foo'), 'can delete service');

    end;
    $$;


\endif

\endif