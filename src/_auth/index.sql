\if :test
\if :local
    drop schema if exists _auth cascade;
\endif
\endif
create schema if not exists _auth;

\ir env.sql
\ir signon.sql
\ir signon_password.sql
\ir session.sql
\ir setting.sql
\ir confirmation.sql

