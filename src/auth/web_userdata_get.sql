create type auth.web_userdata_get_it as (
    _auth auth.auth_t,
    keys text[] -- pass 'prefix.*,prefix.*'
);

create function auth.web_userdata_get(req jsonb) returns jsonb as $$
declare
    it auth.web_userdata_get_it = jsonb_populate_record(null::auth.web_userdata_get_it, auth.auth(req));
begin
    return jsonb_build_object('userdata', (
        select jsonb_object_agg ( ud.key::text, ud.value )
        from auth_.userdata ud,
            ( select unnest (it.keys) ) as keys (k)
        where ud.key ~ (keys.k::lquery)
        and ud.user_id = (it._auth).user_id
    ));
end;
$$ language plpgsql;
