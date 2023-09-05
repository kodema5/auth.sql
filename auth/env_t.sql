\if :{?auth_env_t_sql}
\else
\set auth_env_t_sql true
-- sets the environment variables for a given session

    create type auth.env_t as (
        session_id text,
        user_id text,
        brand_id text,
        setting jsonb
    );


\ir user.sql

    create function auth.env_t(ses auth_.session)
        returns auth.env_t
        language sql
        security definer
    as $$
        with
        arg_ as (
            select ses,
            auth.user(ses) as usr
        ),
        set_ as (
            select
                set_config('auth.session_id', coalesce((ses).session_id, ''), true),
                set_config('auth.user_id', coalesce((usr).user_id, ''), true),
                set_config('auth.brand_id', coalesce((usr).brand_id, ''), true),
                coalesce((ses).session_id, '') session_id,
                coalesce((usr).user_id, '') user_id,
                coalesce((usr).brand_id, '') brand_id,
                (ses).setting
            from arg_
        )
        select (
            nullif(session_id, ''),
            nullif(user_id, ''),
            nullif(brand_id, ''),
            nullif(setting, '{}')
        )::auth.env_t
        from set_
    $$;

    comment on function auth.env_t(auth_.session)
        is 'sets the environment variables for a session';

\ir session.sql

    create function auth.env_t ()
        returns auth.env_t
        language sql
        security definer
        stable
    as $$
        select (
            nullif(current_setting('auth.session_id', true), ''),
            nullif(current_setting('auth.user_id', true), ''),
            nullif(current_setting('auth.brand_id', true), ''),
            nullif((auth.session()).setting, '{}')
        )::auth.env_t
    $$;

    comment on function auth.env_t()
        is 'returns current environment variables';


\if :{?test}
    create function tests.test_auth_env_t_sql() returns setof text language plpgsql
    as $$
    declare
        s auth_.session;
        e auth.env_t;
    begin
        s = auth.session(auth.user('test#user'));
        e = auth.env_t(s);
        return next ok(not (e.session_id is null),
            'sets env_t');

        e = auth.env_t(null);

        return next ok(e.session_id is null,
            'resets env(s)');
    end;
    $$;

\endif

\endif
