\if :{?auth_web_signoff_sql}
\else
\set auth_web_signoff_sql true

    create function auth.web_signoff(
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
        req jsonb = web_request_t($1, $2);
        env env_t = env_t();
        s auth_.session = delete(session(env.session_id));
    begin
        select *
        from web_response_t(true)
        into $3, $4;
    end;
    $$;

\if :{?test}

    create function tests.test_auth_web_signoff_sql()
        returns setof text
        language plpgsql
        set search_path=auth, public
    as $$
    declare
        head jsonb = web_headers_t_as('test#user');
        a jsonb = res from auth.web_env('{}', head);
    begin
        return next ok(a ? 'session_id', 'has valid session');

        perform auth.web_signoff('{}'::jsonb, head);

        return next throws_ok(
            format('select auth.web_env(%L::jsonb,%L::jsonb)', '{}', head),
            'auth.request_t.unrecognized_session');
    end;
    $$;

\endif



\endif