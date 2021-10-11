------------------------------------------------------------------------------
-- get setting

create function auth.setting_get (
    setting_keys_ text default 'ui.*',
    namespace_id_ text default null,
    user_id_ text default null
) returns jsonb
as $$
    select jsonb_object_agg(ds.key, coalesce(ss.value, ns.value, ds.value))
    from (
        select s.*
        from auth.setting s,
            (select unnest (string_to_array(setting_keys_, ','))) as keys (k)
        where s.key ~ (keys.k::lquery)
        order by s.key
    ) ds (key, value)
    left outer join auth.setting_namespace ns
        on ns.namespace=namespace_id_
        and ns.key=ds.key
    left outer join auth.setting_user ss
        on ss.user_id=(
            select id from auth.user
            where namespace=namespace_id_ and id=user_id_)
        and ss.key=ds.key;
$$ language sql stable;
