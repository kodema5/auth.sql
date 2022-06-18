-- web-dev watch auth.sql

-- add jwt.sql
\set skip_test false
\if :test
    \set skip_test true
    \set test false
\endif

\ir jwt.sql/jwt.sql

\if :skip_test
    \set test true
\endif


\ir ./src/_auth/index.sql
\ir ./src/auth/index.sql

insert into _jwt.key(id, value)
values
    (md5(uuid_generate_v4()::text), md5(uuid_generate_v4()::text)),
    (md5(uuid_generate_v4()::text), md5(uuid_generate_v4()::text));

\if :test
\if :local
    create function tests.startup()
        returns setof text
        language plpgsql
    as $$
    begin
        return next 'auth: startup';

        -- initialize jwt keys
        --
        insert into _jwt.key (id, value)
        values
            ('test-key-1', 'test-jwt-key-a'),
            ('test-key-2', md5(uuid_generate_v4()::text));

        -- for local testing purpose
        --
        insert into _auth.signon(id, name, role, is_active)
            values (
                'test-signon-id',
                'test-signon-name',
                'test',
                true)
            on conflict (name) do nothing;

        insert into _auth.signon_password (signon_id, password)
            values (
                'test-signon-id',
                crypt('foo', gen_salt('bf'))
            );

        insert into _auth.session (id, signon_id, origin, authenticated)
            values (
                'test-session-id',
                'test-signon-id',
                'test',
                true);

        insert into _auth.setting (id, description, value)
            values
            ('test.font', 'default font', jsonb_build_object(
                'family', 'verdana',
                'size', '10pt'
            ));

        insert into _auth.setting_template (id, setting_id, value)
            values
            ('brand', 'test.font', jsonb_build_object(
                'family', 'arial',
                'size', '10pt'
            )),
            ('brand.admin', 'test.font', jsonb_build_object(
                'family', 'monaco',
                'size', '10pt'
            ));

        insert into _auth.setting_signon (signon_id, setting_id, value)
            values
            ('test-signon-id', 'test.font', jsonb_build_object(
                'family', 'times new roman',
                'size', '10pt'
            ));
    end;
    $$;

    create function tests.shutdown()
        returns setof text
        language plpgsql
    as $$
    begin
        delete from _jwt.key where id='test-key-1';
        delete from _jwt.key where id='test-key-2';
        delete from _auth.signon where id='test-signon-id';
        delete from _auth.setting where id='test.font';
        return next 'auth: shutdown';
    end;
    $$;
\endif
\endif
