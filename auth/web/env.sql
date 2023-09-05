\if :{?auth_web_env_sql}
\else
\set auth_web_env_sql true

    create function auth.web_env (
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
    begin
        select *
        from web_response_t(env_t())
        into $3, $4;
    end;
    $$;

\endif
