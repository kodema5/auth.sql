-- check if valid session
-- returns basic user's info
--
create type session.auth_t as (
    session_id text,
    path text,
    user_id text,
    role text,
    is_signed boolean
);

create function session.auth (
    req jsonb,
    sid_ jsonpath default '$._headers.authorization',
    path_ jsonpath default '$._headers.path'
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    a session.auth_t;
begin
    a.session_id = jsonb_path_query_first(req, sid_)->>0;
    a.path = jsonb_path_query_first(req, path_)->>0;

    select s.user_id, u.role, s.is_signed
        into a.user_id, a.role, a.is_signed
        from session_.session s
        left join user_.user u on u.id = s.user_id
        where s.id = a.session_id;

    if not found then
        perform util.set_config('session.session_id', '');
        perform util.set_config('session.user_id', '');
        perform util.set_config('session.user_role', '');

        return req - '_uid' - '_sid' - '_role' - '_auth';
    end if;

    update session_.session s
        set last_auth_tz = current_timestamp
        where s.id = a.session_id;

    perform util.set_config('session.session_id', a.session_id);

    if not a.is_signed then
        a.user_id = '';
        a.role = '';
    end if;
    perform util.set_config('session.user_id', a.user_id);
    perform util.set_config('session.user_role', a.role);

    return req || jsonb_build_object(
        '_auth', a,
        '_role', a.role,
        '_sid', a.session_id,
        '_uid', a.user_id
    );
end;
$$;

