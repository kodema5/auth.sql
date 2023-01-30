\if :{?web_user_sql}
\else
\set web_user_sql true

-- drop schema if exists web_user cascade;
-- create schema web_user;

\ir signon.sql
\ir signoff.sql
\ir register.sql
\ir change_password.sql
\ir data.sql

\ir setting.sql

\endif