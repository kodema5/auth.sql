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

\if :test
\if :local

    -- initialize jwt keys
    --
    insert into _jwt.key (id, value)
    values
        ('foo', 'test-jwt-key-a'),
        ('bar', md5(uuid_generate_v4()::text));

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
        ('ui.font', 'default font', jsonb_build_object(
            'family', 'verdana',
            'size', '10pt'
        ));

    insert into _auth.setting_template (id, setting_id, value)
        values
        ('brand', 'ui.font', jsonb_build_object(
            'family', 'arial',
            'size', '10pt'
        )),
        ('brand.admin', 'ui.font', jsonb_build_object(
            'family', 'monaco',
            'size', '10pt'
        ));

    insert into _auth.setting_signon (signon_id, setting_id, value)
        values
        ('test-signon-id', 'ui.font', jsonb_build_object(
            'family', 'times new roman',
            'size', '10pt'
        ));

\endif
\endif