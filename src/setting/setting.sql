
create function setting.setting (
    set_ setting_.setting[] default null,
    get_ text[] default null,
    delete_ text[] default null
)
    returns setting_.setting[]
    language plpgsql
    security definer
as $$
begin
    if not (delete_ is null)
    then
        delete from setting_.setting
        where id = any(delete_);
    end if;

    if not (set_ is null)
    then
        insert into setting_.setting (id, description, value)
            select a.id, a.description, a.value
            from unnest(set_) a
        on conflict (id)
        do update set
            description = excluded.description,
            value = excluded.value;
    end if;

    if not (get_ is null)
    then
        return array_agg(s)
        from setting_.setting s
        where id = any(get_);
    end if;

    return null;
end;
$$;