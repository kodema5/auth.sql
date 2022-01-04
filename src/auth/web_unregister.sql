create type auth.web_unregister_it as (
    _auth auth.auth_t,
    signon_key text,
    signon_key_confirm text
);

create function auth.web_unregister(req jsonb) returns jsonb as $$
declare
    it auth.web_unregister_it = jsonb_populate_record(null::auth.web_unregister_it, auth.auth(req));
begin
    if it._auth is null then
        raise exception 'error.invalid_session';
    end if;

    if not exists (
        select from auth_.user t
        where id=(it._auth).user_id
        and t.signon_key = crypt(it.signon_key, t.signon_key)
    ) then
        raise exception 'error.invalid_signon_key';
    end if;

    if it.signon_key <> it.signon_key_confirm then
        raise exception 'error.invalid_signon_key_confirm';
    end if;


    delete from auth_.session where id = (it._auth).session_id;

    delete from auth_.user where signon_id = (it._auth).signon_id;

    return jsonb_build_object('success', true);
end;
$$ language plpgsql;



\if :test
    create function tests.test_auth_registration() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_user();
        a jsonb;
    begin
        a = sid;
        return next throws_ok(format('select auth.web_unregister(%L::jsonb)', a), 'error.invalid_signon_key');

        a = sid || jsonb_build_object(
            'signon_key', 'foo.password',
            'signon_key_confirm', 'foo.----'
        );
        return next throws_ok(format('select auth.web_unregister(%L::jsonb)', a), 'error.invalid_signon_key_confirm');

        a = sid || jsonb_build_object(
            'signon_key', 'foo.password',
            'signon_key_confirm', 'foo.password'
        );
        execute format('select auth.web_unregister(%L::jsonb)', a) into a;
        return next ok((a->>'success')::boolean, 'able to unregister');

        return next ok (
            not exists (select from auth_.user where ns_id='dev' and signon_id='foo.user'),
            'foo.user is able to unregister');
    end;
    $$ language plpgsql;
\endif

