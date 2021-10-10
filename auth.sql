------------------------------------------------------------------------------

create function auth.auth(req jsonb) returns jsonb as $$
declare
    sid_ text = req->>'session_id';
    ns_ text;
    id_ text;
    name_ text;
    role_ auth.signon_role_t;
begin
    select u.id, u.role, u.name, u.namespace
    into id_, role_, name_, ns_
        from auth.session s
        join auth.signon u on u.id = s.signon_id
        where s.id=sid_;

    ns_ = coalesce(ns_, req->>'namespace');
    if ns_ is null and not exists(select 1 from auth.namespace where id=ns_) then
        call auth.log('error.unrecognized_namespace', req);
        raise exception 'error.unrecognized_namespace';
    end if;

    req = req || jsonb_build_object(
        'namespace', ns_,
        'signon_id', id_,
        'signon_name', name_,
        'is_user', (role_ = 'user'::auth.signon_role_t),
        'is_admin', (role_ = 'admin'::auth.signon_role_t)
    );

    call auth.log('authorizing ' || sid_, req);

    return req;
end;
$$ language plpgsql;