create type auth.web_signoff_it as (
    _auth jsonb
);

create function auth.web_signoff(req jsonb) returns jsonb as $$
declare
    it auth.web_signoff_it = jsonb_populate_record(null::auth.web_signoff_it, auth.auth(req));
    a jsonb;
begin
    a = it._auth;
    if a is null then
        raise exception 'error.invalid_session';
    end if;

    delete from auth_.session where id = a->>'session_id';

    if not found then
        raise exception 'error.invalid_session';
    end if;

    return jsonb_build_object('success', true);
end;
$$ language plpgsql;




