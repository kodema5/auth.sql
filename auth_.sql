\if :{?auth__sql}
\else
\set auth__sql true

drop schema if exists auth_ cascade;
create schema if not exists auth_;
comment on schema auth is 'auth_ contains a protected data section';

-- the autorization model is app -> param -> setting
-- the authentiation model is brand -> user_type -> user -> session
-- assumptions: settings are set by admin/system, not modifiable by user

\ir auth_/app.sql
\ir auth_/param.sql
\ir auth_/setting.sql
\ir auth_/service.sql
\ir auth_/auth.sql

\ir auth_/brand.sql
\ir auth_/user_type.sql
\ir auth_/user.sql
\ir auth_/session.sql

-- some initial data

    insert into auth_.app (app_id, name)
        values
        ('auth', 'authentication/authorization')
        on conflict do nothing;

    insert into auth_.param (app_id, name, description, value, option)
        values
        ('auth', 'user_access', 'allow access', 'true', '[true,false]'),
        ('auth', 'admin_access', 'allow access to auth admin functionality', 'false', '[true,false]'),
        ('auth', 'sys_access', 'allow access to auth admin functionality', 'false', '[true,false]')
        on conflict do nothing;

    insert into auth_.auth (auth_id, path)
        values
        ('is-user', '$.auth.user_access'),
        ('is-admin', '$.auth.admin_access'),
        ('is-sys', '$.auth.sys_access')
        on conflict do nothing;

\endif