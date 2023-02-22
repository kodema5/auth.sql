create function "user".sign (
    user_id_ text,
    password_ text
)
    returns boolean
    language sql
    security definer
as $$
    select exists(
        select
        from user_.password p
        where p.user_id = user_id_
        and p.password = crypt(password_, p.password)
    )
$$;

