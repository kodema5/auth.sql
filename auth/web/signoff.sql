\if :{?auth_web_signoff_sql}
\else
\set auth_web_signoff_sql true

    create function auth.web_signoff(jsonb)
        returns jsonb
        language plpgsql
        security definer
        strict
        set search_path=auth, public
    as $$
    declare
        req jsonb = request_t($1);
        env env_t = env_t();
        s auth_.session = delete(session(env.session_id));
    begin
        perform env_t(null);
        return response_t(true);
    end;
    $$;

\if :{?test}

    create function tests.test_auth_web_signoff_sql() returns setof text language plpgsql
    set search_path=auth, public
    as $$
    declare
        head jsonb = header_t_as('test::user');
        res jsonb = web_env(head);
    begin
        return next ok(res ? 'session_id', 'has valid session');

        res = web_signoff(head);

        return next throws_ok(
            format('select auth.web_env(%L::jsonb)', head),
            'auth.request_t.unrecognized_session');
    end;
    $$;

\endif



\endif