create type auth.web_signoff_it as (
    _auth auth.auth_t
);

create function auth.web_signoff(req jsonb) returns jsonb as $$
declare
    it auth.web_signoff_it = jsonb_populate_record(null::auth.web_signoff_it, auth.auth(req));
begin

    if it._auth is null then
        raise exception 'error.invalid_session';
    end if;

    delete from auth_.session where id = (it._auth).session_id;

    return jsonb_build_object('success', true);
end;
$$ language plpgsql;



\if :test
    create function tests.test_auth_signoff() returns setof text as $$
    declare
        a jsonb;
    begin
        return next throws_ok(format('select auth.web_signoff(null)', a), 'error.invalid_session');

        a = tests.session_as_foo_user();
        a = auth.web_signoff(a);
        return next ok((a->'success')::boolean, 'able to signoff');
    end;
    $$ language plpgsql;
\endif

