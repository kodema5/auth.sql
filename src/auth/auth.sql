create function auth.who (
    session_id text,
    origin_ text default null
)
    returns _auth.signon
    language sql
    security definer
as $$
    select u.*
    from _auth.session s
    join _auth.signon u
        on u.id = s.signon_id
    where s.id = session_id
        and u.is_active = true
        and s.authenticated = true
        and s.signed_off_tz is null
        and s.expired_tz is null
        and (
            origin_ is null
            or s.origin = origin_
        );
$$;

-- auth.auth is a function that is to be called frequently
-- it adds _auth into req jsonb
--
create function auth.auth (
    req jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select req || jsonb_build_object(
        '_auth', auth.who(
            coalesce(jwt.decode(
                req->'_headers'->>'authorization')->>'sid',
                'nobody'),
            coalesce(
                req->>'_origin',
                'nowhere')
        ))
$$;
