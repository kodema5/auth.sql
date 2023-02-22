
drop type if exists web.session_sign_it cascade;
create type web.session_sign_it as (
    session_id text,
    password text
);


create or replace function web.session_sign (
    it web.session_sign_it
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    sid text = util.get_config('session.session_id');
    s session_.session = session.get_by_id(sid);
    f boolean;
begin
    if sid='' then
        raise exception 'web.session_sign.session_not_found';
    end if;

    f = "user".sign(
        user_id_ := s.user_id,
        password_ := it.password
    );
    if not f
    then
        raise exception 'web.session_sign.invalid_password';
    end if;

    s = session.sign(
        id_ := sid,
        is_signed_ := true
    );

    return jsonb_build_object(
        '_headers', jsonb_build_object(
            'authorization', s.id
        )
    );
end;
$$;

create or replace function web.session_sign (
    it jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select web.session_sign(jsonb_populate_record(
        null::web.session_sign_it,
        session.auth(it)
    ))
$$;

\if :test
    create function tests.test_web_session_sign()
        returns setof text
        language plpgsql
    as $$
    declare
        u user_.user = "user".new('foo@example.com','bar');
        req jsonb;
        res jsonb;
        sid text;
    begin
        req = jsonb_build_object('email', 'foo@example.com');
        res = web.session_new(req);
        sid = res->'_headers'->>'authorization';
        return next ok(sid is not null, 'able to create session');

        req = res || jsonb_build_object('password', 'bar');
        res = web.session_sign(req);
        return next ok(res->'_headers'->>'authorization' is not null, 'able to sign session');
        return next ok(res->'_headers'->>'authorization' <> sid, 'a new session will be created');

        perform session.end();


    end;
    $$;
\endif



