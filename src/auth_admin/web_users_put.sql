create type auth_admin.web_users_put_it as (
    _auth auth.auth_t,
    user_id text,
    namespace text,
    signon_id text,
    signon_key text,
    role text
);

-- insert or update
create function auth_admin.web_users_put(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_users_put_it = jsonb_populate_record(null::auth_admin.web_users_put_it, auth_admin.auth(req));
    u auth_.user;
begin
    if it.user_id is null then
        insert into auth_.user (ns_id, signon_id, signon_key, role)
        values (
            it.namespace,
            it.signon_id,
            crypt(it.signon_key, gen_salt('bf', 8)),
            it.role
        )
        returning * into u;
    else
        update auth_.user set
            ns_id = coalesce(it.namespace, ns_id),
            signon_key = coalesce(crypt(it.signon_key, gen_salt('bf', 8)), signon_key),
            role = coalesce(it.role, role)
        where id = it.user_id
        returning * into u;
    end if;

    return jsonb_build_object('user', u);
end;
$$ language plpgsql;




-- create type auth_admin.web_users_delete_it as (
--     _auth auth.auth_t,
--     user_ids text[]
-- );

-- create function auth_admin.web_users_delete(req jsonb) returns jsonb as $$
-- declare
--     it auth_admin.web_users_delete_it = jsonb_populate_record(null::auth_admin.web_users_delete_it, auth_admin.auth(req));
--     n int;
-- begin
--     with deleted as (
--         delete from auth_.user
--         where id = any(it.user_ids)
--         returning *
--     )
--     select count(1) into n from deleted;

--     return jsonb_build_object('deleted', n);
-- end;
-- $$ language plpgsql;



\if :test
    create function tests.test_auth_admin_web_users_put() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_admin();
        a jsonb;
    begin
        a = auth_admin.web_users_put(sid || jsonb_build_object(
            'namespace', 'dev',
            'signon_id', 'foo.test',
            'signon_key', 'foo.password',
            'role', 'user'
        ));
        return next ok(a->'user' is not null, 'can create user');

        a = auth_admin.web_users_put(sid || jsonb_build_object(
            'user_id', a->'user'->>'id',
            'signon_key', 'foo.password2', -- this changes password
            'role', 'admin' -- this changes role
        ));
        return next ok(a->'user'->>'role' = 'admin', 'can update user');

        a = auth_admin.web_users_delete( sid
            || jsonb_build_object('user_ids', jsonb_build_array(a->'user'->>'id')));
        return next ok((a->>'deleted')::int = 1, 'able to delete');

        a = auth_admin.web_users_get( sid
            || jsonb_build_object('signon_ids', jsonb_build_array('foo.test')));
        return next ok(jsonb_typeof(a->'users')='null', 'foo.test deleted');
    end;
    $$ language plpgsql;
\endif