\if :{?auth_header_t_sql}
\else
\set auth_header_t_sql true

    create function auth.header_t(session_id text)
        returns jsonb
        language sql
        security definer
    as $$
        select jsonb_build_object(
            '_headers', jsonb_build_object(
                'authorization',
                session_id
            )
        )
    $$;

    create function auth.header_t_as(user_id text)
        returns jsonb
        language sql
        security definer
    as $$
        select auth.header_t((auth.session(auth.user(user_id))).session_id)
    $$;

\endif
