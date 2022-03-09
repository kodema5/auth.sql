-- returns user's settings with keys

create type auth.web_setting_get_it as (
    _auth auth.auth_t,
    keys text[]         -- pass 'prefix.*,prefix.*'
);

create type auth.web_setting_get_t as (
    setting jsonb
);

create function auth.web_setting_get (
    it auth.web_setting_get_it
)
    returns auth.web_setting_get_t
    language sql
    security definer
as $$
    select (auth.get_setting(
        it.keys,
        (it._auth).namespace,
        (it._auth).user_id
    ))
$$;


create function auth.web_setting_get (
    req jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select to_jsonb(auth.web_setting_get(
        jsonb_populate_record(
            null::auth.web_setting_get_it,
            auth.auth(req))
    ))
$$;



\if :test
    create function tests.test_auth_web_setting_get()
        returns setof text
        language plpgsql
    as $$
    declare
        sid jsonb = tests.session_as_foo_user();
        a jsonb;
    begin
        a = auth.web_setting_get(sid);
        return next ok(jsonb_typeof(a->'setting') = 'null', 'returns null');

        a = auth.web_setting_get(sid || jsonb_build_object('keys', jsonb_build_array('test.*')));
        return next ok((select cardinality(array_agg(rs)) from jsonb_object_keys(a->'setting') rs) = 3, 'returns settings');

        a = auth.web_setting_get(sid || jsonb_build_object('keys', jsonb_build_array('test.a', 'test.b')));
        return next ok((select cardinality(array_agg(rs)) from jsonb_object_keys(a->'setting') rs) = 2, 'returns specified setting');
    end;
    $$;
\endif


