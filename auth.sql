\if :test
\if :local
drop schema if exists web cascade;
\endif
\endif
create schema if not exists web;

\if :test
\if :local
drop schema if exists util cascade;
\endif
\endif
create schema if not exists util;


\ir src/user/mod.sql
\ir src/session/mod.sql
\ir src/setting/mod.sql

-- web interface
\ir src/web/user/mod.sql
\ir src/web/session/mod.sql
