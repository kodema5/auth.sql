\if :{?auth_sql}
\else
\set auth_sql true

drop schema if exists auth cascade;
create schema if not exists auth;
comment on schema auth is 'auth is for authentiction and authorization';

create extension if not exists pgcrypto;

\ir auth/test.sql
\ir auth/util.sql

\ir auth/env_t.sql
\ir auth/setting_t.sql

\ir auth/app.sql
\ir auth/param.sql
\ir auth/setting.sql
\ir auth/auth.sql
\ir auth/service.sql


\ir auth/brand.sql
\ir auth/user_type.sql
\ir auth/user.sql
\ir auth/session.sql

\ir auth/web.sql

\endif
