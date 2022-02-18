create type auth.web_signoff_it as (
    _auth auth.auth_t
);


create type auth.web_signoff_t as (
    success boolean
);

create function auth.web_signoff(
    it auth.web_signoff_it
)
returns auth.web_signoff_t as $$
declare
    a auth.web_signoff_t;
begin
    if it._auth is null then
        raise exception 'error.invalid_session';
    end if;

    delete from auth_.session
    where id = (it._auth).session_id;

    a.success = true;
    return a;
end;
$$ language plpgsql;


create function auth.web_signoff(req jsonb)
returns jsonb as $$
    select to_jsonb(auth.web_signoff(
        jsonb_populate_record(
            null::auth.web_signoff_it,
            auth.auth(req))
    ))
$$ language sql stable;


\if :test
    create function tests.test_auth_web_signoff() returns setof text as $$
    declare
        a jsonb;
    begin
        a = tests.session_as_foo_user();
        a = auth.web_signoff(a);
        return next ok((a->'success')::boolean, 'able to signoff');
    end;
    $$ language plpgsql;
\endif

