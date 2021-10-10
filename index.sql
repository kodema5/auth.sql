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
    create domain auth.namespace_t as text
    not null
    default 'dev';
exception when duplicate_object then null; end; $$;

create table auth.NAMESPACE (
    id auth.namespace_t primary key
);

create table auth.SETTING_NAMESPACE (
    namespace auth.namespace_t references auth.namespace(id) on delete cascade,
    key ltree references auth.setting(key) on delete cascade,
    value jsonb,
    unique (namespace, key)
);

------------------------------------------------------------------------------
-- NAMESPACE = [SIGNON]

do $$ begin
    create domain auth.signon_t as text
    default md5(uuid_generate_v4()::text);
exception when duplicate_object then null; end; $$;

create table auth.SIGNON (
    id auth.signon_t primary key,
    namespace auth.namespace_t references auth.namespace(id) on delete cascade
);

create table auth.SETTING_SIGNON (
    signon_id auth.signon_t references auth.signon(id) on delete cascade,
    key ltree references auth.setting(key) on delete cascade,
    value jsonb,
    unique (signon_id, key)
);

------------------------------------------------------------------------------
-- signon = SIGNON -> [SESSION]

do $$ begin
    create domain auth.session_t as text
    not null
    default md5(uuid_generate_v4()::text);
exception when duplicate_object then null; end; $$;

create table auth.SESSION (
    id auth.session_t primary key,
    signon_id auth.signon_t references auth.signon(id) on delete cascade
);

------------------------------------------------------------------------------
-- auth = SESSION -> AUTH

do $$ begin
    create domain auth.auth_t as jsonb
    not null
    check (
        value ? 'namespace' and value ? 'signon_id' and value ? 'signon_name'
    );
exception when duplicate_object then null; end; $$;


------------------------------------------------------------------------------
-- application specific
------------------------------------------------------------------------------

\ir app/setting.sql
\ir app/signon.sql
\ir app/session.sql

------------------------------------------------------------------------------
-- scheduled job
------------------------------------------------------------------------------

\ir job/delete_expired_sessions.sql

------------------------------------------------------------------------------
-- web interface
------------------------------------------------------------------------------

\ir auth.sql
\ir web/signon.sql
\ir web/signoff.sql

------------------------------------------------------------------------------
-- quick sanity check
------------------------------------------------------------------------------

insert into auth.namespace (id) values ('dev');
insert into auth.signon(name, pwd, role) values ('foo@abc.com', crypt('bar', gen_salt('bf', 8)), 'admin');

insert into auth.setting(key, value) values ('ui.font.size', to_jsonb('14pt'::text));
insert into auth.setting_namespace(namespace, key, value) values ('dev', 'ui.font.size', to_jsonb('15pt'::text));
insert into auth.setting_signon(signon_id, key, value) values (auth.signon_id('dev', 'foo@abc.com'), 'ui.font.size', to_jsonb('16pt'::text));

create function auth.register(req jsonb) returns jsonb as $$
declare
    signon_name text = req->>'signon_name';
    signon_pwd text = req->>'signon_pwd';
    u auth.signon;

begin
    req = auth.auth(req);
    insert into auth.signon (namespace, name, pwd)
        values (req->>'namespace', signon_name, signon_pwd)
        returning * into u;



end;
$$ language plpgsql;

select '----auth', auth.auth(jsonb_build_object());



do $$
declare
    r jsonb;
begin
    raise warning '------------------------------------------------------------------------------';
    r = auth.web_signon(jsonb_build_object(
        'namespace', 'dev',
        'signon_name', 'foo@abc.com',
        'signon_pwd', 'bar'
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