-- consider:
-- - check if user is not locked?
--
create function session.new (
    user_id_ text
)
    returns session_.session
    language sql
    security definer
as $$
    insert into session_.session (
        user_id
    ) values (
        user_id_
    )
    returning *;
$$;

-- in the form of authorization header
--
create function session.head (
    user_id_ text
)
    returns jsonb
    language sql
    security definer
as $$
    select jsonb_build_object(
        '_headers', jsonb_build_object(
            'authorization',
            (session.new(user_id_)).id
        )
    );
$$;