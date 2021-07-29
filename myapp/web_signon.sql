------------------------------------------------------------------------------
-- signon

create function myapp.web_signon(
    req jsonb,
    _ text default myapp.__env__()
) returns jsonb as $$
declare
    usr text;
    sid text;
begin
    usr = auth.authenticate_signon(
        req->>'name',
        req->>'pwd',
        auth.get_ns('myapp')
    );

    sid = auth.new_session(
        usr,
        jsonb_build_object(
            'usr', usr
        )
    );

    return jsonb_build_object(
        'sid', sid
    );
end;
$$ language plpgsql security definer;


------------------------------------------------------------------------------
-- signon

\if :test

create function tests.startup_myapp() returns void as $$
begin
    perform myapp.__init__();
end;
$$ language plpgsql;


create function tests.test_myapp_signon () returns setof text as $$
declare
    a jsonb;
begin
    a = myapp.web_signon(jsonb_build_object('name', 'test','pwd', '--test--'));
    return next ok(a is not null and a->>'sid' is not null, 'able to signed on');

    return next throws_ok('select myapp.web_signon(jsonb_build_object('
        '''name'',''test'',''pwd'',''xxxx'''
        '))'
    , 'error.unrecognized_signon');
    return next throws_ok('select myapp.web_signon(null)', 'error.unrecognized_signon');

end;
$$ language plpgsql;

\endif