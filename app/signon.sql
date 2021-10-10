---------------------------------------------------------------------------

do $$ begin
    create domain auth.signon_name_t as text
    constraint "error.should_be_email_address" check (value ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
    default md5(uuid_generate_v4()::text);
exception when duplicate_object then null; end; $$;

do $$ begin
    create domain auth.signon_password_t as text
    not null
    default md5(uuid_generate_v4()::text);
exception when duplicate_object then null; end; $$;

do $$ begin
    create type auth.signon_role_t as enum ('admin', 'user');
exception when duplicate_object then null; end; $$;

alter table auth.SIGNON
    add column name auth.signon_name_t not null,
    add column pwd auth.signon_password_t not null,
    add column role auth.signon_role_t default 'user',
    add column last_signon_tz timestamp with time zone,
    add unique (namespace, name);


---------------------------------------------------------------------------
-- gets signon-id

create function auth.signon_id (
    ns_ namespace_t,
    name_ auth.signon_name_t
) returns auth.signon_t
as $$
    select id from auth.signon where namespace=ns_ and name=name_;
$$ language sql stable;

