\if :{?auth_web_param_sql}
\else
\set auth_web_param_sql true

    create function auth.web_params(
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
        ret = jsonb_object_agg(a.param_id, a)
            from auth_.param a;

        select *
        from web_response_t(ret) into $3, $4;
    end;
    $$;

    comment on function auth.web_params(jsonb, jsonb)
        is 'to find related params';


    create function auth.web_param_set(
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
                param (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }'))))
    $$;

    comment on function auth.web_param_set(jsonb, jsonb)
        is 'sets an param (auth_.param).';


    create function auth.web_param_delete(
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
                param (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }'))))
    $$;

    comment on function auth.web_param_delete(jsonb, jsonb)
        is 'deletes an param (auth_.param).';


\if :{?test}

    create function tests.test_auth_web_param_sql()
        returns setof text
        language plpgsql
        set search_path=auth, public
    as $$
    declare
        head jsonb = web_headers_t_as('test#sys');
        a jsonb;
    begin
        a = res from web_params(null, head);
        return next ok(a ? 'test#test', 'able to retrieve param');

        a = res from web_param_set(
            '{
                "app_id": "test",
                "name": "test2",
                "description":"test2",
                "value":true
            }', head);
        a = res from web_params(null, head);
        return next ok(a ? 'test#test2', 'can create an param');


        a = res from web_param_set(
            '{
                "param_id": "test#test2",
                "description":"test2b"
            }', head);
        a = res from web_params(null, head);
        return next ok(
            a ? 'test#test2'
            and a->'test#test2'->>'description' = 'test2b'
            and a->'test#test2'->>'value' = 'true',
            'can update param');


        a = res from web_param_delete(
            '{
                "param_id": "test#test2"
            }', head);

        a = res from web_params(null, head);
        return next ok(not (a ? 'test#test2'), 'can delete an param');
    end;
    $$;

\endif

\endif
