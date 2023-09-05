\if :{?auth_web_response_t_sql}
\else
\set auth_web_response_t_sql true

    create function auth.web_response_t (
        ret anyelement,
        is_set_headers boolean default false,
        is_reset_env boolean
            default coalesce(
                nullif(current_setting('auth.web_response_t.is_reset_env', true), ''),
            't')::boolean,
        out res jsonb,
        out res_ jsonb
    )
        language plpgsql
        security definer
        stable
    as $$
    declare
        env auth.env_t;
    begin
        res = jsonb_strip_nulls(to_jsonb(ret));

        if is_set_headers then
            env = auth.env_t();
            res_ = auth.web_headers_t(env.session_id);
        end if;

        if is_reset_env then
            perform auth.env_t(null);
        end if;
    end;
    $$;

\endif
