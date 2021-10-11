------------------------------------------------------------------------------

create function auth.web_signon(req jsonb) returns jsonb as $$
declare
    namespace_ text = req->>'namespace';
    user_name_ text = req->>'user_name';
    user_pwd_ text = req->>'user_pwd';
    s auth.session;
    u auth.user;
begin
    call auth.log('web_signon', req);

    select * into u
    from auth.user t
    where t.namespace=namespace_
        and t.name=user_name_
        and t.pwd=crypt(user_pwd_, t.pwd);
    if u is null then
        raise exception 'error.unrecognized_signon';
    end if;

    insert into auth.session (user_id) values (u.id) returning * into s;

    update auth.user set last_signon_tz = current_timestamp where id=u.id;

    return jsonb_build_object(
        'session_id', s.id,
        'user_name', u.name,
        'last_signon_tz', u.last_signon_tz,
        'setting', auth.setting_get('ui.*', namespace_, u.id)
    );
end;
$$ language plpgsql;