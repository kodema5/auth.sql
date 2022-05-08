-- to register a new user

create type auth.register_it as (
    signon_name text,
    signon_password text
);

create type auth.register_t as (
    session_id text
);


create function auth.register(
    v auth.register_it,
    req jsonb default null
)
    returns auth.register_t
    language plpgsql
    security definer
as $$
declare
    u _auth.signon;
    s _auth.session;
    a auth.register_t;
begin
    if exists (
        select from _auth.signon
        where name=v.signon_name
    ) then
        raise exception 'error.signon_name_not_available';
    end if;

    insert into _auth.signon (name, is_active)
        values (
            v.signon_name,
            true
        )
        returning * into u;

    insert into _auth.signon_password (signon_id, password)
        values (
            u.id,
            crypt(v.signon_password, gen_salt('bf'))
        );

    insert into _auth.session (signon_id, origin, authenticated)
        values (
            u.id,
            req->>'_origin',
            true
        )
        returning * into s;

    a.session_id = s.id;
    return a;
end;
$$;

create function auth.web_register (
    req jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select to_jsonb(auth.register(
        jsonb_populate_record(
            null::auth.register_it,
            coalesce(a['data'], a)
        ),
        req
    ))
    from (select auth.auth(req)) as t(a)
$$;


\if :test
    create function tests.test_auth_register() returns setof text language plpgsql as $$
    declare
        req jsonb;
        res jsonb;
    begin
        res = auth.web_register(jsonb_build_object(
            'signon_name', 'foo',
            'signon_password', 'bar'
        ));
        return next ok(true, 'able to register');
        return next ok(res->'session_id' is not null, 'is automatically signed-in');

        res = auth.web_signon(jsonb_build_object(
            'signon_name', 'foo',
            'signon_password', 'bar'
        ));
        return next ok(res->'session_id' is not null, 'able to signon');
    end;
    $$;
\endif




