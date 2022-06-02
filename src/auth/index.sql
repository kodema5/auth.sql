create extension if not exists ltree schema public;

drop schema if exists auth cascade;
create schema if not exists auth;

\ir auth.sql
\ir settings.sql
\ir signon/index.sql
\ir signoff/index.sql
\ir register/index.sql
