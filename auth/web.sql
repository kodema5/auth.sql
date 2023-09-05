\if :{?auth_web_sql}
\else
\set auth_web_sql true

\ir web/headers_t.sql
\ir web/request_t.sql
\ir web/response_t.sql


\ir web/env.sql

\ir web/app.sql
\ir web/auth.sql
\ir web/brand.sql
\ir web/param.sql
\ir web/service.sql
\ir web/session.sql
\ir web/setting.sql
\ir web/signoff.sql
\ir web/signon.sql
\ir web/user_type.sql
\ir web/user.sql
\ir web/api.sql

\endif