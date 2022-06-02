create type auth.signon_it as (
    signon_name text,
    signon_password text
);

create type auth.signon_t as (
    session_id text
);

create function auth.signon (
    v auth.signon_it,
    req jsonb default null
)
    returns auth.signon_t
    language plpgsql
    security definer
as $$
declare
    a auth.signon_t;
    u _auth.signon;
    s _auth.session;
begin
    -- validate user/pwd pair
    select usr.*
        into u
        from _auth.signon usr
        join _auth.signon_password pwd
            on pwd.signon_id = usr.id
        where usr.name = v.signon_name
            and pwd.password = crypt(v.signon_password, pwd.password)
            and pwd.expired_tz is null;

    if u is null then
        raise exception 'error.unrecognized_signon';
    end if;

    -- create new session
    insert into _auth.session (
        signon_id,
        origin,
        authenticated
    )
        values (u.id, req->>'_origin', true)
        returning *
        into s;

    a.session_id = 'Bearer ' || jwt.encode(jsonb_build_object(
        'sid', s.id,
        'uid', u.id,
        'role', u.role
    ));
    if a.session_id is null then
        raise exception 'error.unable_to_generate_session_id';
    end if;

    return a;
end;
$$;

create function auth.web_signon (
    req jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select to_jsonb(auth.signon(
        jsonb_populate_record(
            null::auth.signon_it,
            coalesce(a['data'], a)
        ),
        req
    ))
    from (select auth.auth(req)) as t(a)
$$;


\if :test
    create function tests.test_auth_signon() returns setof text language plpgsql as $$
    declare
        req jsonb;
        res jsonb;
    begin
        res = auth.web_signon(jsonb_build_object(
            'data', jsonb_build_object(
                'signon_name', 'test-signon-name',
                'signon_password', 'foo'
            ),
            '_origin', 'test'
        ));


        return next ok(res->>'session_id' is not null, 'able to sign-on');
    end;
    $$;
\endif