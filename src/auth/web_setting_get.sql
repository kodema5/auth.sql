create type auth.web_setting_get_it as (
    _auth jsonb,
    setting_key text -- pass 'prefix.*,prefix.*'
);

create function auth.web_setting_get(req jsonb) returns jsonb as $$
declare
    it auth.web_setting_get_it = jsonb_populate_record(null::auth.web_setting_get_it, auth.auth(req));
begin
    return jsonb_build_object('setting', auth.get_setting(
        coalesce(it.setting_key, '*'),
        it._auth->>'namespace',
        it._auth->>'user_id'
    ));
end;
$$ language plpgsql;
