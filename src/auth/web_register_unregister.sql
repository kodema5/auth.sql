create type auth.web_register_it as (
    namespace text,
    signon_id text,
    signon_key text,
    signon_key_confirm text,
    _auth jsonb
);

create function auth.web_register(req jsonb) returns jsonb as $$
declare
    it auth.web_register_it = jsonb_populate_record(null::auth.web_register_it, req);
    u auth_.user;
begin
    if it.signon_id is null or length(it.signon_id)<8 then
        raise exception 'error.invalid_signon_id';
    end if;

    if it.signon_key is null or length(it.signon_key)<8 then
        raise exception 'error.invalid_signon_key';
    end if;

    if it.signon_key <> it.signon_key_confirm then
        raise exception 'error.invalid_signon_key_confirmation';
    end if;

    insert into auth_.user (ns_id, signon_id, signon_key)
        values (
            it.namespace,
            it.signon_id,
            crypt(it.signon_key, gen_salt('bf', 8))
        )
        returning * into u;

    return to_jsonb(auth.new_session(u.id));

end;
$$ language plpgsql;



create type auth.web_unregister_it as (
    _auth jsonb
);

create function auth.web_unregister(req jsonb) returns jsonb as $$
declare
    it auth.web_unregister_it = jsonb_populate_record(null::auth.web_unregister_it, auth.auth(req));
    a jsonb;
begin
    a = it._auth;
    if a is null then
        raise exception 'error.invalid_session';
    end if;

    delete from auth_.session where id = a->>'session_id';

    delete from auth_.user where signon_id = a->>'signon_id';

    return jsonb_build_object('success', true);
end;
$$ language plpgsql;



\if :test
    create function tests.test_auth_registration() returns setof text as $$
    declare
        res jsonb;
    begin
        res = auth.web_register(jsonb_build_object(
            'namespace', 'dev',
            'signon_id', 'foo.test',
            'signon_key', 'foo.password',
            'signon_key_confirm', 'foo.password'
        ));

        return next ok (
            (select count(1) from auth_.user where ns_id='dev' and signon_id='foo.test') = 1,
            'foo.test is able to register');

        perform auth.web_unregister(res);

        return next ok (
            (select count(1) from auth_.user where ns_id='dev' and signon_id='foo.test') = 0,
            'foo.test is able to unregister');

    end;
    $$ language plpgsql;
\endif

