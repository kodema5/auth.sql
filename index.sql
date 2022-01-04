------------------------------------------------------------------------------
-- q: what is a simple user authentication/authorization module?

create extension if not exists "uuid-ossp" schema public;
create extension if not exists pgcrypto schema public;
create extension if not exists ltree schema public;

------------------------------------------------------------------------------
-- ddl section
\if :local
    drop schema if exists auth_ cascade;
\endif
create schema if not exists auth_;
\ir src/auth_/index.sql

------------------------------------------------------------------------------
-- user api  section

drop schema if exists auth cascade;
create schema auth;
\ir src/auth/index.sql

------------------------------------------------------------------------------
-- admin api section

drop schema if exists auth_admin cascade;
create schema auth_admin;
\ir src/auth_admin/index.sql
