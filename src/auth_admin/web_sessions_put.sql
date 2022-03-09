-- allows admin to work as user

create type auth_admin.web_sessions_put_it as (
    _auth auth.auth_t,
    user_id text
);


create type auth_admin.web_sessions_put_t as (
    session_id text,
    setting jsonb
);

create function auth_admin.web_sessions_put (
    it auth_admin.web_sessions_put_it
)
    returns auth_admin.web_sessions_put_t
    language plpgsql
    security definer
as $$
declare
    a auth_admin.web_sessions_put_t;
    u auth_.user;
    s auth_.session;
begin
    if it.user_id is null
    then
        raise exception 'error.invalid_user_id';
    end if;

    select *
    into u
    from auth_.user
    where id = it.user_id;

    if not found then
        raise exception 'error.invalid_user_id';
    end if;


    insert into auth_.session (user_id)
    values (u.id)
    returning *
    into s;

    a.session_id = s.id;
    a.setting = auth.get_setting(
        null,
        u.ns_id,
        u.id
    );
    return a;
end;
$$;


create function auth_admin.web_sessions_put (
    req jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select to_jsonb(auth_admin.web_sessions_put (
        jsonb_populate_record(
            null::auth_admin.web_sessions_put_it,
            auth_admin.auth(req))
    ))
$$;


\if :test
    create function tests.test_auth_admin_web_sessions_put()
        returns setof text
        language plpgsql
    as $$
    declare
        sid jsonb = tests.session_as_foo_admin();
        a jsonb;
    begin
        a = sid;
        return next throws_ok(format('select auth_admin.web_sessions_put(%L::jsonb)', a), 'error.invalid_user_id');

        a = sid || jsonb_build_object(
            'user_id', 'xxxx'
        );
        return next throws_ok(format('select auth_admin.web_sessions_put(%L::jsonb)', a), 'error.invalid_user_id');


        a = auth_admin.web_sessions_put(sid || jsonb_build_object(
            'user_id', auth.get_user_id('dev', 'foo.user')
        ));
        return next ok(a->>'session_id' is not null, 'get new session');

    end;
    $$;
\endif

