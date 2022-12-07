\if :{?auth_auth_sql}
\else
\set auth_auth_sql true

create type auth.auth_t as (
    session_id text,
    path text,
    user_id text,
    role text
);

create function auth.auth (
    req jsonb,
    sid_ jsonpath default '$._headers.authorization',
    path_ jsonpath default '$._headers.path'
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    a auth.auth_t;
begin
    a.session_id = jsonb_path_query_first(req, sid_)->>0;
    a.path = jsonb_path_query_first(req, path_)->>0;

    select s.user_id, u.role
    into a.user_id, a.role
    from _auth.session s
    left join _auth.user u on u.id = s.user_id
    where s.id = a.session_id;

    if not found then
        return req - '_uid' - '_sid' - '_role';
    end if;

    return req || jsonb_build_object(
        '_auth', a,
        '_role', a.role,
        '_sid', a.session_id,
        '_uid', a.user_id -- most commonly used
    );
end;
$$;

\if :test
    create function tests.test_auth_auth()
        returns setof text
        language plpgsql
    as $$
    declare
        u _auth.user = auth.user('foo@example.com', 'bar');
        a jsonb;
    begin
        a = auth.web_session(u.id);
        a = auth.auth(a);
        return next ok(a->>'_uid' = u.id, 'authorize session');

        a = auth.auth(jsonb_build_object());
        return next ok(a->'_uid' is null, 'handles empty auth');
    end;
    $$;
\endif

\endif
