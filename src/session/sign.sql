create function session.sign (
    id_ text,
    is_signed_ boolean default true
)
    returns session_.session
    language sql
    security definer
as $$
    update session_.session
    set
        id = md5(gen_random_uuid()::text),
        is_signed = is_signed_
    where id = id_
    returning *;
$$;
