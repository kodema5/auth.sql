create type auth_admin.web_sessions_get_it as (
    _auth auth.auth_t,
    namespace text
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
            left join auth_.user u on u.id = s.user_id
                and (it.namespace is null or u.ns_id=it.namespace)
        ) a)
    );
end;
$$ language plpgsql;


\if :test
    create function tests.test_auth_admin_web_sessions_get() returns setof text as $$
    declare
        sid1 jsonb = tests.session_as_foo_admin();
        sid2 jsonb = tests.session_as_foo_user();
        a jsonb;
    begin
        a = auth_admin.web_sessions_get(sid1);
        return next ok(jsonb_array_length(a->'sessions') = 2, 'able to get sessions');


        a = auth_admin.web_sessions_get(sid1 || jsonb_build_object('namespace', 'test2'));
        return next ok(jsonb_array_length(a->'sessions') = 2, 'able to get sessions for namespace');

    end;
    $$ language plpgsql;
\endif

