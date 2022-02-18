create type auth.web_change_password_it as (
    _auth jsonb,
    old_signon_key text,
    new_signon_key text,
    new_signon_key_confirm text
);

create type auth.web_change_password_t as (
    success boolean
);

create function auth.web_change_password (
    it auth.web_change_password_it
)
returns auth.web_change_password_t
as $$
declare
    a auth.web_change_password_t;
begin
    if it.old_signon_key is null
        or it.new_signon_key is null
        or it.new_signon_key <> it.new_signon_key_confirm
        or it.new_signon_key = it.old_signon_key
    then
        raise exception 'error.missing_parameter';
    end if;

    if not exists (
        select 1
        from auth_.user
        where id = it._auth->>'user_id'
        and signon_key = crypt(it.old_signon_key, signon_key)
    ) then
        raise exception 'error.invalid_existing_key';
    end if;

    update auth_.user
    set signon_key = crypt(it.new_signon_key, gen_salt('bf', 8))
    where id = it._auth->>'user_id';

    a.success = true;
    return a;
end;
$$ language plpgsql;


create function auth.web_change_password (req jsonb)
returns jsonb as $$
    select to_jsonb(auth.web_change_password(
        jsonb_populate_record(
            null::auth.web_change_password_it,
            auth.auth(req))
    ))
$$ language sql stable;


\if :test
    create function tests.test_auth_web_change_password() returns setof text as $$
    declare
        sid jsonb = tests.session_as_foo_user();
        res jsonb;
    begin
        res = auth.web_change_password(sid || jsonb_build_object(
            'old_signon_key', 'foo.password',
            'new_signon_key', 'foo.password2',
            'new_signon_key_confirm', 'foo.password2'
        ));
        return next ok((res->'success')::boolean = true, 'able to change password');
    end;
    $$ language plpgsql;
\endif