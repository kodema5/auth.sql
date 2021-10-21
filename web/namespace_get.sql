---------------------------------------------------------------------------

create function auth.namespace_get(req jsonb default null)
returns setof auth.namespace
as $$
    select * from auth.namespace;
$$ language sql;

---------------------------------------------------------------------------

create function auth.web_namespace_get (req jsonb)
returns jsonb
as $$
declare
    res jsonb;
begin
    select jsonb_agg(to_jsonb(d.*))
    into res
    from auth.web_namespace_get(auth.auth(req)) d;

    return res;
end;
$$ language plpgsql security definer;


