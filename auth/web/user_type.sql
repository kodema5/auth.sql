\if :{?auth_web_user_type_sql}
\else
\set auth_web_user_type_sql true
create function auth.web_user_types(jsonb)
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
        res = jsonb_object_agg(a.user_type_id, a)
            from auth_.user_type a;

        return response_t(res);
    end;
    $$;

    create function auth.web_user_type_set(jsonb)
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
        return response_t(set(user_type(req)));
    end;
    $$;

    create function auth.web_user_type_delete(jsonb)
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
        return response_t(delete(user_type(req->>'user_type_id')));
    end;
    $$;

\if :{?test}

    create function tests.test_auth_web_user_type_sql() returns setof text language plpgsql
    set search_path=auth, public
    as $$
    declare
        res jsonb;
        id text;
    begin
        res = web_user_type_set(header_t_as('test::sys') || '{
            "brand_id": "test",
            "name":"foo",
            "apps":["auth","test"]
        }');
        id = res->>'user_type_id';
        res = web_user_types(header_t_as('test::sys'));
        return next ok( res ? id, 'can create user_type');


        res = web_user_type_set(header_t_as('test::sys') || ('{
            "user_type_id": "' || id || '",
            "apps":["auth","test2"],
            "services":["dummy"]
        }')::jsonb);
        return next ok( texts(res->'apps') = '{"auth"}', 'filters apps');
        return next ok( texts(res->'services') = '{}', 'filters services');


        res = web_user_type_delete(header_t_as('test::sys') || ('{
            "user_type_id": "' || id || '"
        }')::jsonb);
        res = web_user_types(header_t_as('test::sys'));
        return next ok( not (res ? 'foo'), 'can delete user_type');

    end;
    $$;


\endif

\endif