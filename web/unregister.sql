------------------------------------------------------------------------------

create function auth.web_unregister(req jsonb) returns jsonb as $$
declare
    u auth.user;
begin
    req = auth.auth(req);
    delete from auth.user where id=req->>'user_id' returning * into u;

    return jsonb_build_object(
        'unregistered', true,
        'user_name', u.name
    );

end;
$$ language plpgsql;

