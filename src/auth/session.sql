\if :{?auth_session_sql}
\else
\set auth_session_sql true

create function auth.session (
    user_id_ text
)
    returns text
    language sql
    security definer
as $$
    insert into _auth.session (
        user_id
    ) values (
        user_id_
    )
    returning id;
$$;

create function auth.web_session (
    user_id_ text
)
    returns jsonb
    language sql
    security definer
as $$
    select jsonb_build_object(
        '_headers', jsonb_build_object(
            'authorization', auth.session(user_id_)
        )
    )
$$;


create procedure auth.delete_session_by_user_id(
    user_id_ text
)
    language plpgsql
    security definer
as $$
begin
    delete from _auth.session
    where user_id = user_id_;
end;
$$;


create function auth.who (
    sid_ text
)
    returns text
    language sql
    security definer
as $$
    select user_id
    from _auth.session
    where id = sid_
$$;


\endif