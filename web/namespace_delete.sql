---------------------------------------------------------------------------

create function auth.namespace_delete(req jsonb)
returns auth.namespace
as $$
declare
    id_ text = req->>'id';
    is_admin boolean = req->'is_admin';
    ns auth.namespace;
begin
    if not is_admin then
        raise exception 'error.administrator_required';
    end if;

    delete from auth.namespace where id=id_
    returning * into ns;

    return ns;
end;
$$ language plpgsql;

---------------------------------------------------------------------------

create function auth.web_namespace_delete (req jsonb)
returns jsonb
as $$
begin
    return to_jsonb(auth.namespace_delete(auth.auth(req)));
end;
$$ language plpgsql security definer;

