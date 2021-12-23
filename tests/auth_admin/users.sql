create function tests.test_auth_admin_users() returns setof text as $$
declare
    sid jsonb = tests.session_as_foo_admin();
    res jsonb;
begin
    res = auth_admin.web_users( sid || jsonb_build_object('x', 1));
    return next ok( (select count(1)
        from jsonb_array_elements ( res->'users' ) a
        where a->>'signon_id' = 'foo.admin'
    ) = 1, 'has foo.admin');

end;
$$ language plpgsql;
