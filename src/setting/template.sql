create function setting.template (
    set_ setting_.template[] default null,
    get_ text[] default null,
    delete_ text[] default null
)
    returns setting_.template[]
    language plpgsql
    security definer
as $$
begin
    if not (delete_ is null)
    then
        delete from setting_.template
        where id = any(delete_);
    end if;

    if not (set_ is null)
    then
        insert into setting_.template (setting_id, template_id, value)
            select a.setting_id, a.template_id, a.value
            from unnest(set_) a
        on conflict (setting_id, template_id)
        do update set
            value = excluded.value;
    end if;

    if not (get_ is null)
    then
        return array_agg(s)
        from setting_.template s
        where template_id = any(get_);
    end if;

    return null;
end;
$$;
