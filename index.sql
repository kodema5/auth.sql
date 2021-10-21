------------------------------------------------------------------------------
-- q: what is a simple user authentication/authorization module?

create extension if not exists "uuid-ossp" schema public;
create extension if not exists pgcrypto schema public;
create extension if not exists ltree schema public;
create extension if not exists pg_cron schema public;

drop schema if exists auth cascade;
create schema auth;
\ir lib/index.sql

------------------------------------------------------------------------------
-- SETTING

create table auth.SETTING (
    key ltree primary key not null,
    value jsonb
);

------------------------------------------------------------------------------
-- NAMESPACE

do $$ begin
    create domain auth.namespace_id_t as text
    not null
    default 'dev';
exception when duplicate_object then null; end; $$;

create table auth.NAMESPACE (
    id auth.namespace_id_t primary key
);

create table auth.SETTING_NAMESPACE (
    namespace auth.namespace_id_t references auth.namespace(id) on delete cascade,
    key ltree references auth.setting(key) on delete cascade,
    value jsonb,
    unique (namespace, key)
);

------------------------------------------------------------------------------
-- NAMESPACE = [USER]

do $$ begin
    create domain auth.user_id_t as text
    default md5(uuid_generate_v4()::text);
exception when duplicate_object then null; end; $$;

create table auth.user (
    id auth.user_id_t primary key,
    namespace auth.namespace_id_t references auth.namespace(id) on delete cascade
);

create table auth.SETTING_USER (
    user_id auth.user_id_t references auth.user(id) on delete cascade,
    key ltree references auth.setting(key) on delete cascade,
    value jsonb,
    unique (user_id, key)
);

------------------------------------------------------------------------------
-- signon = USER -> [SESSION]

do $$ begin
    create domain auth.session_id_t as text
    not null
    default md5(uuid_generate_v4()::text);
exception when duplicate_object then null; end; $$;

create table auth.SESSION (
    id auth.session_id_t primary key,
    user_id auth.user_id_t references auth.user(id) on delete cascade
);


------------------------------------------------------------------------------
-- application specific
------------------------------------------------------------------------------

\ir app/setting.sql
\ir app/user.sql
\ir app/session.sql

------------------------------------------------------------------------------
-- scheduled job
------------------------------------------------------------------------------

\ir job/delete_expired_sessions.sql
\ir __cron__.sql

------------------------------------------------------------------------------
-- web interface
------------------------------------------------------------------------------

\ir auth.sql
\ir web/signon.sql
\ir web/signoff.sql
\ir web/register.sql
\ir web/unregister.sql
\ir web/namespace_delete.sql
\ir web/namespace_get.sql
\ir web/namespace_new.sql

------------------------------------------------------------------------------
-- quick sanity check
------------------------------------------------------------------------------

insert into auth.namespace (id) values ('dev');
insert into auth.user(name, pwd, role) values ('foo@abc.com', crypt('bar', gen_salt('bf', 8)), 'admin');

insert into auth.setting(key, value) values ('ui.font.size', to_jsonb('14pt'::text));
insert into auth.setting_namespace(namespace, key, value) values ('dev', 'ui.font.size', to_jsonb('15pt'::text));
insert into auth.setting_user(user_id, key, value) values (auth.user_id('dev', 'foo@abc.com'), 'ui.font.size', to_jsonb('16pt'::text));

do $$
declare
    r jsonb;
begin
    raise warning '------------------------------------------------------------------------------';
    r = auth.web_register(jsonb_build_object(
        'namespace', 'dev',
        'user_name', 'foo2@abc.com',
        'user_pwd', 'bar'
    ));
    raise warning 'register %', jsonb_pretty(r);

    r = auth.web_unregister(jsonb_build_object(
        'session_id', r->>'session_id'
    ));
    raise warning 'unregister %', jsonb_pretty(r);

    r = auth.web_signon(jsonb_build_object(
        'namespace', 'dev',
        'user_name', 'foo@abc.com',
        'user_pwd', 'bar'
    ));
    raise warning 'signon %', jsonb_pretty(r);

    r = auth.web_signoff(jsonb_build_object(
        'namespace', 'dev',
        'session_id', r->>'session_id'
    ));

    raise warning 'signoff %', jsonb_pretty(r);

    raise warning '------------------------------------------------------------------------------';
end;
$$;

delete from auth.namespace where id='dev'; -- deletes all assets of a namespace
select ts, msg from auth.log;

call auth.__cron__();