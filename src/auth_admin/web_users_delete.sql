create type auth_admin.web_users_delete_it as (
    _auth auth.auth_t,
    user_ids text[]
);

create type auth_admin.web_users_delete_t as (
    deleted int
);

create function auth_admin.web_users_delete(
    it auth_admin.web_users_delete_it)
returns auth_admin.web_users_delete_t
as $$
declare
    a auth_admin.web_users_delete_t;
begin
    with deleted as (
        delete from auth_.user
        where id = any(it.user_ids)
        returning *
    )
    select count(1)
    into a.deleted
    from deleted;

    return a;
end;
$$ language plpgsql;


create function auth_admin.web_users_delete (req jsonb)
returns jsonb
as $$
    select to_jsonb(auth_admin.web_users_delete(
        jsonb_populate_record(
            null::auth_admin.web_users_delete_it,
            auth_admin.auth(req))
    ))
$$ language sql stable;


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