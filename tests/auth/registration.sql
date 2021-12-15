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
