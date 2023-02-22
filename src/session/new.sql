-- consider:
-- - check if user is not locked?
--
create function session.new (
    user_id_ text,
    is_signed_ boolean default true
)
    returns session_.session
    language sql
    security definer
as $$
    insert into session_.session (
        user_id, is_signed
    ) values (
        user_id_, is_signed_
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