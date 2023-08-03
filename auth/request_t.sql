\if :{?auth_request_t_sql}
\else
\set auth_request_t_sql true

-- request parses json web-request, sets environments and checks authorization

    create type auth.request_header_t_ as (
        session_id_path jsonpath,
        request_path jsonpath
    );

    create function auth.request_header_t_(
        session_id_path jsonpath default '$._headers.authorization',
        request_path jsonpath default '$._headers.path'
    )
        returns auth.request_header_t_
        language sql
        security definer
        stable
    as $$
        select (
            session_id_path,
            request_path
        )::auth.request_header_t_
    $$;


    create type auth.request_header_t as (
        session_id text,
        path text
    );

    create function auth.request_header_t(
        req_ jsonb,
        opt_ auth.request_header_t_ default auth.request_header_t_()
    )
        returns auth.request_header_t
        language sql
        security definer
        stable
    as $$
        select (
            jsonb_path_query_first(req_, opt_.session_id_path)->>0,
            jsonb_path_query_first(req_, opt_.request_path)->>0
        ):: auth.request_header_t
    $$;

    comment on function auth.request_header_t(jsonb,auth.request_header_t_)
        is 'retrieves data from web request header';



    create type auth.request_option_t as (
        is_session_required boolean,
        auth_paths jsonpath[],
        headers auth.request_header_t_,
        is_debug boolean,
        end_tz timestamp with time zone
    );

    create function auth.request_option_t (
        is_session_required boolean default true,
        auth_paths jsonpath[] default null,
        headers auth.request_header_t_ default auth.request_header_t_(),
        is_debug boolean default false
    )
        returns auth.request_option_t
        language sql
        security definer
        stable
    as $$
        select (
            is_session_required,
            auth_paths,
            headers,
            is_debug,
            clock_timestamp()
        )::auth.request_option_t
    $$;

\ir util/array.sql

    create function auth.request_t(
        req_ jsonb,
        opt_ auth.request_option_t default auth.request_option_t()
    )
        returns jsonb
        language plpgsql
        security definer
    as $$
    declare
        -- TODO: possible issue, if connection is shared.
        -- when a prior transcation raised an exception, will session variables in connection be reset?
        -- if not, will the current transaction get invalid session-variables?
        -- back-log: reset can be first done in the web_api, not for other web yet
        --
        env auth.env_t = auth.env_t();
    begin

        if opt_.is_session_required and env.session_id is null
        then
        declare
            h auth.request_header_t = auth.request_header_t(req_, opt_.headers);
            sid text = h.session_id;
            s auth_.session;
        begin
            if sid is null then
                raise exception 'auth.request_t.missing_session';
            end if;

            s = auth.session(sid);
            if s is null then
                raise exception 'auth.request_t.unrecognized_session';
            end if;

            -- initialize session
            env = auth.env_t(s);

            if env.session_id is null then
                raise exception 'auth.request_t.unable_to_set_environment';
            end if;
        end;
        end if;

        <<validate_auths>>
        declare
            arr jsonpath[] = opt_.auth_paths;
        begin
            if arr is null or cardinality(arr) = 0 or auth.have(env.setting, arr) then
                exit validate_auths;
            end if;

            if opt_.is_debug then
                raise exception 'auth.request_t.missing_authorization %', arr;
            else
                raise exception 'auth.request_t.missing_authorization';
            end if;
        end;

        return req_;
    end;
    $$;


    comment on function auth.request_t(jsonb, auth.request_option_t)
        is 'if env is not set, validates session from _header & set env.'
        'checks authorization if provided.';

    create function auth.request_t(
        req jsonb,
        auths text[]
    )
        returns jsonb
        language sql
        security definer
    as $$
        select auth.request_t(
            req,
            auth.request_option_t(
                auth_paths => auth.auth_paths(auths)
            )
        )
    $$;

\endif