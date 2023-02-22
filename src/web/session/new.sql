
drop type if exists web.session_new_it cascade;
create type web.session_new_it as (
    email text
);


create or replace function web.session_new (
    it web.session_new_it
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    sid text = util.get_config('session.session_id');
    s session_.session;
    u user_.user;
begin
    if sid<>'' then
        raise exception 'web.session_new.existing_session_found';
    end if;

    if it.email is null
    then
        raise exception 'web.session_new.empty_user_id';
    end if;

    u = "user".get_by_email(it.email);
    if  u.id is null then
        raise exception 'web.session_new.unrecognized_user_id';
    end if;

    s = session.new(
        user_id_ := u.id,
        is_signed_ := false -- yet authorized
    );

    return jsonb_build_object(
        '_headers', jsonb_build_object(
            'authorization', s.id
        )
    );
end;
$$;

create or replace function web.session_new (
    it jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select web.session_new(jsonb_populate_record(
        null::web.session_new_it,
        session.auth(it)
    ))
$$;



\if :test
    create function tests.test_web_session_new()
        returns setof text
        language plpgsql
    as $$
    declare
        u user_.user = "user".new('foo@example.com','bar');
        req jsonb;
        res jsonb;
    begin
        req = jsonb_build_object('email', 'foo@example.com');
        res = web.session_new(req);
        return next ok(res->'_headers'->>'authorization' is not null, 'able to create session');
        perform session.end();


        return next throws_ok(
            format('select web.session_new(%L::jsonb)',
                session.head(u.id)
                || jsonb_build_object('email', 'foo@example.com')
            ),
            'web.session_new.existing_session_found',
            'disallow new session when valid session'
        );
        perform session.end();
    end;
    $$;
\endif


