------------------------------------------------------------------------------

create function auth.web_signoff(req jsonb) returns jsonb as $$
begin
    req = auth.auth(req);
    call auth.log('web_signoff', req);

    if req->'user_id' is null then
        raise exception 'error.unrecognized_session';
    end if;

    delete from auth.session where id=req->>'authorization';

    return jsonb_build_object();
end;
$$ language plpgsql;
