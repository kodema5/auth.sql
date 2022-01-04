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



create type auth_admin.web_sessions_delete_it as (
    _auth jsonb,
    session_ids text[],
    user_ids text[]
);

create function auth_admin.web_sessions_delete(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_sessions_delete_it = jsonb_populate_record(null::auth_admin.web_sessions_delete_it, auth_admin.auth(req));
    n int = 0;
begin
    if it.session_ids is not null then
        with deleted as (
            delete from auth_.session
            where id = any(it.session_ids)
            returning *
        )
        select (n + count(1)) into n from deleted;
    end if;

    if it.user_ids is not null then
        with deleted as (
            delete from auth_.session
            where user_id = any(it.user_ids)
            returning *
        )
        select (n + count(1)) into n from deleted;
    end if;

    return jsonb_build_object('deleted', n);
end;
$$ language plpgsql;



\if :test
    create function tests.test_auth_admin_sessions() returns setof text as $$
    declare
        sid1 jsonb = tests.session_as_foo_admin();
        sid2 jsonb = tests.session_as_foo_user();

        res jsonb;
    begin
        res = auth_admin.web_sessions_get(sid1);
        return next ok(jsonb_array_length(res->'sessions') = 2, 'able to get sessions');

        res = auth_admin.web_sessions_delete(sid1 || jsonb_build_object(
            'session_ids', array[sid2->'session_id']
        ));
        return next ok((res->'deleted')::numeric = 1, 'delete session with session-id');

        res = auth_admin.web_sessions_delete(sid1 || jsonb_build_object(
            'user_ids', array[(select id from auth_.user where signon_id='foo.admin')]
        ));
        return next ok((res->'deleted')::numeric = 1, 'delete session with signon-id');

    end;
    $$ language plpgsql;
\endif