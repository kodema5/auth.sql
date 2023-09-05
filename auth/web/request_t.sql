\if :{?auth_web_request_t_sql}
\else
\set auth_web_request_t_sql true

-- validates session in req_
-- checks permissions in opt_
-- returns req

    create function auth.web_request_t(
        req jsonb,
        req_ jsonb default null,
        auth_ids text[] default null,
        is_debug boolean
            default coalesce(
                nullif(current_setting('auth.web_request_t.is_debug', true), ''),
            'f')::boolean
    )
        returns jsonb
        language plpgsql
        security definer
    as $$
    declare
        env auth.env_t = auth.env_t();
    begin

        <<check_headers>>
        declare
            h auth.web_headers_t = auth.web_headers_t(req_);
            s auth_.session;
        begin
            if h is null then
                exit check_headers;
            end if;

            s = auth.session(h.authorization);
            if s is null then
                if is_debug then
                    raise exception 'auth.request_t.unrecognized_session %', jsonb_pretty(to_jsonb(h));
                else
                    raise exception 'auth.request_t.unrecognized_session';
                end if;
            end if;

            env = auth.env_t(s);
        end;

        <<check_auth_ids>>
        declare
            arr jsonpath[] = auth.auth_paths(auth_ids);
        begin
            if arr is null or cardinality(arr) = 0 or auth.have(env.setting, arr) then
                exit check_auth_ids;
            end if;

            if is_debug then
                raise exception 'auth.request_t.missing_authorization %', arr;
            else
                raise exception 'auth.request_t.missing_authorization';
            end if;
        end;

        return req;
    end;
    $$;

\endif

