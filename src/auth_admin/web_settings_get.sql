create type auth_admin.web_settings_get_it as (
    _auth jsonb,
    setting_key text -- default '*'
);

create function auth_admin.web_settings_get(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_settings_get_it = jsonb_populate_record(null::auth_admin.web_settings_get_it, auth_admin.auth(req));
    res jsonb;
    keys_ text = coalesce(it.setting_key, '*');
begin

    select jsonb_object_agg( s.key, to_jsonb(s))
    into res
    from auth_.setting s,
        ( select unnest (string_to_array(keys_, ',')) ) as keys (k)
    where s.key ~ (keys.k::lquery);

    return jsonb_build_object('setting', res);
end;
$$ language plpgsql;
