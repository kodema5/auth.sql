create type auth.web_change_password_it as (
    _auth jsonb,
    old_signon_key text,
    new_signon_key text,
    new_signon_key_confirm text
);

create function auth.web_change_password (req jsonb) returns jsonb as $$
declare
    it auth.web_change_password_it = jsonb_populate_record(null::auth.web_change_password_it, auth.auth(req));
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

    return jsonb_build_object('success', true);
end;
$$ language plpgsql;

