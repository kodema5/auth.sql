---------------------------------------------------------------------------

do $$ begin
    create domain auth.user_name_t as text
    constraint "error.should_be_email_address" check (value ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
    default md5(uuid_generate_v4()::text);
exception when duplicate_object then null; end; $$;

do $$ begin
    create domain auth.user_password_t as text
    not null
    default md5(uuid_generate_v4()::text);
exception when duplicate_object then null; end; $$;

do $$ begin
    create type auth.user_role_t as enum ('admin', 'user');
exception when duplicate_object then null; end; $$;

alter table auth.USER
    add column name auth.user_name_t not null,
    add column pwd auth.user_password_t not null,
    add column role auth.user_role_t default 'user',
    add column last_signon_tz timestamp with time zone,
    add unique (namespace, name);


---------------------------------------------------------------------------
-- gets user-id

create function auth.user_id (
    ns_ auth.namespace_id_t,
    name_ auth.user_name_t
) returns auth.user_t
as $$
    select id from auth.user where namespace=ns_ and name=name_;
$$ language sql stable;

