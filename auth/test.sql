\if :{?test}
\if :{?auth_test_sql}
\else
\set auth_test_sql true

    create function tests.startup_test_users ()
        returns setof text
        language plpgsql
    as $$
    declare
        usr auth_.user;
    begin
        insert into auth_.app (app_id)
        values ('test');

        insert into auth_.param (app_id, name, value)
        values
            ('test', 'test', '111');

        insert into auth_.brand (brand_id, apps)
        values('test', array['auth','test']);

        insert into auth_.user_type (brand_id, name, apps)
        values
            ('test', 'user', array['test','auth']),
            ('test', 'admin', array['test','auth']),
            ('test', 'sys', array['test','auth'])
        ;

        insert into auth_.setting (typeof, ref_id, app_id, value)
        values ('auth_.user_type', 'test::sys', 'auth', '{
            "sys_access":true
        }');

        insert into auth_.user (brand_id, name, user_type_id)
        values
            ('test', 'user', 'test::user'),
            ('test', 'admin', 'test::admin'),
            ('test', 'sys', 'test::sys')
        ;

        insert into auth_.user_ (user_id, password)
        values
            ('test::user', crypt('test', gen_salt('bf'))),
            ('test::admin', crypt('test', gen_salt('bf'))),
            ('test::sys', crypt('test', gen_salt('bf')))
        ;
        return next 'setup test';
    end;
    $$;

    create function tests.shutdown_test_users ()
        returns setof text
        language plpgsql
    as $$
    begin
        delete from auth_.app where app_id='test';
        delete from auth_.brand where brand_id = 'test';
        return next 'shutdown test';
    end;
    $$;

    create function tests.setup_reset_env()
        returns text
        language plpgsql
    as $$
    begin
        perform auth.env_t(null);
        return 'setup.reset_env';
    end;
    $$;

    create function tests.teardown_reset_env()
        returns text
        language plpgsql
    as $$
    begin
        perform auth.env_t(null);
        return 'teardown.reset_env';
    end;
    $$;
\endif
\endif
