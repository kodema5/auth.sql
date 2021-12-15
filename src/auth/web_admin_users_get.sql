
-- lists users

create type auth.web_admin_users_get_it as (
    _auth jsonb
);

create type auth.user_t as (
    ns_id text,
    signon_id text,
    role text
);

create type auth.web_admin_users_get_ot as (
    users auth.user_t[]
);


create function auth.web_admin_users_get(req jsonb) returns jsonb as $$
declare
    it auth.web_admin_users_get_it = jsonb_populate_record(null::auth.web_admin_users_get_it, auth.auth_admin(req));
    ot auth.web_admin_users_get_ot;
begin
    if not it._auth->'is_admin' then
        raise exception 'error.insufficient_previledge';
    end if;

    select array_agg((
        u.ns_id,
        u.signon_id,
        u.role
    )::auth.user_t)
    into ot.users
    from auth_.user u;

    return to_jsonb(ot);
end;
$$ language plpgsql;

select * from auth_.user u;