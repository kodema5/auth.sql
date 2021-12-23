
create type auth_admin.web_users_it as (
    _auth jsonb
);

create type auth_admin.user_t as (
    id text,
    ns_id text,
    signon_id text,
    role text
);

create type auth_admin.web_users_ot as (
    users auth_admin.user_t[]
);


create function auth_admin.web_users(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_users_it = jsonb_populate_record(null::auth_admin.web_users_it, auth_admin.auth(req));
    ot auth_admin.web_users_ot;
begin
    select array_agg((
        u.id,
        u.ns_id,
        u.signon_id,
        u.role
    )::auth_admin.user_t)
    into ot.users
    from auth_.user u;

    return to_jsonb(ot);
end;
$$ language plpgsql;

create function auth_admin.web_users_get(req jsonb) returns jsonb as $$
    select auth_admin.web_users(req);
$$ language sql;
