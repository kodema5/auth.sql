create function tests.startup_auth() returns setof text as $$
begin
    insert into auth_.namespace (id) values ('dev');

    insert into auth_.user (signon_id, signon_key, role) values
        ('foo.user', crypt('foo.password', gen_salt('bf', 8)), 'user'),
        ('foo.admin', crypt('foo.password', gen_salt('bf', 8)), 'admin'),
        ('foo.system', crypt('foo.password', gen_salt('bf', 8)), 'system');

    return next 'startup-auth';

end;
$$ language plpgsql;

create function tests.shutdown_auth() returns setof text as $$
begin
    delete from auth_.namespace where id = 'dev';
    return next 'shutdown-auth';
end;
$$ language plpgsql;

\ir registration.sql
\ir signon_signoff.sql