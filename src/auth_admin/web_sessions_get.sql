create type auth_admin.web_sessions_get_it as (
    _auth auth.auth_t
);

create function auth_admin.web_sessions_get(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_sessions_get_it = jsonb_populate_record(null::auth_admin.web_sessions_get_it, auth_admin.auth(req));
    res jsonb;
begin
    return jsonb_build_object(
        'sessions',
        (select jsonb_agg(to_jsonb(a))
        from (
            select s.*, u.ns_id, u.signon_id
            from auth_.session s
            left outer join auth_.user u on u.id = s.user_id
        ) a)
    );
end;
$$ language plpgsql;
