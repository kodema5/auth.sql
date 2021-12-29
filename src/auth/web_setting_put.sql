create type auth.web_setting_put_it as (
    _auth jsonb,
    setting jsonb
);

create function auth.web_setting_put(req jsonb) returns jsonb as $$
declare
    it auth.web_setting_put_it = jsonb_populate_record(null::auth.web_setting_put_it, auth.auth(req));
    res jsonb;
begin

    with updated as (
        insert into auth_.setting_user (user_id, key, value)
            (
                select it._auth->>'user_id', s.key::ltree, s.value
                from jsonb_each(it.setting) s
                join auth_.setting ss on ss.key = s.key::ltree
            )
        on conflict (user_id, key)
        do update set value = excluded.value
        returning *
    )
    select jsonb_object_agg(u.key, u.value)
    into res
    from updated u;

    delete from auth_.setting_user
    where user_id = it._auth->>'user_id'
    and value is null;

    return jsonb_build_object('setting', res);
end;
$$ language plpgsql;



