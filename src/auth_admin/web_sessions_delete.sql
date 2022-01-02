
create type auth_admin.web_sessions_delete_it as (
    _auth jsonb,
    session_ids text[],
    user_ids text[]
);

create function auth_admin.web_sessions_delete(req jsonb) returns jsonb as $$
declare
    it auth_admin.web_sessions_delete_it = jsonb_populate_record(null::auth_admin.web_sessions_delete_it, auth_admin.auth(req));
    n int = 0;
    i int;
begin
    if it.session_ids is not null then
        with deleted as (
            delete from auth_.session
            where id = any(it.session_ids)
            returning *
        )
        select (n + count(1)) into n from deleted;
    end if;

    if it.user_ids is not null then
        with deleted as (
            delete from auth_.session
            where user_id = any(it.user_ids)
            returning *
        )
        select (n + count(1)) into n from deleted;
    end if;

    return jsonb_build_object('deleted', n);
end;
$$ language plpgsql;
