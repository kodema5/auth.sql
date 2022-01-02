

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