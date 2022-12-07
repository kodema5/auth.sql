\if :{?auth_user_sql}
\else
\set auth_user_sql true


\ir password.sql

create function auth.user (
    email_ text,
    pwd_ text,
    role_ text default 'user'
)
    returns _auth.user
    language plpgsql
    security definer
as $$
declare
    usr _auth.user;
    err text;
begin
    insert into _auth.user(email, role)
    values (email_, role_)
    returning * into usr;

    perform auth.password(
        usr.id,
        pwd_
    );

    return usr;
exception
    when check_violation
    or unique_violation
    then
        get stacked diagnostics err = constraint_name;
        raise exception '%', err;
    when others then
        raise exception 'auth.user.unable_to_create_user';
end;
$$;


create function auth.user_by_email (
    email_ text
)
    returns _auth.user
    language sql
    security definer
as $$
    select *
    from _auth.user
    where email = email_
$$;

create function auth.user_by_id (
    id_ text
)
    returns _auth.user
    language sql
    security definer
as $$
    select *
    from _auth.user
    where id = id_
$$;
\endif
