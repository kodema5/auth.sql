create function session.get_by_id (
    id_ text
)
    returns session_.session
    language sql
    security definer
as $$
    select s.*
    from session_.session s
    where s.id = id_
$$;
