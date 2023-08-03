\if :{?auth_web_signon_sql}
\else
\set auth_web_signon_sql true

-- web_signon are for mostly
create type auth.web_signon_t_ as (
    brand_id text,
    name text,
    password text
);

create function auth.web_signon(jsonb)
    returns jsonb
    language plpgsql
    security definer
    strict
    set search_path=auth, public
as $$
declare
    req web_signon_t_ = jsonb_populate_record(
        null::web_signon_t_,
        request_t($1, request_option_t(
            is_session_required => false
        )));

    usr auth_.user = (
        select u
        from auth_.user u
        join auth_.user_ p on p.user_id = u.user_id
        where u.brand_id = req.brand_id
            and u.name = req.name
            and p.password = crypt(req.password, p.password)
    );

    res jsonb;
begin
    if usr is null then
        raise exception 'auth.web_signon.unrecognized_user';
    end if;

    declare
        s auth_.session = session(usr);
        e env_t = env_t(s);
    begin
        update auth_.user
        set last_signon_tz = current_timestamp
        where user_id = usr.user_id;

        res = jsonb_build_object(
            'session_id', s.session_id,
            'user_id', s.user_id,
            'setting', s.setting,
            'data', s.data,
            'current_tz', current_timestamp
        );
    end;

    return response_t(
        res,
        response_option_t(
            is_add_header => true
        ));
end;
$$;


\if :{?test}
    -- \set test_pattern web_signon

    create function tests.test_auth_web_signon_sql() returns setof text language plpgsql
    set search_path=auth, public
    as $$
    declare
        res jsonb;
    begin
        return next throws_ok(
            format(
                'select auth.web_signon(%L::jsonb)',
                '{}'::jsonb),
            'auth.web_signon.unrecognized_user');

        return next throws_ok(
            format(
                'select auth.web_signon(%L::jsonb)',
                '{
                    "brand_id":"test",
                    "name":"user",
                    "password":"wrong-password"
                }'::jsonb),
            'auth.web_signon.unrecognized_user');

        res = web_signon('{
            "brand_id":"test",
            "name":"user",
            "password":"test"
        }');
        return next ok(
            res->'_headers'->>'authorization' is not null,
            'contains authorization header');
    end;
    $$;
\endif



\endif
