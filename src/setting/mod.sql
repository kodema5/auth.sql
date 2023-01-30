\if :{?setting_sql}
\else
\set setting_sql true

\ir ../util/config.sql

\if :test
\if :local
drop schema if exists setting_ cascade;
\endif
\endif
create schema if not exists setting_;


create table if not exists setting_.setting (
    id text
        not null
        primary key,
    description text,
    value jsonb
);

create table if not exists setting_.template (
    setting_id text
        references setting_.setting(id)
        on delete cascade,
    template_id text
        not null,
    value jsonb,
    primary key (setting_id, template_id)
);

create table setting_.user  (
    setting_id text
        references setting_.setting(id)
        on delete cascade,
    user_id text
        references user_.user(id)
        on delete cascade,
    value jsonb,
    primary key (setting_id, user_id)
);


drop schema if exists setting cascade;
create schema setting;

\ir get.sql
\ir setting.sql
\ir template.sql
\ir user.sql

\endif