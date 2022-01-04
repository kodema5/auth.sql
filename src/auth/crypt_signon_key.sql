create function auth.crypt_signon_key (key text) returns text as $$
begin
    if key is null or length(key)<8 then
        return null;
    end if;

    return crypt(key, gen_salt('bf', 8));
end;
$$ language plpgsql;
