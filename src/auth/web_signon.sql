create type auth.web_signon_it as (
    _auth auth.auth_t,
    namespace text,
    signon_id text,
    signon_key text,
    setting text
);

create type auth.web_signon_t as (
    session_id text,
    setting jsonb
);

create function auth.web_signon (
    it auth.web_signon_it
)
returns auth.web_signon_t
as $$
declare
    a auth.web_signon_t;
    u auth_.user;
    s auth_.session;
begin
    -- "is not null" does not work here
    if not (it._auth is null)
        and not (it._auth).is_admin
    then
        raise exception 'error.existing_session_found';
    end if;

    if not exists (
        select from auth_.namespace
        where id = it.namespace)
    then
        raise exception 'error.invalid_namespace';
    end if;

    select *
    into u
    from auth_.user t
    where t.ns_id = it.namespace
    and t.signon_id = it.signon_id
    and t.signon_key = crypt(it.signon_key, t.signon_key);

    if u is null then
        raise exception 'error.unrecognized_signon';
    end if;

    insert into auth_.session (user_id)
    values (u.id)
    returning *
    into s;

    a.session_id = s.id;
    a.setting = auth.get_setting(
        coalesce(it.setting, 'ui.*'),
        u.ns_id,
        u.id
    );
    return a;
end;
$$ language plpgsql;

create function auth.web_signon(req jsonb)
returns jsonb
as $$
    select to_jsonb(auth.web_signon(
        jsonb_populate_record(
            null::auth.web_signon_it,
            auth.auth(req, false))
    ))
$$ language sql stable;


\if :test
    create function tests.test_auth_web_signon() returns setof text as $$
    declare
        a jsonb;
    begin
        return next throws_ok(format('select auth.web_signon(null::jsonb)', a), 'error.invalid_namespace');

        a = tests.session_as_foo_user();
        return next throws_ok(format('select auth.web_signon(%L::jsonb)', a), 'error.existing_session_found');

        a = jsonb_build_object(
            'namespace', 'xxx'
        );
        return next throws_ok(format('select auth.web_signon(%L::jsonb)', a), 'error.invalid_namespace');

        a = jsonb_build_object(
            'namespace', 'dev',
            'signon_id', 'foo.userx',
            'signon_key', 'foo.password'
        );
        return next throws_ok(format('select auth.web_signon(%L::jsonb)', a), 'error.unrecognized_signon');

        a = jsonb_build_object(
            'namespace', 'dev',
            'signon_id', 'foo.user',
            'signon_key', 'foo.passwordx'
        );
        return next throws_ok(format('select auth.web_signon(%L::jsonb)', a), 'error.unrecognized_signon');

        a = jsonb_build_object(
            'namespace', 'dev',
            'signon_id', 'foo.user',
            'signon_key', 'foo.password',
            'setting', 'test.*'
        );
        a = auth.web_signon(a);
        return next ok(a->>'session_id' is not null, 'got session-id');
        return next ok(jsonb_typeof(a->'setting') = 'object', 'got setting');

    end;
    $$ language plpgsql;

\endif