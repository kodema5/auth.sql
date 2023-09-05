\if :{?auth_web_auth_sql}
\else
\set auth_web_auth_sql true

    create function auth.web_auths(
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
        ret = jsonb_object_agg(a.auth_id, a)
            from auth_.auth a;

        select *
        from web_response_t(ret) into $3, $4;
    end;
    $$;


    create function auth.web_auth_set(
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
                auth (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }'))))
    $$;


    create function auth.web_auth_delete(
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
                auth (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }')->>'auth_id')))
    $$;


\if :{?test}

    create function tests.test_auth_web_auth_sql()
        returns setof text
        language plpgsql
        set search_path=auth, public
    as $$
    declare
        head jsonb = web_headers_t_as('test#sys');
        a jsonb;
    begin
        a = res from web_auth_set(
            '{
                "auth_id": "is-foo",
                "path": "$.auth.is_foo"
            }'::jsonb,
            head);
        a = res from web_auths('{}'::jsonb, head);
        return next ok(a ? 'is-foo', 'can create auth');

        a = res from web_auth_set(
            '{
                "auth_id": "is-foo",
                "path": "$.auth.is_bar"
            }'::jsonb,
            head);
        a = res from web_auths('{}'::jsonb, head);
        return next ok(a->'is-foo'->>'path' = '$.auth.is_bar'::jsonpath::text, 'can update auth');


        a = res from web_auth_delete(
            '{
                "auth_id": "is-foo"
            }'::jsonb,
            head);
        a = res from web_auths('{}'::jsonb, head);
        return next ok(not (a ? 'is-foo'), 'can delete auth');
    end;
    $$;

\endif



\endif
