create function "user".set_password(
    uid text,
    pwd text
)
    returns user_.password
    language sql
    security definer
as $$
    insert into user_.password(
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
