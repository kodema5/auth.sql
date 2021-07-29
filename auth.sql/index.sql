create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";
create extension if not exists "ltree";

drop schema if exists auth cascade;
create schema auth;

create function auth.current_ts ()
returns bigint as $$
    select trunc(extract(epoch from clock_timestamp()))::bigint
$$ language sql security definer;





\ir namespace.sql
\ir config.sql
\ir signon.sql
\ir session.sql


