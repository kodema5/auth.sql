\if :{?auth_web_brand_sql}
\else
\set auth_web_brand_sql true

    create function auth.web_brands(jsonb)
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
        res = jsonb_object_agg(a.brand_id, a)
            from auth_.brand a;

        return response_t(res);
    end;
    $$;

    create function auth.web_brand_set(jsonb)
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
        return response_t(set(brand(req)));
    end;
    $$;

    create function auth.web_brand_delete(jsonb)
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
        return response_t(delete(brand(req->>'brand_id')));
    end;
    $$;

\if :{?test}

    create function tests.test_auth_web_brand_sql() returns setof text language plpgsql
    set search_path=auth, public
    as $$
    declare
        res jsonb;
    begin
        res = web_brand_set(header_t_as('test::sys') || '{
            "brand_id": "foo",
            "name":"foo",
            "apps":["auth","test"]
        }');
        res = web_brands(header_t_as('test::sys'));
        return next ok( res ? 'foo', 'can create brand');


        res = web_brand_set(header_t_as('test::sys') || '{
            "brand_id": "foo",
            "name":"bar",
            "apps":["auth","test2"],
            "services":["dummy"]
        }');
        return next ok( texts(res->'apps') = '{"auth"}', 'filters apps');
        return next ok( texts(res->'services') = '{}', 'filters services');
        res = web_brands(header_t_as('test::sys'));
        return next ok( res->'foo'->>'name' = 'bar', 'can update brand');


        res = web_brand_delete(header_t_as('test::sys') || '{
            "brand_id": "foo"
        }');
        res = web_brands(header_t_as('test::sys'));
        return next ok( not (res ? 'foo'), 'can delete brand');

    end;
    $$;


\endif

\endif