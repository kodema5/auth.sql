create type auth_admin.web_settings_put_it as (
    _auth jsonb,
    setting jsonb -- new/update: { key: {[key:new_key], [value:new_value], [description:new_description] }}
                  -- delete    : { key: null }
);

create function auth_admin.web_settings_put(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_settings_put_it = jsonb_populate_record(null::auth_admin.web_settings_put_it, auth_admin.auth(req));
    r record;
    s auth_.setting;
    v auth_.setting;
begin
   for r in
        select rs.key, rs.value
        from jsonb_each(it.setting) rs
    loop
        if jsonb_typeof(r.value) = 'null' then
            delete from auth_.setting where key = r.key::ltree;
            continue;
        end if;

        v = jsonb_populate_record(null::auth_.setting, r.value);

        select * into s from auth_.setting where key = r.key::ltree;
        if not found then
            insert into auth_.setting (key, value, description)
            values (
                r.key::ltree,
                coalesce(v.value, s.value),
                coalesce(v.description, s.description)
            );
            continue;
        else
            update auth_.setting set
                value = coalesce(v.value, s.value),
                description = coalesce(v.description, s.description)
            where key = r.key::ltree;
            continue;
        end if;
    end loop;


    return (select jsonb_build_object('setting', jsonb_object_agg( ss.key, to_jsonb(ss)))
    from auth_.setting ss);

end;
$$ language plpgsql;
