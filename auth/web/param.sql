\if :{?auth_web_param_sql}
\else
\set auth_web_param_sql true

    create function auth.web_params(jsonb)
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
        env env_t = env_t();
        res jsonb;
    begin
        res = jsonb_object_agg(a.param_id, a)
            from auth_.param a;

        return response_t(res);
    end;
    $$;

    comment on function auth.web_params(jsonb)
        is 'to find related params';


    create function auth.web_param_set(jsonb)
        returns jsonb
        language plpgsql
        security definer
        strict
        set search_path=auth, public
    as $$
    declare
        req jsonb = request_t($1);
        prm auth_.param = param(req);
    begin
        return response_t(set(prm));
    end;
    $$;

    comment on function auth.web_param_set(jsonb)
        is 'sets an param (auth_.param).';


    create function auth.web_param_delete(jsonb)
        returns jsonb
        language plpgsql
        security definer
        strict
        set search_path=auth, public
    as $$
    declare
        req jsonb = request_t($1);
    begin
        return response_t(delete(param(req)));
    end;
    $$;

    comment on function auth.web_param_delete(jsonb)
        is 'deletes an param (auth_.param).';


\if :{?test}

    create function tests.test_auth_web_param_sql() returns setof text language plpgsql
    set search_path=auth, public
    as $$
    declare
        res jsonb;
    begin
        res = web_params(header_t_as('test::sys'));
        return next ok(
            res ? 'test::test',
            'able to retrieve param');

        res = web_param_set(
            auth.header_t_as('test::sys') ||
            '{
                "app_id": "test",
                "name": "test2",
                "description":"test2",
                "value":true
            }');
        res = web_params(header_t_as('test::sys'));
        return next ok(res ? 'test::test2', 'can create an param');


        res = web_param_set(
            auth.header_t_as('test::sys') ||
            '{
                "param_id": "test::test2",
                "description":"test2b"
            }');
        res = web_params(header_t_as('test::sys'));
        return next ok(
            res ? 'test::test2'
            and res->'test::test2'->>'description' = 'test2b'
            and res->'test::test2'->>'value' = 'true',
            'can update param');


        res = web_param_delete(
            auth.header_t_as('test::sys') ||
            '{
                "param_id": "test::test2"
            }');

        res = web_params(header_t_as('test::sys'));
        return next ok(not (res ? 'test::test2'), 'can delete an param');
    end;
    $$;

\endif

\endif
