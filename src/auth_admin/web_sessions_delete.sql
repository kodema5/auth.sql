create type auth_admin.web_sessions_delete_it as (
    _auth jsonb,
    session_ids text[],
    user_ids text[]
);

create type auth_admin.web_sessions_delete_t as (
    deleted int
);

create function auth_admin.web_sessions_delete(
    it auth_admin.web_sessions_delete_it)
returns auth_admin.web_sessions_delete_t
as $$
declare
    a auth_admin.web_sessions_delete_t;
    n int = 0;
begin
    if it.session_ids is not null then
        with deleted as (
            delete from auth_.session
            where id = any(it.session_ids)
            returning *
        )
        select (n + count(1))
        into n
        from deleted;
    end if;

    if it.user_ids is not null then
        with deleted as (
            delete from auth_.session
            where user_id = any(it.user_ids)
            returning *
        )
        select (n + count(1))
        into n
        from deleted;
    end if;

    a.deleted = n;
    return a;
end;
$$ language plpgsql;


create function auth_admin.web_sessions_delete(req jsonb)
returns jsonb
as $$
    select to_jsonb(auth_admin.web_sessions_delete(
        jsonb_populate_record(
            null::auth_admin.web_sessions_delete_it,
            auth_admin.auth(req))
    ))
$$ language sql stable;


\if :test
    create function tests.test_auth_admin_web_sessions_delete() returns setof text as $$
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