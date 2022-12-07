\if :{?auth_config_config_template_sql}
\else
\set auth_web_config_config_template_sql true

create function auth.config_template (
    it auth.config_data_it
)
    returns auth.config_data_t
    language plpgsql
    security definer
as $$
declare
    t auth.config_data_t;
begin
    if not (it.remove is null)
    then
        with
        deleted as (
            delete from _auth.config_template c
            using (
                select id, name
                from unnest(it.remove)
            ) a
            where c.id = a.id
            and c.name = a.name
            returning c.id, c.name
        )
        select array_agg(
            (id, name)::auth.config_id_t
        )
        into t.remove
        from deleted;
    end if;

    if not (it.set is null)
    then
        with
        inserted as (
            insert into _auth.config_template
            (id, name, value)
                select a.id, a.name, a.value
                from unnest(it.set) a
            on conflict (id, name)
            do update set
                value = excluded.value
            returning id, name
        )
        select array_agg(
            (id, name)::auth.config_id_t
        )
        into t.set
        from inserted;
    end if;

    if not (it.get is null)
    then
        select array_agg(
            (c.id, c.name, c.value)::auth.config_item_t
        )
        into t.get
        from (
            select distinct id, name
            from unnest(it.get)
        ) a
        left join _auth.config_template c
        on c.id = a.id
        and c.name = a.name;
    end if;

    return t;
end;
$$;


\endif