\if :{?auth_web_brand_sql}
\else
\set auth_web_brand_sql true

    create function auth.web_brands(
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
        ret = jsonb_object_agg(a.brand_id, a)
            from auth_.brand a;

        select *
        from web_response_t(ret)
        into $3, $4;
    end;
    $$;


    create function auth.web_brand_set(
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
                brand (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }'))))
    $$;


    create function auth.web_brand_delete(
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
                brand (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }')->>'brand_id')))
    $$;


\if :{?test}

    create function tests.test_auth_web_brand_sql()
        returns setof text
        language plpgsql
        set search_path=auth, public
    as $$
    declare
        head jsonb = web_headers_t_as('test#sys');
        a jsonb;
    begin
        a = res from web_brand_set('{
            "brand_id": "foo",
            "name":"foo",
            "apps":["auth","test"]
        }'::jsonb, head);
        a = res from web_brands('{}', head);
        return next ok( a ? 'foo', 'can create brand');


        a = res from web_brand_set('{
            "brand_id": "foo",
            "name":"bar",
            "apps":["auth","test2"],
            "services":["dummy"]
        }'::jsonb, head);
        return next ok( texts(a->'apps') = '{"auth"}', 'filters apps');
        return next ok( texts(a->'services') = '{}', 'filters services');
        a = res from web_brands(null, head);
        return next ok( a->'foo'->>'name' = 'bar', 'can update brand');


        a = res from web_brand_delete('{
            "brand_id": "foo"
        }'::jsonb, head);
        a = res from web_brands(null, head);
        return next ok( not (a ? 'foo'), 'can delete brand');

    end;
    $$;


\endif

\endif