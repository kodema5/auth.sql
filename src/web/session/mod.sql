\if :{?web_session_sql}
\else
\set web_session_sql true

\ir data.sql

\endif