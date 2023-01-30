create function session.data (
    sid_ text,
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
        delete from session_.data d
        where d.session_id = sid_
        and d.key = any(delete_);
    end if;

    if not (set_ is null)
    then
        insert into session_.data(session_id, key, value)
            select sid_, a.key, a.value
            from jsonb_each(set_) a
        on conflict (session_id, key)
        do update set
            value = excluded.value;
    end if;

    if not (get_ is null)
    then
        return jsonb_object_agg(d.key, d.value)
            from session_.data d
            where session_id = sid_
            and key = any(get_);
    end if;

    return null;
end;
$$;
