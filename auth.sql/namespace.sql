-- namespace can be used for app/tenant/brand

create table auth.namespace (
    name text primary key,
    created_ts bigint default auth.current_ts()
);


------------------------------------------------------------------------------
--
create function auth.new_ns(name_ text)
returns text as $$
    with insertion as (
        insert into auth.namespace (name)
        values (name_)
        on conflict (name)
        do update set name=name_
        returning *
    )
    select s.name from insertion s
$$ language sql strict security definer;

------------------------------------------------------------------------------
--
create function auth.end_ns(name_ text) returns boolean as $$
    with deletion as (
        delete from auth.namespace
        where name = name_
        returning *
    )
    select exists(select 1 from deletion)
$$ language sql security definer;

------------------------------------------------------------------------------
-- picks namespace from setting, but also validates it with data in table
--
create function auth.get_ns(
    name_ text default coalesce(current_setting('auth.namespace', true), 'test')
) returns text as $$
    select name
    from auth.namespace
    where name = name_
$$ language sql strict security definer;


------------------------------------------------------------------------------
--

\if :test
create function tests.test_auth_namespace() returns setof text as $$
declare
    ns text;
begin
    return next ok(auth.new_ns(null) is null, 'name cant be null');
    return next ok(auth.end_ns(null) = false, 'name cant be null');


    ns = auth.new_ns('test');
    return next ok(ns is not null, 'can create namespace');

    ns = auth.get_ns('test2');
    return next ok(ns is null, 'null for invalid namespace');

    ns = auth.get_ns('test');
    return next ok(ns is not null, 'can get namespace-id');

    set auth.namespace = 'test';
    return next ok(auth.get_ns() = ns, 'can use session variable');


    perform auth.end_ns(ns);
    ns = auth.get_ns('test');
    return next ok(ns is null, 'null for removed namespace');
end;
$$ language plpgsql;

\endif