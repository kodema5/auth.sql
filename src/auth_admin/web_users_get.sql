
create type auth_admin.web_users_it as (
    _auth auth.auth_t,
    ns_id text,
    signon_ids text[],
    user_ids text[]
);


create function auth_admin.web_users(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_users_it = jsonb_populate_record(null::auth_admin.web_users_it, auth_admin.auth(req));
    res jsonb;
begin
    select jsonb_agg(to_jsonb(usr))
    into res
    from (
        select id, ns_id, signon_id, role
        from auth_.user u
        where (it.ns_id is null or u.ns_id = it.ns_id)
        and (it.signon_ids is null or u.signon_id = any(it.signon_ids))
        and (it.user_ids is null or u.id = any(it.user_ids))
    ) usr;

    return jsonb_build_object('users', res);
end;
$$ language plpgsql;

create function auth_admin.web_users_get(req jsonb) returns jsonb as $$
    select auth_admin.web_users(req);
$$ language sql;
