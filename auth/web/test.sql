\if :{?auth_web_test_sql}
\else
\set auth_web_test_sql true

\ir test/signon.sql

\endif
