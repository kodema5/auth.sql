create function setting.user (
    uid_ text,
    set_ jsonb default null,
    get_ text[] default null,
    delete_ text[] default null
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
begin
    if not (delete_ is null)
    then
        delete from setting_.user
        where user_id = uid_
        and setting_id = any(delete_);
    end if;

    if not (set_ is null)
    then
        insert into setting_.user(user_id, setting_id, value)
            select uid_, a.key, a.value
            from jsonb_each(set_) a
        on conflict (user_id, setting_id)
        do update set
            value = excluded.value;
    end if;

    if not (get_ is null)
    then
        return jsonb_object_agg(d.setting_id, d.value)
            from setting_.user d
            where user_id = uid_
            and setting_id = any(get_);
    end if;

    return null;
end;
$$;