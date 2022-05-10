-- to signoff
create function auth.signoff (
    jwt text,
    req jsonb default null
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    sid text;
    u _auth.signon;
begin
    sid = jwt.decode(jwt)->>'sid';

    -- coming from web-call
    if req is not null then
        if auth.who(sid, req->>'_origin') is null
        then
            raise exception 'error.unrecognized_session';
        end if;
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
        req->'_headers'->>'authorization',
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
                'authorization', jwt.encode(jsonb_build_object(
                    'sid','test-session-id'
                ))
            ),
            '_origin', 'test'
        ));

        return next ok(true, 'able to sign-off');
    end;
    $$;
\endif
