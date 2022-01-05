-- checks session_id variable and adds authentication information

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


create function auth.auth(
    req jsonb,
    is_required boolean default true
) returns jsonb as $$
declare
    session_id text = req->>'session_id';
    a auth.auth_t;
begin
    if req is null then
        if is_required then
            raise exception 'error.invalid_session';
        end if;
        return req;
    end if;

    update auth_.session s1 set accessed_tz = now()
    from (
        select id, accessed_tz from auth_.session
        where id=session_id for update
    ) s0
    where s1.id = s0.id
    returning s0.accessed_tz as last_accessed_tz, s1.user_id
    into a.last_accessed_tz, a.user_id;

    if not found then
        if is_required then
            raise exception 'error.invalid_session';
        end if;
        return req;
    end if;

    select u.role, u.signon_id, u.ns_id
    into a.role, a.signon_id, a.namespace
        from auth_.user u
        where u.id = a.user_id;

    if not found then return req; end if;

    a.session_id = session_id;
    a.is_admin = a.role='admin' or a.role='system';
    a.is_system = a.role='system';

    return req
        || jsonb_build_object('_auth', a);
end;
$$ language plpgsql;
