create type auth.web_signon_it as (
    _auth auth.auth_t,
    namespace text,
    signon_id text,
    signon_key text,
    setting text
);

create function auth.web_signon(req jsonb) returns jsonb as $$
declare
    it auth.web_signon_it = jsonb_populate_record(null::auth.web_signon_it, auth.auth(req, false));
    u auth_.user;
begin
    -- "is not null" does not work here
    if not (it._auth is null) then
        raise exception 'error.existing_session_found';
    end if;

    if not exists (select from auth_.namespace where id=it.namespace)
    then
        raise exception 'error.invalid_namespace';
    end if;



    select * into u
    from auth_.user t
    where t.ns_id = it.namespace
        and t.signon_id = it.signon_id
        and t.signon_key = crypt(it.signon_key, t.signon_key);
    if u is null then
        raise exception 'error.unrecognized_signon';
    end if;

    return to_jsonb(auth.new_session(
        u.id,
        coalesce(it.setting, 'ui.*')
    ));
end;
$$ language plpgsql;


\if :test

    create function tests.test_auth_web_signon() returns setof text as $$
    declare
        a jsonb;
    begin
        return next throws_ok(format('select auth.web_signon(null)', a), 'error.invalid_namespace');

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