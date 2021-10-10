------------------------------------------------------------------------------

create function auth.web_signon(req jsonb) returns jsonb as $$
declare
    namespace_ text = req->>'namespace';
    signon_name_ text = req->>'signon_name';
    signon_pwd_ text = req->>'signon_pwd';
    s auth.session;
    u auth.signon;
begin
    call auth.log('web_signon', req);

    select * into u
    from auth.signon t
    where t.namespace=namespace_
        and t.name=signon_name_
        and t.pwd=crypt(signon_pwd_, t.pwd);
    if u is null then
        raise exception 'error.unrecognized_signon';
    end if;

    insert into auth.session (signon_id) values (u.id) returning * into s;

    update auth.signon set last_signon_tz = current_timestamp where id=u.id;

    return jsonb_build_object(
        'session_id', s.id,
        'signon_name', u.name,
        'last_signon_tz', u.last_signon_tz,
        'setting', auth.setting_get('ui.*', namespace_, u.id)
    );
end;
$$ language plpgsql;