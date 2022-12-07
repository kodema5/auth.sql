\if :{?auth_password_sql}
\else
\set auth_password_sql true

create function auth.password(
    uid text,
    pwd text
)
    returns _auth.password
    language sql
    security definer
as $$
    insert into _auth.password(
        user_id,
        password
    ) values (
        uid,
        crypt(pwd, gen_salt('bf'))
    )
    on conflict (user_id)
    do update set
        password = crypt(pwd, gen_salt('bf'))
    returning *
$$;

\endif
