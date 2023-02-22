drop type if exists web.user_change_password_it cascade;
create type web.user_change_password_it as (
    old text,
    new text
);

create or replace function web.user_change_password (
    it web.user_change_password_it
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
    if uid = ''
    then
        raise exception 'web.user_change_password.unrecognized_user';
    end if;

    if it.new is null or length(it.new)<8
    then
        raise exception 'web.user_register.invalid_password';
    end if;

    usr = "user".get_by_id(uid);
    if usr.id is null
    then
        raise exception 'web.user_register.unrecognized_user';
    end if;

    if util.get_config('session.user_role')='user'
    then
        usr = "usr".get(usr.email, it.old);
        if usr.id is null
        then
            raise exception 'web.user_register.existing_password_mismatched';
        end if;
    end if;

    perform "user".set_password(usr.id, it.new);

    return jsonb_build_object('success', true);
end;
$$;

create or replace function web.user_change_password (
    it jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select web.user_change_password(jsonb_populate_record(
        null::web.user_change_password_it,
        session.auth(it)
    ))
$$;


\if :test
    create function tests.test_web_user_change_password()
        returns setof text
        language plpgsql
    as $$
    declare
        res jsonb;
    begin
        res = web.user_register(jsonb_build_object(
            'email', 'foo@example.com',
            'password', '12345678'
        ));
        return next ok(res->'_headers'->>'authorization' is not null,
            'able to register');
        perform session.end();

        -- return next throws_ok(
        --     format('select web.user_register(%L::jsonb)',
        --         jsonb_build_object('email', 'foo@example.com', 'password', '12345678')
        --     ),
        --     'web.user_register.existing_user_found',
        --     'disallow re-register existing user'
        -- );

        -- return next throws_ok(
        --     format('select web.user_register(%L::jsonb)',
        --         jsonb_build_object('email', 'foo.example.com', 'password', '12345678')
        --     ),
        --     'web.user_register.invalid_email',
        --     'disallow invalid email'
        -- );

        -- return next throws_ok(
        --     format('select web.user_register(%L::jsonb)',
        --         jsonb_build_object('email', 'foo@example.com')
        --     ),
        --     'web.user_register.invalid_password',
        --     'disallow invalid password'
        -- );
        perform session.end();

    end;
    $$;
\endif