drop type if exists web.user_register_it cascade;
create type web.user_register_it as (
    email text,
    password text
);

create or replace function web.user_register (
    it web.user_register_it
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    uid text = util.get_config('session.user_id');
    usr user_.user;
    ses session_.session;
begin
    if uid <> ''
    then
        raise exception 'web.user_register.existing_session_found';
    end if;

    if not util.is_email(it.email)
    then
        raise exception 'web.user_register.invalid_email';
    end if;

    if it.password is null
    or length(it.password)<8
    then
        raise exception 'web.user_register.invalid_password';
    end if;

    usr = "user".get_by_email(it.email);
    if usr.id is not null
    then
        raise exception 'web.user_register.existing_user_found';
    end if;

    usr = "user".new(it.email, it.password);

    ses = session.new(usr.id);

    return jsonb_build_object(
        '_headers', jsonb_build_object(
            'authorization', ses.id
        )
    );
end;
$$;

create or replace function web.user_register (
    it jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select web.user_register(jsonb_populate_record(
        null::web.user_register_it,
        session.auth(it)
    ))
$$;


\if :test
    create function tests.test_web_user_register()
        returns setof text
        language plpgsql
    as $$
    declare
        res jsonb;
        req jsonb;
    begin
        res = web.user_register(jsonb_build_object(
            'email', 'foo@example.com',
            'password', '12345678'
        ));
        return next ok(res->'_headers'->>'authorization' is not null,
            'able to register');
        perform session.end();

        return next throws_ok(
            format('select web.user_register(%L::jsonb)',
                jsonb_build_object('email', 'foo@example.com', 'password', '12345678')
            ),
            'web.user_register.existing_user_found',
            'disallow re-register existing user'
        );

        return next throws_ok(
            format('select web.user_register(%L::jsonb)',
                jsonb_build_object('email', 'foo.example.com', 'password', '12345678')
            ),
            'web.user_register.invalid_email',
            'disallow invalid email'
        );

        return next throws_ok(
            format('select web.user_register(%L::jsonb)',
                jsonb_build_object('email', 'foo@example.com')
            ),
            'web.user_register.invalid_password',
            'disallow invalid password'
        );
        perform session.end();

    end;
    $$;
\endif