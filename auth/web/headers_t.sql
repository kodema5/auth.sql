\if :{?auth_web_headers_t_sql}
\else
\set auth_web_headers_t_sql true


    create type auth.web_headers_t as (
        "authorization" text,
        path text
    );

    create function auth.web_headers_t(
        req_ jsonb
    )
        returns auth.web_headers_t
        language sql
        strict
        security definer
    as $$
        select jsonb_populate_record(
            null::auth.web_headers_t,
            req_
        )
    $$;

    create function auth.web_headers_t(
        sid text
    )
        returns jsonb
        language sql
        security definer
    as $$
        select jsonb_build_object(
            'authorization', sid
        )
    $$;


    create function auth.web_headers_t_as(
        user_id text
    )
        returns jsonb
        language sql
        security definer
    as $$
        select auth.web_headers_t(
            (auth.session(auth.user(user_id))).session_id
        )
    $$;

\endif
