create function "user".data (
    uid_ text,
    set_ jsonb default null,
    get_ text[] default null,
    delete_ text[] default null
)
    returns jsonb
    language plpgsql
    security definer
as $$
begin
    if not (delete_ is null)
    then
        delete from user_.data d
        where d.user_id = uid_
        and d.key = any(delete_);
    end if;

    if not (set_ is null)
    then
        insert into user_.data(user_id, key, value)
            select uid_, a.key, a.value
            from jsonb_each(set_) a
        on conflict (user_id, key)
        do update set
            value = excluded.value;
    end if;

    if not (get_ is null)
    then
        return jsonb_object_agg(d.key, d.value)
            from user_.data d
            where user_id = uid_
            and key = any(get_);
    end if;

    return null;
end;
$$;
