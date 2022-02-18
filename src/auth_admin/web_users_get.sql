
create type auth_admin.web_users_get_it as (
    _auth auth.auth_t,
    namespace text,
    signon_ids text[],
    user_ids text[]
);

create type auth_admin.web_users_get_user_info_t as (
    user_id text,
    namespace text,
    signon_id text,
    role text
);

create type auth_admin.web_users_get_t as (
    users auth_admin.web_users_get_user_info_t[]
);

create function auth_admin.web_users_get(
    it auth_admin.web_users_get_it)
returns auth_admin.web_users_get_t
as $$
declare
    a auth_admin.web_users_get_t;
begin
    select array_agg(usr)
    into a.users
    from (
        select id, ns_id, signon_id, role
        from auth_.user u
        where (it.namespace is null or u.ns_id = it.namespace)
        and (it.signon_ids is null or u.signon_id = any(it.signon_ids))
        and (it.user_ids is null or u.id = any(it.user_ids))
    ) usr;

    return a;
end;
$$ language plpgsql;


create function auth_admin.web_users_get (req jsonb)
returns jsonb
as $$
    select to_jsonb(auth_admin.web_users_get(
        jsonb_populate_record(
            null::auth_admin.web_users_get_it,
            auth_admin.auth(req))
    ))
$$ language sql stable;


\if :test
    create function tests.test_auth_admin_web_users_get() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_admin();
        a jsonb;
    begin
        a = auth_admin.web_users_get( sid || jsonb_build_object('namespace', 'dev'));
        return next ok( jsonb_path_query(a, '$.users[*] ? ( @.signon_id == "foo.admin" ) ') is not null, 'has foo.admin');

        a = auth_admin.web_users_get( sid || jsonb_build_object('signon_ids', jsonb_build_array('foo.admin')));
        return next ok(jsonb_array_length(a->'users') = 1, 'has foo.admin');
    end;
    $$ language plpgsql;
\endif

