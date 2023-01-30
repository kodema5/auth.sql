create function "user".new (
    email_ text,
    pwd_ text,
    role_ text default 'user',
    templates_ text[] default array[]::text[]
)
    returns user_.user
    language plpgsql
    security definer
as $$
declare
    usr user_.user;
    err text;
begin
    insert into user_.user(email, role, templates)
    values (email_, role_, templates_)
    returning * into usr;

    perform "user".set_password(
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
        raise exception 'user.new.unable_to_create_user';
end;
$$;
