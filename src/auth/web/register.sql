\if :{?auth_web_register_sql}
\else
\set auth_web_register_sql true

create type auth.register_it as (
    email text
);

create type auth.register_t as (
    confirm_id text
);

create function auth.register (
    it auth.register_it
)
    returns auth.register_t
    language plpgsql
    security definer
as $$
declare
    a auth.register_t;
    r confirm.confirm_t;
begin
    if not util.is_email(it.email)
    then
        raise exception 'auth.register.invalid_email';
    end if;

    if exists (
        select 1
        from _auth.user
        where email = it.email
    ) then
        raise exception 'auth.register.existing_email';
    end if;


    r = confirm.confirm (
        confirm_f_ := 'auth.confirm_register'::regproc,
        context_t_ := 'auth.register_it'::regtype,
        context_ := to_jsonb(it)
    );

    a.confirm_id = r.id;
    return a;
end;
$$;

call util.export(array[
    util.web_fn_t('auth.register(auth.register_it)')
]);


create function auth.confirm_register(
    it auth.register_it
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    u _auth.user;
begin
    if exists (
        select 1
        from _auth.user
        where email = it.email
    ) then
        raise exception 'auth.register.existing_user';
    end if;

    insert into _auth.user (
        email
    ) values (
        it.email
    )
    returning *
    into u;

    return auth.web_session(
        user_id_ := u.id
    );
end;
$$;


\if :test
    \ir ../auth.sql
    \ir ../session.sql

    create function tests.test_auth_web_register()
        returns setof text
        language plpgsql
    as $$
    declare
        a jsonb;
        t text;
        c confirm.confirm_t;
    begin
        -- on register, redirect user for confirmation id
        a = auth.web_register(jsonb_build_object(
            'email', 'foo@example.com'
        ));
        t = a->>'confirm_id';
        return next ok(t is not null, 'has confirmation id');

        -- send the confirmation code via email
        c = confirm.confirm(t);
        return next ok(c.code is not null, 'is the confirmation code to be emailed');

        -- user is to be directed to confirmation code
        a = confirm.web_confirm(jsonb_build_object(
            'id', t,
            'code', c.code
        ));
        return next ok(a is not null, 'is a web session-id');

        -- to get user-id
        a = auth.auth(a);
        return next ok(
            a->>'_uid' = auth.who(a->'_auth'->>'session_id'),
            'able to get user-id');

        -- consider next to direct user to set password
    end;
    $$;
\endif



\endif