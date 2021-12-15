create type auth.web_unregister_it as (
    _auth jsonb
);

create function auth.web_unregister(req jsonb) returns jsonb as $$
declare
    it auth.web_unregister_it = jsonb_populate_record(null::auth.web_unregister_it, auth.auth(req));
    a jsonb;
begin
    a = it._auth;
    if a is null then
        raise exception 'error.invalid_session';
    end if;

    delete from auth_.session where id = a->>'session_id';

    delete from auth_.user where signon_id = a->>'signon_id';

    return jsonb_build_object('success', true);
end;
$$ language plpgsql;




