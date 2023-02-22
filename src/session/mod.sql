\if :{?session_sql}
\else
\set session_sql true

\ir ../util/config.sql

\if :test
\if :local
drop schema if exists session_ cascade;
\endif
\endif
create schema if not exists session_;

create table if not exists session_.session (
    id text default
        md5(gen_random_uuid()::text)
        primary key,
    user_id text
        not null
        references user_.user(id)
        on delete cascade,

    is_signed boolean
        default false,

    -- when first created
    created_tz
        timestamp with time zone
        default current_timestamp,

    -- last auth got called
    last_auth_tz
        timestamp with time zone
);


create table if not exists session_.data (
    session_id text
        references session_.session(id)
        on delete cascade,

    key text
        not null,
    value jsonb,

    primary key (session_id, key)
);


drop schema if exists session cascade;
create schema session;

\ir auth.sql
\ir new.sql
\ir end.sql
\ir data.sql
\ir get.sql
\ir sign.sql

\endif