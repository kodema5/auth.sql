create type auth.setting_t as (
    key text,
    value text
);

create function auth.get_setting (
    setting_keys_ text default 'ui.*',
    ns_id_ text default null,
    user_id_ text default null
)
returns auth.setting_t[]
as $$

    select array_agg((ds.key, coalesce(ss.value, ns.value, ds.value))::auth.setting_t)

    from (
        select s.*
        from auth_.setting s,
            ( select unnest (string_to_array(setting_keys_, ',')) ) as keys (k)
        where s.key ~ (keys.k::lquery)
        order by s.key
    ) ds (key, value)

    left outer join auth_.setting_namespace ns
        on ns.ns_id = ns_id_ and ns.key = ds.key

    left outer join auth_.setting_user ss
        on ss.user_id=(
            select id from auth_.user where ns_id = ns_id_ and id = user_id_
        )
        and ss.key=ds.key;

$$ language sql stable;