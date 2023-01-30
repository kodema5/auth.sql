create type setting.get_t as (
    key text,
    value jsonb
);

create function setting.get(
    setting_ids text[],
    template_ids text[],
    user_id text
)
    returns setof setting.get_t
    language sql
    security definer
as $$
    select (
        s1.id,
        coalesce(
            s3.value, -- user override
            s2.value, -- last template
            s1.value  -- default
        )
    )::setting.get_t
    from (
        select s.*
        from setting_.setting s
        where setting_ids is null
        or s.id = any(setting_ids)
    ) s1
    left outer join (
        select setting_id, value
        from setting_.template t
        where
            (setting_ids is null or setting_id = any(setting_ids))
            and t.template_id = any(template_ids)
        order by array_position(template_ids, template_id) desc
        limit 1
    ) s2
        on s2.setting_id = s1.id
    left outer join setting_.user s3
        on s3.setting_id = s1.id
        and s3.user_id = user_id
$$;