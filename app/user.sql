---------------------------------------------------------------------------

do $$ begin
    create type auth.user_role_t as enum ('admin', 'user');
exception when duplicate_object then null; end; $$;

alter table auth.USER
    add column name text not null check (name ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
    add column pwd text not null default md5(uuid_generate_v4()::text),
    add column role auth.user_role_t default 'user',
    add column last_signon_tz timestamp with time zone,
    add unique (namespace, name);


---------------------------------------------------------------------------
-- gets user-id

create function auth.user_id (
    ns_ text,
    name_ text
) returns text
as $$
    select id from auth.user where namespace=ns_ and name=name_;
$$ language sql stable;

