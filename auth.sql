-- web-dev watch auth.sql
create extension if not exists "uuid-ossp" schema public;
create extension if not exists pgcrypto schema public;
create extension if not exists ltree schema public;

\ir ./src/_auth/index.sql
\ir ./src/auth/index.sql