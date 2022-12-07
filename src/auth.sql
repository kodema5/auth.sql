\if :{?auth_sql}
\else
\set auth_sql true

create extension if not exists pgcrypto;

\ir util/add_constraint.sql
\ir util/is.sql
\ir util/export.jsonb_fn_t.sql
\ir util/export.web_fn_t.sqL
\ir confirm.sql

\if :test
\if :local
drop schema if exists _auth cascade;
\endif
\endif
create schema if not exists _auth;

drop schema if exists auth cascade;
create schema auth;

-- holds signon user-name/pwd
--
create table if not exists _auth.user (
    id text
        default md5(gen_random_uuid()::text)
        primary key,
    email text not null,
    role text
        default 'user',
    created_tz timestamp with time zone
        default current_timestamp,
    confirmed_tz timestamp with time zone
);

call util.add_constraints(array[
    ('_auth.user', 'signon.user.invalid_email', 'check(util.is_email(email))'),
    ('_auth.user', 'signon.user.unique_email', 'unique(email)'),
    ('_auth.user', 'signon.user.invalid_roe', 'check(role in(''user'',''admin'',''sys''))')
]::util.add_constraint_it[]);

create table if not exists _auth.password(
    user_id text
        unique
        references _auth.user(id)
        on delete cascade,

    password text not null
);

\ir auth/user.sql



-- token for user-access
--
create table if not exists _auth.session (
    id text default
        md5(gen_random_uuid()::text)
        primary key,
    user_id text
        not null
        references _auth.user(id)
        on delete cascade,
    created_tz timestamp with time zone
        default current_timestamp
);

\ir auth/session.sql


-- user scoped storage
create table if not exists _auth.user_storage (
    user_id text
        references _auth.user(id)
        on delete cascade,
    key text
        not null,
    value jsonb,
    primary key (user_id, key)
);

-- session scoped storage
create table if not exists _auth.session_storage (
    session_id text
        references _auth.session(id)
        on delete cascade,
    key text
        not null,
    value jsonb,
    primary key (session_id, key)
);


create table if not exists _auth.config (
    id text
        primary key
        not null,
    name text,
    value jsonb
);


create table if not exists _auth.config_template (
    id text
        references _auth.config(id)
        on delete cascade,
    name text not null,
    value jsonb,
    unique (id, name)
);


-- these are user override
create table if not exists _auth.config_user (
    id text
        references _auth.config(id)
        on delete cascade,
    name text
        not null
        references _auth.user(id)
        on delete cascade,
    value jsonb,
    unique (id, name)
);

\ir auth/auth.sql

set app.default_auth_function = 'auth.auth';
\ir auth/web_config.sql
\ir auth/web_register.sql
\ir auth/web_signon.sql
\ir auth/web_signoff.sql
\ir auth/web_storage.sql

\endif