drop schema if exists auth cascade;
create schema if not exists auth;

\if :test
\if :local

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


\ir auth.sql
\ir settings.sql
\ir signon/index.sql
\ir signoff/index.sql
\ir register/index.sql
