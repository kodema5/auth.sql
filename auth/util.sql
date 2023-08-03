\if :{?auth_util_sql}
\else
\set auth_util_sql true
-- various utility

\ir util/array.sql
\ir util/debug.sql
\ir util/jsonb.sql
\ir util/jsonpath.sql

\endif
