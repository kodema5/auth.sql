create function tests.test_auth_change_password() returns setof text as $$
declare
    sid jsonb = tests.session_as_foo_user();
    res jsonb;
begin
    res = auth.web_change_password(sid || jsonb_build_object(
        'old_signon_key', 'foo.password',
        'new_signon_key', 'foo.password2',
        'new_signon_key_confirm', 'foo.password2'
    ));
    return next ok((res->'success')::boolean = true, 'able to change password');
end;
$$ language plpgsql;