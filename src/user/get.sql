create function "user".get (
    email_ text,
    password_ text
)
    returns user_.user
    language sql
    security definer
as $$
    select u.*
    from user_.user u
    join user_.password p on p.user_id = u.id
    where u.email = email_
        and p.password = crypt(password_, p.password);
$$;

create function "user".get_by_id (
    id_ text
)
    returns user_.user
    language sql
    security definer
as $$
    select u.*
    from user_.user u
    where u.id = id_
$$;

create function "user".get_by_email (
    email_ text
)
    returns user_.user
    language sql
    security definer
as $$
    select u.*
    from user_.user u
    where u.email = email_
$$;