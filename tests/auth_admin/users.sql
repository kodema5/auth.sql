
create function tests.test_auth_admin_users() returns setof text as $$
declare
    sid jsonb = tests.session_as_foo_admin();
    res jsonb;
begin
    res = auth_admin.web_users( sid || jsonb_build_object('ns_id', 'dev'));
    return next ok( jsonb_path_query(res, '$.users[*] ? ( @.signon_id == "foo.admin" ) ') is not null, 'has foo.admin');

    res = auth_admin.web_users( sid || jsonb_build_object('signon_ids', jsonb_build_array('foo.admin')));
    return next ok(jsonb_array_length(res->'users') = 1, 'has foo.admin');
end;
$$ language plpgsql;
