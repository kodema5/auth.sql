
create type auth_admin.web_sessions_put_it as (
    _auth auth.auth_t,
    user_id text
);


create function auth_admin.web_sessions_put(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_sessions_put_it = jsonb_populate_record(null::auth_admin.web_sessions_put_it, auth_admin.auth(req));
    res jsonb;
begin
    if it.user_id is null or not exists (select from auth_.user where id=it.user_id) then
        raise exception 'error.invalid_user_id';
    end if;

    return to_jsonb(auth.new_session(it.user_id));
end;
$$ language plpgsql;


\if :test
    create function tests.test_auth_admin_web_sessions_put() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_admin();
        a jsonb;
    begin
        a = sid;
        return next throws_ok(format('select auth_admin.web_sessions_put(%L::jsonb)', a), 'error.invalid_user_id');

        a = sid || jsonb_build_object(
            'user_id', 'xxxx'
        );
        return next throws_ok(format('select auth_admin.web_sessions_put(%L::jsonb)', a), 'error.invalid_user_id');


        a = auth_admin.web_sessions_put(sid || jsonb_build_object(
            'user_id', auth.get_user_id('dev', 'foo.user')
        ));
        return next ok(a->>'session_id' is not null, 'get new session');

    end;
    $$ language plpgsql;
\endif

