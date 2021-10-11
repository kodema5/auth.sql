------------------------------------------------------------------------------

create function auth.web_register(req jsonb) returns jsonb as $$
declare
    user_name text = req->>'user_name';
    user_pwd text = req->>'user_pwd';
    ns_ text;
    u auth.user;
    s auth.session;
begin
    req = auth.auth(req);
    ns_ = req->>'namespace';
    insert into auth.user (namespace, name, pwd)
        values (ns_, user_name, user_pwd)
        returning * into u;

    insert into auth.session (user_id) values (u.id) returning * into s;

    return jsonb_build_object(
        'session_id', s.id,
        'user_name', u.name,
        'last_signon_tz', null,
        'setting', auth.setting_get('ui.*', ns_, u.id)
    );
end;
$$ language plpgsql;