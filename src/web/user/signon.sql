drop type if exists web.user_signon_it cascade;
create type web.user_signon_it as (
    email text,
    password text,
    _uid text,
    _sid text
);

create or replace function web.user_signon (
    it web.user_signon_it
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    usr user_.user;
    ses session_.session;
begin
    if util.get_config('session.user_id') <> ''
    then
        raise exception 'web.user_signon.existing_session_found';
    end if;

    usr = "user".get(it.email, it.password);
    if usr.id is null then
        raise exception 'web.user_signon.usr_not_found';
    end if;

    ses = session.new(usr.id);

    return jsonb_build_object(
        '_headers', jsonb_build_object(
            'authorization', ses.id
        )
    );
end;
$$;

create or replace function web.user_signon (
    it jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select web.user_signon(jsonb_populate_record(
        null::web.user_signon_it,
        session.auth(it)
    ))
$$;



\if :test
    create function tests.test_web_user_signon()
        returns setof text
        language plpgsql
    as $$
    declare
        u user_.user = "user".new('foo@example.com','bar');
        res jsonb;
    begin
        return next throws_ok(
            format('select web.user_signon(%L::jsonb)',
                jsonb_build_object('email', 'foo', 'password', 'bar')
            ),
            'web.user_signon.usr_not_found',
            'disallow signon of incorrect credential'
        );

        res = web.user_signon(jsonb_build_object(
            'email', 'foo@example.com',
            'password', 'bar'
        ));
        return next ok(res->'_headers'->>'authorization' is not null,
            'allow signon with valid email and password');

        return next throws_ok(
            format('select web.user_signon(%L::jsonb)',
                res
            ),
            'web.user_signon.existing_session_found',
            'disallow signon in valid session'
        );

        perform session.end();
    end;
    $$;
\endif