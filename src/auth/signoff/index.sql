-- to signoff
create function auth.signoff (
    req jsonb
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    sid text;
    u _auth.signon;
    a jsonb;
begin
    a = jwt.auth(req);
    sid = a->'_auth'->>'sid';
    if sid is null then
        raise exception 'error.unrecognized_session';
    end if;

    update _auth.session
        set signed_off_tz = now()
        where id = sid;
    return null;

    return jsonb_build_object(
        'success', true
    );
end;
$$;

create function auth.web_signoff (
    req jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select to_jsonb(auth.signoff(
        req
    ))
$$;


\if :test
    create function tests.test_auth_signoff() returns setof text language plpgsql as $$
    declare
        req jsonb;
        res jsonb;
    begin
        res = auth.web_signoff(jsonb_build_object(
            '_headers', jsonb_build_object(
                'authorization', 'Bearer ' || jwt.encode(jsonb_build_object(
                    'sid','test-session-id'
                ))
            ),
            '_origin', 'test'
        ));

        return next ok(true, 'able to sign-off');
    end;
    $$;
\endif
