create type auth.web_signon_it as (
    namespace text,
    signon_id text,
    signon_key text,
    setting text
);

create function auth.web_signon(req jsonb) returns jsonb as $$
declare
    it auth.web_signon_it = jsonb_populate_record(null::auth.web_signon_it, req);
    u auth_.user;
begin
    select * into u
    from auth_.user t
    where t.ns_id = it.namespace
        and t.signon_id = it.signon_id
        and t.signon_key = crypt(it.signon_key, t.signon_key);
    if u is null then
        raise exception 'error.unrecognized_signon';
    end if;

    return to_jsonb(auth.new_session(
        u.id,
        coalesce(it.setting, 'ui.*')
    ));
end;
$$ language plpgsql;