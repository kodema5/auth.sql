create type auth.setting_t as (
    key text,
    value text
);

create function auth.get_setting (
    keys_ text[],
    ns_id_ text default null,
    user_id text default null
)
    returns jsonb
    language sql
    security definer
    stable
as $$
    select jsonb_object_agg(
        ds.key,
        coalesce(ss.value, ns.value, ds.value)
    )
    from (
        select s.*
        from auth_.setting s,
            ( select unnest (keys_) ) as keys (k)
        where s.key ~ (keys.k::lquery)
        order by s.key
    ) ds (key, value)

    left outer join auth_.setting_namespace ns
        on ns.ns_id = ns_id_ and ns.key = ds.key

    left outer join auth_.setting_user ss
        on ss.user_id=(
            select id from auth_.user where ns_id = ns_id_ and id = user_id
        )
        and ss.key=ds.key;

$$;

create function auth.get_setting (
    keys_ text default 'ui.*',
    ns_id_ text default null,
    user_id text default null
)
    returns jsonb
    language sql
    security definer
    stable
as $$
    select auth.get_setting(string_to_array(keys_, ','), ns_id_, user_id)
$$;