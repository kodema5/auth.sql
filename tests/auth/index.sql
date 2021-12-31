create function tests.startup_auth() returns setof text as $$
begin
    insert into auth_.namespace (id) values ('dev');

    insert into auth_.user (signon_id, signon_key, role) values
        ('foo.user', crypt('foo.password', gen_salt('bf', 8)), 'user'),
        ('foo.admin', crypt('foo.password', gen_salt('bf', 8)), 'admin'),
        ('foo.system', crypt('foo.password', gen_salt('bf', 8)), 'system');

    insert into auth_.setting (key, value, description) values
        ('test.a', to_jsonb(100), 'test a'),
        ('test.b', to_jsonb(200), 'test b'),
        ('test.c', to_jsonb(300), 'test c');

    return next 'startup-auth';

end;
$$ language plpgsql;

create function tests.shutdown_auth() returns setof text as $$
begin
    delete from auth_.namespace where id = 'dev';
    return next 'shutdown-auth';
end;
$$ language plpgsql;

create function tests.session_as_foo_user() returns jsonb as $$
declare
    r jsonb;
begin
    r = auth.web_signon(jsonb_build_object(
        'namespace', 'dev',
        'signon_id', 'foo.user',
        'signon_key', 'foo.password'
    ));
    return jsonb_build_object('session_id', r->'session_id');
end;
$$ language plpgsql;

create function tests.session_as_foo_admin() returns jsonb as $$
declare
    r jsonb;
begin
    r = auth.web_signon(jsonb_build_object(
        'namespace', 'dev',
        'signon_id', 'foo.admin',
        'signon_key', 'foo.password'
    ));
    return jsonb_build_object('session_id', r->'session_id');
end;
$$ language plpgsql;

\ir change_password.sql
\ir registration.sql
\ir signon_signoff.sql
\ir setting.sql