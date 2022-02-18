create type auth_admin.web_users_put_it as (
    _auth auth.auth_t,
    user_id text,
    namespace text,
    signon_id text,
    signon_key text,
    role text
);

create type auth_admin.web_users_put_t as (
    "user" auth_.user
);

create function auth_admin.web_users_put (
    it auth_admin.web_users_put_it)
returns auth_admin.web_users_put_t
as $$
declare
    a auth_admin.web_users_put_t;
    u auth_.user;
    pwd text;
begin
    -- create a new user?
    if it.user_id is null
    then

        if it.namespace is null
            or not exists (
                select from auth_.namespace
                where id=it.namespace)
        then
            raise exception 'error.invalid_namespace';
        end if;

        if it.signon_id is null
        then
            raise exception 'error.invalid_signon_id';
        end if;

        insert into auth_.user (ns_id, signon_id, signon_key, role)
        values (
            it.namespace,
            it.signon_id,
            auth.crypt_signon_key(it.signon_key),
            it.role
        )
        returning *
        into u;

    -- updates existing user?
    else

        if not exists (
            select from auth_.user
            where id=it.user_id)
        then
            raise exception 'error.invalid_user_id';
        end if;

        pwd = auth.crypt_signon_key(it.signon_key);

        if it.signon_key is not null
            and pwd is null
        then
            raise exception 'error.invalid_signon_key';
        end if;

        update auth_.user set
            ns_id = coalesce(it.namespace, ns_id),
            signon_key = coalesce(
                auth.crypt_signon_key(it.signon_key),
                signon_key),
            role = coalesce(it.role, role)
        where id = it.user_id
        returning *
        into u;
    end if;

    a.user = u;
    return a;
end;
$$ language plpgsql;


create function auth_admin.web_users_put (req jsonb)
returns jsonb
as $$
    select to_jsonb(auth_admin.web_users_put(
        jsonb_populate_record(
            null::auth_admin.web_users_put_it,
            auth_admin.auth(req))
    ))
$$ language sql stable;


\if :test
    create function tests.test_auth_admin_web_users_put() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_admin();
        a jsonb;
        uid text;
    begin
        a = sid;
        return next throws_ok(format('select auth_admin.web_users_put(%L::jsonb)', a), 'error.invalid_namespace');

        a = auth_admin.web_users_put(sid || jsonb_build_object(
            'namespace', 'dev',
            'signon_id', 'foo.test',
            'signon_key', 'foo.password',
            'role', 'user'
        ));
        return next ok(a->'user' is not null, 'can create user');
        uid = a->'user'->>'id';

        a = auth_admin.web_users_put(sid || jsonb_build_object(
            'user_id', uid,
            'signon_key', 'foo.password2', -- this changes password
            'role', 'admin' -- this changes role
        ));
        return next ok(a->'user'->>'role' = 'admin', 'can update user');


        a = sid || jsonb_build_object(
            'user_id', 'xxxx'
        );
        return next throws_ok(format('select auth_admin.web_users_put(%L::jsonb)', a), 'error.invalid_user_id');

        a = sid || jsonb_build_object(
            'user_id', uid,
            'signon_key', 'foo'
        );
        return next throws_ok(format('select auth_admin.web_users_put(%L::jsonb)', a), 'error.invalid_signon_key');
    end;
    $$ language plpgsql;
\endif