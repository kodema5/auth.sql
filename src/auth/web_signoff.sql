create type auth.web_signoff_it as (
    _auth jsonb
);

create function auth.web_signoff(req jsonb) returns jsonb as $$
declare
    it auth.web_signoff_it = jsonb_populate_record(null::auth.web_signoff_it, auth.auth(req));
begin
    delete from auth_.session where id = (it._auth)->>'session_id';

    return jsonb_build_object('success', true);
end;
$$ language plpgsql;




