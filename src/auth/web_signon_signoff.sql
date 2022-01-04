create type auth.web_signon_it as (
    namespace text,
    signon_id text,
    signon_key text,
    setting text
);

create function auth.web_signon(req jsonb) returns jsonb as $$
declare
    it auth.web_signon_it = jsonb_populate_record(null::auth.web_signon_it, req);
    u auth_.user;
begin
    select * into u
    from auth_.user t
    where t.ns_id = it.namespace
        and t.signon_id = it.signon_id
        and t.signon_key = crypt(it.signon_key, t.signon_key);
    if u is null then
        raise exception 'error.unrecognized_signon';
    end if;

    return to_jsonb(auth.new_session(
        u.id,
        coalesce(it.setting, 'ui.*')
    ));
end;
$$ language plpgsql;


create type auth.web_signoff_it as (
    _auth auth.auth_t
);

create function auth.web_signoff(req jsonb) returns jsonb as $$
declare
    it auth.web_signoff_it = jsonb_populate_record(null::auth.web_signoff_it, auth.auth(req));
begin
    delete from auth_.session where id = (it._auth).session_id;

    return jsonb_build_object('success', true);
end;
$$ language plpgsql;



\if :test
    create function tests.test_auth_signon_signoff() returns setof text as $$
    declare
        res jsonb;
    begin
        res = auth.web_signon(jsonb_build_object(
            'namespace', 'dev',
            'signon_id', 'foo.user',
            'signon_key', 'foo.password',
            'setting', 'test.*'
        ));

        return next ok(
            res is not null
            and res['session_id'] is not null
        , 'foo.user is able to signon');

        return next ok(
            res is not null
            and res['setting'] is not null
        , 'foo.user has setting');


        res = auth.web_signoff(res);
        return next ok((res->'success')::boolean, 'able to signoff');
    end;
    $$ language plpgsql;
\endif

