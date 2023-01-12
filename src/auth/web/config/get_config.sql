\if :{?auth_web_config_get_sql}
\else
\set auth_web_config_get_sql true


create function auth.get_config (
    it auth.config_get_it
)
    returns table (
        id text,
        value jsonb,
        description text
    )
    language sql
    security definer
as $$
    select s1.id,
    coalesce(
        s3.value, -- user override
        s2.value, -- last template
        s1.value  -- default
    ),
    s1.name -- description
    from (
        select s.*
        from _auth.config s
        where it.ids is null or s.id = any(it.ids)
    ) s1
    left outer join (
        select id, value
        from _auth.config_template t
        where
            (it.ids is null or id = any(it.ids))
            and t.name = any(it.templates)
        order by array_position(it.templates, t.name) desc
        limit 1
    ) s2
        on s2.id = s1.id
    left outer join _auth.config_user s3
        on s3.id = s1.id
        and s3.name = it.user_id
$$;


\endif
