create type auth_admin.web_users_delete_it as (
    _auth auth.auth_t,
    user_ids text[]
);

create function auth_admin.web_users_delete(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_users_delete_it = jsonb_populate_record(null::auth_admin.web_users_delete_it, auth_admin.auth(req));
    n int;
begin
    with deleted as (
        delete from auth_.user
        where id = any(it.user_ids)
        returning *
    )
    select count(1) into n from deleted;

    return jsonb_build_object('deleted', n);
end;
$$ language plpgsql;


\if :test
    create function tests.test_auth_admin_web_users_delete() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_admin();
        a jsonb;
    begin
        a = auth_admin.web_users_delete( sid
            || jsonb_build_object(
                'user_ids', jsonb_build_array( auth.get_user_id('dev', 'foo.user'))
            ));
        return next ok((a->>'deleted')::int = 1, 'able to delete');

        a = auth_admin.web_users_get( sid
            || jsonb_build_object(
                'namespace', 'dev',
                'signon_ids', jsonb_build_array('foo.user')));
        return next ok(jsonb_typeof(a->'users')='null', 'foo.user deleted');
    end;
    $$ language plpgsql;
\endif