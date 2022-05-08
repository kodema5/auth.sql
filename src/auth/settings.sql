create function auth.settings (
    setting_id_ text default '*',
    setting_template_id_ lquery default null,
    signon_id_ text default null
)
    returns table (
        id text,
        value jsonb
    )
    language sql
    security definer
    stable
as $$
    select s1.id, coalesce(
        s3.value, -- if user-defined
        s2.value, -- if template defined
        s1.value) -- use default-value
    from (
        select s.*
        from _auth.setting s,
            (select unnest (
                string_to_array(setting_id_, ',')
            )) as keys (k)
        where s.id ~ (keys.k::lquery)
    ) s1
    left outer join lateral (
        -- lateral is used
        select id, value
        from _auth.setting_template
        where setting_id = s1.id -- index from parent
            and id ~ setting_template_id_ -- 'brand.admin{0,1}'
        order by nlevel(id) desc
        limit 1
    ) s2 on (true)
    left outer join _auth.setting_signon s3
        on s3.setting_id = s1.id
        and s3.signon_id = signon_id_
    ;
$$;

-- select * from auth.settings(
--     setting_id_ => 'ui.*',
--     setting_template_id_ => 'brand.admin{0,1}',
--     signon_id_ => 'test-signon-id'
-- );

-- explain analyze
-- select s1.id, coalesce(s3.value, s2.value, s1.value, '123'::jsonb)
-- from (
--     select s.*
--     from _auth.setting s,
--         (select unnest (
--             string_to_array('ui.*', ',')
--         )) as keys (k)
--     where s.id ~ (keys.k::lquery)
-- ) s1
-- left outer join (
--     with
--         setting_ids as (
--             select distinct setting_id
--             from _auth.setting_template t1
--             where id ~ 'brand.admin{0,1}'
--         )
--     select t2.id, t1.setting_id, t2.value
--     from setting_ids t1
--     join lateral (
--         select id, value
--         from _auth.setting_template
--         where setting_id = t1.setting_id
--             and id ~ 'brand.admin{0,1}'
--         order by nlevel(id) desc
--         limit 1
--     ) t2 on (true)
-- ) s2
--     on s2.setting_id = s1.id
-- left outer join _auth.setting_signon s3
--     on s3.setting_id = s1.id
--     and s3.signon_id = (
--         select 'test-signon-id'
--     )
-- ;

-- select s1.id, coalesce(s3.value, s2.value, s1.value)
-- from (
--     select s.*
--     from _auth.setting s,
--         (select unnest (
--             string_to_array('ui.*', ',')
--         )) as keys (k)
--     where s.id ~ (keys.k::lquery)
-- ) s1
-- left outer join lateral (
--     -- lateral is used
--     select id, value
--     from _auth.setting_template
--     where setting_id = s1.id -- index from parent
--         and id ~ 'brand.admin{0,1}'
--     order by nlevel(id) desc
--     limit 1
-- ) s2 on (true)
-- left outer join _auth.setting_signon s3
--     on s3.setting_id = s1.id
--     and s3.signon_id = (
--         select 'test-signon-id'
--     )

-- ;

