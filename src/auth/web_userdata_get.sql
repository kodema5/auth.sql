create type auth.web_userdata_get_it as (
    _auth auth.auth_t,
    keys text[] -- pass 'prefix.*,prefix.*'
);

create type auth.web_userdata_get_t as (
    userdata jsonb
);

create function auth.web_userdata_get(
    it auth.web_userdata_get_it
)
    returns auth.web_userdata_get_t
    language plpgsql
    security definer
as $$
declare
    a auth.web_userdata_get_t;
begin
    select jsonb_object_agg ( ud.key::text, ud.value )
    into a.userdata
    from auth_.userdata ud,
        ( select unnest (it.keys) ) as keys (k)
    where ud.key ~ (keys.k::lquery)
    and ud.user_id = (it._auth).user_id;

    return a;
end;
$$;


create function auth.web_userdata_get (
    req jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select to_jsonb(auth.web_userdata_get(
        jsonb_populate_record(
            null::auth.web_userdata_get_it,
            auth.auth(req))
    ))
$$;

