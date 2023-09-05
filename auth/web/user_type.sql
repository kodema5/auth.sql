\if :{?auth_web_user_type_sql}
\else
\set auth_web_user_type_sql true

    create function auth.web_user_types(
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
        ret = jsonb_object_agg(a.user_type_id, a)
            from auth_.user_type a;

        select *
        from web_response_t(ret) into $3, $4;
    end;
    $$;


    create function auth.web_user_type_set(
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
                user_type (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }'))))
    $$;


    create function auth.web_user_type_delete(
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
                user_type (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }')->>'user_type_id')))
    $$;

\if :{?test}

    create function tests.test_auth_web_user_type_sql()
        returns setof text
        language plpgsql
        set search_path=auth, public
    as $$
    declare
        head jsonb = web_headers_t_as('test#sys');
        a jsonb;
        id text;
    begin
        a = res from web_user_type_set(
            ('{
                "brand_id": "test",
                "name":"foo",
                "apps":["auth","test"]
            }')::jsonb,head);
        id = a->>'user_type_id';
        a = res from web_user_types(null, head);
        return next ok( a ? id, 'can create user_type');


        a = res from web_user_type_set(
            ('{
                "user_type_id": "' || id || '",
                "apps":["auth","test2"],
                "services":["dummy"]
            }')::jsonb, head);
        return next ok(
            texts(a->'apps') = '{"auth"}',
            'filters apps');
        return next ok(
            texts(a->'services') = '{}',
            'filters services');


        a = res from web_user_type_delete(
            ('{
                "user_type_id": "' || id || '"
            }')::jsonb, head);
        a = res from web_user_types(null, head);
        return next ok(
            not (a ? 'foo'),
            'can delete user_type');

    end;
    $$;


\endif

\endif