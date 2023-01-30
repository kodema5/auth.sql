drop type if exists web.user_signoff_it cascade;
create type web.user_signoff_it as (
    _uid text,
    _sid text
);

create or replace function web.user_signoff (
    it web.user_signoff_it
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    sid text = util.get_config('session.session_id');
begin
    if  sid = ''
    then
        raise exception 'web.user_signoff.no_session_found';
    end if;

    perform session.end(sid);

    return jsonb_build_object(
        '_headers', jsonb_build_object(
            'authorization', null
        ),
        'success', true
    );
end;
$$;

create or replace function web.user_signoff (
    it jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select web.user_signoff(jsonb_populate_record(
        null::web.user_signoff_it,
        session.auth(it)
    ))
$$;


\if :test
    create function tests.test_web_user_signoff()
        returns setof text
        language plpgsql
    as $$
    declare
        u user_.user = "user".new('foo@example.com','bar');
        res jsonb;
    begin
        res = web.user_signon(jsonb_build_object(
            'email', 'foo@example.com',
            'password', 'bar'
        ));

        res = web.user_signoff(res);
        return next ok(res->'_headers'->>'authorization' is null,
            'allow signoff of valid session');

        return next ok(util.get_config('session.session_id')='',
            'local setting is reset');

        return next throws_ok(
            format('select web.user_signoff(%L::jsonb)',
                '{}'
            ),
            'web.user_signoff.no_session_found',
            'disallow signoff of invalid session'
        );

    end;
    $$;
\endif