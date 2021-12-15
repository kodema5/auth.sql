create type auth.web_register_it as (
    namespace text,
    signon_id text,
    signon_key text,
    signon_key_confirm text,
    _auth jsonb
);

create function auth.web_register(req jsonb) returns jsonb as $$
declare
    it auth.web_register_it = jsonb_populate_record(null::auth.web_register_it, req);
    u auth_.user;
begin
    if it.signon_id is null or length(it.signon_id)<8 then
        raise exception 'error.invalid_signon_id';
    end if;

    if it.signon_key is null or length(it.signon_key)<8 then
        raise exception 'error.invalid_signon_key';
    end if;

    if it.signon_key <> it.signon_key_confirm then
        raise exception 'error.invalid_signon_key_confirmation';
    end if;

    insert into auth_.user (ns_id, signon_id, signon_key)
        values (
            it.namespace,
            it.signon_id,
            crypt(it.signon_key, gen_salt('bf', 8))
        )
        returning * into u;

    return to_jsonb(auth.new_session(u.id));

end;
$$ language plpgsql;