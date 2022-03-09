create function auth.get_user_id(
    namespace text,
    signon_id_ text
)
    returns text
    language sql
    security definer
    stable
as $$
    select id
    from auth_.user
    where ns_id = namespace
    and signon_id = signon_id_
$$;