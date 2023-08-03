\if :{?auth_web_auth_sql}
\else
\set auth_web_auth_sql true

    create function auth.web_auths(jsonb)
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
        res = jsonb_object_agg(a.auth_id, a)
            from auth_.auth a;

        return response_t(res);
    end;
    $$;

    create function auth.web_auth_set(jsonb)
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
        auth auth_.auth = auth(req);
    begin
        return response_t(set(auth));
    end;
    $$;


    create function auth.web_auth_delete(jsonb)
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
        return response_t(delete(auth(req->>'auth_id')));
    end;
    $$;


\if :{?test}

    create function tests.test_auth_web_auth_sql() returns setof text language plpgsql
    set search_path=auth, public
    as $$
    declare
        res jsonb;
    begin
        res = web_auth_set(
            auth.header_t_as('test::sys') ||
            '{
                "auth_id": "is-foo",
                "path": "$.auth.is_foo"
            }');
        res = web_auths(header_t_as('test::sys'));
        return next ok(res ? 'is-foo', 'can create auth');

        res = web_auth_set(
            auth.header_t_as('test::sys') ||
            '{
                "auth_id": "is-foo",
                "path": "$.auth.is_bar"
            }');
        res = web_auths(header_t_as('test::sys'));
        return next ok(res->'is-foo'->>'path' = '$.auth.is_bar'::jsonpath::text, 'can update auth');

        res = web_auth_delete(
            auth.header_t_as('test::sys') ||
            '{
                "auth_id": "is-foo"
            }');
        res = web_auths(header_t_as('test::sys'));
        return next ok(not (res ? 'is-foo'), 'can delete auth');
    end;
    $$;

\endif



\endif
