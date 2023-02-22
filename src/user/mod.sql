\if :{?user_sql}
\else
\set user_sql true

create extension if not exists pgcrypto;

\ir ../util/add_constraint.sql
\ir ../util/is.sql
\ir ../util/config.sql

\if :test
\if :local
drop schema if exists user_ cascade;
\endif
\endif
create schema if not exists user_;

create table if not exists user_.user (
    id text
        default md5(gen_random_uuid()::text)
        primary key,

    email text not null,

    role text
        default 'user',

    created_tz
        timestamp with time zone
        default current_timestamp,

    templates text[]
);


call util.add_constraints(array[
    ('user_.user', 'user.user.invalid_email', 'check(util.is_email(email))'),
    ('user_.user', 'user.user.unique_email', 'unique(email)'),
    ('user_.user', 'user.user.invalid_roe', 'check(role in(''user'',''admin'',''sys''))')
]::util.add_constraint_it[]);

create table if not exists user_.password(
    user_id text
        unique
        references user_.user(id)
        on delete cascade,

    password text not null
);


create table if not exists user_.data (
    user_id text
        references user_.user(id)
        on delete cascade,
    key text
        not null,
    value jsonb,
    primary key (user_id, key)
);


drop schema if exists "user" cascade;
create schema "user";

\ir set_password.sql
\ir new.sql
\ir get.sql
\ir data.sql
\ir sign.sql


\endif
