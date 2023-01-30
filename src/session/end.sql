create function session.end (
    id_ text default util.get_config('session.session_id')
)
    returns text
    language plpgsql
    security definer
as $$
begin
    if not exists (
        select from session_.session
        where id=id_
    )
    then
        return null;
    end if;

    delete
    from session_.session
    where id = id_;

    perform util.set_config('session.session_id', '');
    perform util.set_config('session.user_id', '');
    perform util.set_config('session.user_role', '');

    return id_;
end;
$$;

