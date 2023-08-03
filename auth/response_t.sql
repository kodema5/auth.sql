\if :{?auth_response_t_sql}
\else
\set auth_response_t_sql true
-- response_t post process results

\ir util/debug.sql
\ir header_t.sql

    create type auth.response_option_t as (
        is_add_header boolean,
        is_reset_env boolean,
        end_tz timestamp with time zone
    );

    create function auth.response_option_t (
        is_add_header boolean default true,
        is_reset_env boolean default true
    )
        returns auth.response_option_t
        language sql
        security definer
        stable
    as $$
        select (
            is_add_header,
            is_reset_env,
            clock_timestamp()
        )::auth.response_option_t
    $$;

    create function auth.response_t(
        res_ anyelement,
        opt_ auth.response_option_t default auth.response_option_t()
    )
        returns jsonb
        language plpgsql
        security definer
        stable
    as $$
    declare
        res jsonb = to_jsonb(res_);
        env auth.env_t = auth.env_t();
        is_web_api boolean = coalesce(
            nullif(current_setting('auth.web_api', true), ''),
            'f')::boolean;
    begin
        if is_web_api then
            return jsonb_strip_nulls(res);
        end if;


        -- adds _headers authorization tag
        if opt_.is_add_header and env.session_id is not null
        then
            res = (select case
                when jsonb_typeof(res) <> 'object'
                    then jsonb_build_object('returns', res)
                else coalesce(res, '{}')
                end
            );

            res = res || auth.header_t(env.session_id);
        end if;

        -- reset env is typically for individual web-api
        if opt_.is_reset_env
        then
            env = auth.env_t(null);
        end if;

        return jsonb_strip_nulls(res);
    end;
    $$;

    comment on function auth.response_t(anyelement,auth.response_option_t)
        is 'post-process web-response';

\endif
