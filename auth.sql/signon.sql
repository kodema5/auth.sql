
create table auth.signon (
    id text primary key default md5(uuid_generate_v4()::text),
    ns text not null,
    name text not null,
    pwd text not null,
    created_ts bigint default auth.current_ts(),
    unique (ns, name)
);

------------------------------------------------------------------------------
-- validation

create or replace function auth.is_a_signon_name (name text) returns boolean as $$
    select name ~ '^[A-Za-z0-9_]+([-.][a-zA-Z0-9_]+)*$';
$$ language sql;

create or replace function auth.is_a_signon_password (pwd text) returns boolean as $$
    select length(pwd)>5
$$ language sql;


create function auth.has_signon(ns_ text, name_ text) returns boolean as $$
    select exists(select 1 from auth.signon where ns=ns_ and name=name_)
$$ language sql stable security definer;

------------------------------------------------------------------------------
-- crates a new user

create or replace function auth.new_signon (
    name_ text,
    pwd_ text,
    is_init boolean default false,
    ns_ text default coalesce(current_setting('auth.namespace', true), 'test')
) returns text as $$
declare
    u auth.signon;
begin
    if auth.has_signon(ns_, name_) and not is_init then
        raise exception 'error.user_exists';
    end if;

    if not auth.is_a_signon_name(name_) then
        raise exception 'error.invalid_signon_name';
    end if;

    if not auth.is_a_signon_password(pwd_) then
        raise exception 'error.invalid_signon_password';
    end if;

    with insert_user as (
        insert into auth.signon (ns, name, pwd)
        values (
            ns_,
            name_,
            crypt(pwd_, gen_salt('bf', 8))
        )
        on conflict do nothing
        returning *
    )
    select (s.*) into u from insert_user s;

    return u.id;
end;
$$ language plpgsql security definer;

------------------------------------------------------------------------------
-- unregister

create or replace function auth.end_signon (
    id_ text
) returns boolean as $$
    with deleted as (
        delete from auth.signon
        where id = id_
        returning *
    )
    select exists(select 1 from deleted s)
$$ language sql security definer;

------------------------------------------------------------------------------
-- authenticate user signon

create or replace function auth.authenticate_signon (
    name_ text,
    pwd_ text,
    ns_ text default coalesce(current_setting('auth.namespace', true), 'test')
) returns text as $$
declare
    usr text;
begin

    select id
    into usr
    from auth.signon
    where ns = ns_
        and name = name_
        and pwd = crypt(pwd_, pwd);

    if usr is null then
        raise exception 'error.unrecognized_signon';
    end if;

    return usr;
end;
$$ language plpgsql security definer;

------------------------------------------------------------------------------
-- change password

create or replace function auth.set_signon_password (
    id_ text,
    new_ text
) returns text as $$
declare
    u auth.signon;
begin
    if not auth.is_a_signon_password(new_) then
        raise exception 'error.invalid_signon_password';
    end if;

    with updated as (
        update auth.signon
        set pwd = crypt(new_, gen_salt('bf', 8))
        where id = id_
        returning *
    )
    select (s.*) into u from updated s;

    return u.name;
end;
$$ language plpgsql security definer;

------------------------------------------------------------------------------

\if :test
    create or replace function tests.test_auth_signon () returns setof text as $$
    declare
        u text;
    begin
        perform set_config('auth.namespace', 'test', true);

        u = auth.new_signon('test', 'test-pwd');
        return next ok(u is not null, 'register');

        u = auth.authenticate_signon('test', 'test-pwd');

        return next ok(u is not null, 'can signon user-name/pwd');
        return next throws_ok('select auth.authenticate_signon(''test'', ''test-xxx'')', 'error.unrecognized_signon');

        return next ok(auth.set_signon_password(u, 'test-pwd2') is not null, 'change password');

        return next ok(auth.end_signon(u), 'unregister');
    end;
    $$ language plpgsql;
\endif

------------------------------------------------------------------------------
-- possible future improvements:
-- use auto-generated id
-- confirm registration, unregistration
-- no reuse of signon.id
-- tract attempts
