create type auth.new_session_t as (
    session_id text,
    signon_id text,
    setting jsonb
);

create function auth.new_session (
    user_id text,
    setting text default null
)
returns auth.new_session_t
as $$
declare
    res jsonb = '{}'::jsonb;
    u auth_.user;
    s auth_.session;
    a auth.new_session_t;
begin
    select * into u from auth_.user where id = user_id limit 1;
    if not found then
        raise exception 'error.invalid_user';
    end if;

    insert into auth_.session (user_id) values (u.id) returning * into s;

    a.session_id = s.id;
    a.signon_id = u.signon_id;
    a.setting = auth.get_setting(
        setting,
        u.ns_id,
        u.id
    );

    return a;
end;
$$ language plpgsql;