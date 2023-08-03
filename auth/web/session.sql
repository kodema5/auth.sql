\if :{?auth_web_session_sql}
\else
\set auth_web_session_sql true

    create function auth.web_sessions(jsonb)
        returns jsonb
        language plpgsql
        security definer
        strict
        set search_path=auth, public
    as $$
    declare
        req jsonb = request_t($1, '{
            "is-sys"
        }'::text[]);
        res jsonb;
    begin
        res = jsonb_object_agg(a.session_id, a)
            from auth_.session a;

        return response_t(res);
    end;
    $$;


    create function auth.web_session_set(jsonb)
        returns jsonb
        language plpgsql
        security definer
        strict
        set search_path=auth, public
    as $$
    declare
        req jsonb = request_t($1, '{
            "is-sys"
        }'::text[]);
        ses auth_.session = session(req);
    begin
        return response_t(set(ses));
    end;
    $$;


    create function auth.web_session_delete(jsonb)
        returns jsonb
        language plpgsql
        security definer
        strict
        set search_path=auth, public
    as $$
    declare
        req jsonb = request_t($1, '{
            "is-sys"
        }'::text[]);
    begin
        return response_t(delete(session(req->>'session_id')));
    end;
    $$;

\if :{?test}

    create function tests.test_web_session_sql() returns setof text language plpgsql
    set search_path=auth, public
    as $$
    declare
        head jsonb = header_t_as('test::sys');
        res jsonb;
        id text;
    begin

        res = web_sessions(head);
        id = res->'_headers'->>'authorization';
        return next ok( id is not null, 'has sessions');

        res = web_session_set(
            head ||
            ('{
                "session_id": "'|| id ||'",
                "data": {"foo":111}
            }')::jsonb);
        res = web_sessions(head);
        return next ok(res->id->'data' = '{"foo":111}', 'can set a session setting/data');

        res = web_session_set(
            head ||
            ('{
                "session_id": "'|| id ||'",
                "data": {"bar":222,"foo":null}
            }')::jsonb);
        res = web_sessions(head);
        return next ok(res->id->'data' = '{"bar":222}', 'can set a session setting/data');

        res = web_session_delete(
            auth.header_t_as('test::sys') ||
            ('{
                "session_id": "'|| id ||'"
            }')::jsonb);
        res = web_sessions(header_t_as('test::sys'));

        return next ok(not (res ? id), 'can delete a session');



        -- res = web_app_set(
        --     auth.header_t_as('test::sys') ||
        --     '{
        --         "app_id": "test2",
        --         "name": "test2"
        --     }');
        -- -- call auth.debug(res);

        -- res = web_apps(header_t_as('test::sys'));
        -- return next ok(res ? 'test2', 'can create an app');

        -- res = web_app_delete(
        --     auth.header_t_as('test::sys') ||
        --     '{
        --         "app_id": "test2"
        --     }');

        -- res = web_apps(header_t_as('test::sys'));
        -- return next ok(not (res ? 'test2'), 'can delete an app');
    end;
    $$;

\endif

\endif