-- checks session_id variable and adds authentication information

create type auth.auth_it as (
    session_id text
);

create type auth.auth_t as (
    session_id text,
    namespace text,
    user_id text,
    signon_id text,
    role text,
    is_admin boolean,
    is_system boolean,
    last_accessed_tz timestamp with time zone
);

create function auth.auth (
    req auth.auth_it,
    required boolean default true
)
returns auth.auth_t as $$
declare
    sid text = req.session_id;
    a auth.auth_t;
begin
    if req is null or sid is null then
        if required then
            raise exception 'error.invalid_session';
        end if;
        return null;
    end if;

    update auth_.session s1
    set accessed_tz = now()
    from (
        select id, accessed_tz
        from auth_.session
        where id = sid
        for update
    ) s0
    where s1.id = s0.id
    returning s0.accessed_tz
        as last_accessed_tz, s1.user_id
        into a.last_accessed_tz, a.user_id;

    if not found then
        if required then
            raise exception 'error.invalid_session';
        end if;
        return null;
    end if;

    select u.role, u.signon_id, u.ns_id
    into a.role, a.signon_id, a.namespace
    from auth_.user u
    where u.id = a.user_id;

    if not found then
        return null;
    end if;

    a.session_id = sid;
    a.is_admin = a.role='admin' or a.role='system';
    a.is_system = a.role='system';
    return a;
end;
$$ language plpgsql;


create function auth.auth (
    req jsonb,
    required boolean default true
)
returns jsonb as $$
    select req
        || jsonb_build_object(
            '_auth',
            auth.auth(
                jsonb_populate_record(null::auth.auth_it, req),
                required))
$$ language sql stable;
