\if :{?auth_web_service_sql}
\else
\set auth_web_service_sql true

    create function auth.web_services(
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
        ret = coalesce(
                jsonb_object_agg(a.service_id, a),
                '{}')
            from auth_.service a;

        select *
        from web_response_t(ret) into $3, $4;
    end;
    $$;


    create function auth.web_service_set(
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
                service (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }'))))
    $$;

    create function auth.web_service_delete(
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
                service (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }')->>'service_id')))

    $$;

\if :{?test}

    create function tests.test_auth_web_service_sql()
        returns setof text
        language plpgsql
        set search_path=auth, public
    as $$
    declare
        head jsonb = web_headers_t_as('test#sys');
        a jsonb;
    begin
        a = res from web_service_set('{
            "service_id":"foo",
            "name":"bar"
        }', head);
        a = res from web_services(null, head);
        return next ok(a ? 'foo', 'can create service');


        a = res from web_service_set('{
            "service_id":"foo",
            "name":"baz"
        }', head);
        a = res from web_services(null, head);
        return next ok(a -> 'foo' ->>'name' = 'baz', 'can delete service');


        a = res from web_service_delete('{
            "service_id":"foo"
        }', head);
        a = res from web_services(null, head);
        return next ok(not (a ? 'foo'), 'can delete service');
    end;
    $$;


\endif

\endif