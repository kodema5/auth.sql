
create type auth.web_register_it as (
    _auth auth.auth_t,
    namespace text,
    signon_id text,
    signon_key text,
    signon_key_confirm text

);

-- returns auth.new_session_t

create function auth.web_register(req jsonb) returns jsonb as $$
declare
    it auth.web_register_it = jsonb_populate_record(null::auth.web_register_it, req);
    u auth_.user;
    pwd text;
begin
    if not exists (select from auth_.namespace where id=it.namespace)
    then
        raise exception 'error.invalid_namespace';
    end if;

    if it.signon_id is null or length(it.signon_id)<8 then
        raise exception 'error.invalid_signon_id';
    end if;

    if exists (select from auth_.user where ns_id=it.namespace and signon_id=it.signon_id) then
        raise exception 'error.signon_id_exists';
    end if;

    pwd = auth.crypt_signon_key(it.signon_key);
    if pwd is null then
        raise exception 'error.invalid_signon_key';
    end if;

    if it.signon_key <> it.signon_key_confirm then
        raise exception 'error.invalid_signon_key_confirm';
    end if;

    insert into auth_.user (ns_id, signon_id, signon_key)
        values (
            it.namespace,
            it.signon_id,
            pwd
        )
        returning * into u;

    return to_jsonb(auth.new_session(u.id));
end;
$$ language plpgsql;


\if :test
    create function tests.test_auth_web_register() returns setof text as $$
    declare
        a jsonb;
    begin
        return next throws_ok(format('select auth.web_register(null)', a), 'error.invalid_namespace');

        a = jsonb_build_object(
            'namespace', 'dev'
        );
        return next throws_ok(format('select auth.web_register(%L::jsonb)', a), 'error.invalid_signon_id');

        a = jsonb_build_object(
            'namespace', 'dev',
            'signon_id', 'foo.user',
            'signon_key', 'foo.password',
            'signon_key_confirm', 'foo.password'
        );
        return next throws_ok(format('select auth.web_register(%L::jsonb)', a), 'error.signon_id_exists');

        a = jsonb_build_object(
            'namespace', 'dev',
            'signon_id', 'foo.test',
            'signon_key', 'foo',
            'signon_key_confirm', 'foo.password'
        );
        return next throws_ok(format('select auth.web_register(%L::jsonb)', a), 'error.invalid_signon_key');

        a = jsonb_build_object(
            'namespace', 'dev',
            'signon_id', 'foo.test',
            'signon_key', 'foo.password',
            'signon_key_confirm', 'foo.-----'
        );
        return next throws_ok(format('select auth.web_register(%L::jsonb)', a), 'error.invalid_signon_key_confirm');


        a = auth.web_register(jsonb_build_object(
            'namespace', 'dev',
            'signon_id', 'foo.test',
            'signon_key', 'foo.password',
            'signon_key_confirm', 'foo.password'
        ));

        return next ok (
            (select count(1) from auth_.user where ns_id='dev' and signon_id='foo.test') = 1,
            'foo.test is able to register');
    end;
    $$ language plpgsql;

\endif

