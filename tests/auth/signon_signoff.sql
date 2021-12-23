create function tests.test_auth_signon_signoff() returns setof text as $$
declare
    res jsonb;
begin
    res = auth.web_signon(jsonb_build_object(
        'namespace', 'dev',
        'signon_id', 'foo.user',
        'signon_key', 'foo.password'
    ));
    return next ok(
        res is not null
        and res['session_id'] is not null
    , 'foo.user is able to signon');

    res = auth.web_signoff(res);
    return next ok((res->'success')::boolean, 'able to signoff');
end;
$$ language plpgsql;


