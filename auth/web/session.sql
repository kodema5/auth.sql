\if :{?auth_web_session_sql}
\else
\set auth_web_session_sql true

    create function auth.web_sessions(
        jsonb,
        jsonb default null,
        out res jsonb,
        out res_ jsonb
    )
        language plpgsql
        security definer
        set search_path=auth, public
    as $$
    declare
        req jsonb = web_request_t($1, $2, '{
            "is-sys"
        }');
        ret jsonb;
    begin
        ret = jsonb_object_agg(a.session_id, a)
            from auth_.session a;

        select *
        from web_response_t(ret) into $3, $4;
    end;
    $$;


    create function auth.web_session_set(
        jsonb,
        jsonb default null,
        out res jsonb,
        out res_ jsonb
    )
        language sql
        security definer
        set search_path=auth, public
    as $$
        select *
        from web_response_t (
            set (
                session (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }'))))
    $$;


    create function auth.web_session_delete(
        jsonb,
        jsonb default null,
        out res jsonb,
        out res_ jsonb
    )
        language sql
        security definer
        set search_path=auth, public
    as $$
        select *
        from web_response_t (
            delete (
                session (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }')->>'session_id')))
    $$;

\if :{?test}

    create function tests.test_web_session_sql()
        returns setof text
        language plpgsql
        set search_path=auth, public
    as $$
    declare
        head jsonb = web_headers_t_as('test#sys');
        a jsonb;
        id text = head->>'authorization';
    begin
        a = res from web_sessions(null, head);
        return next ok( a ? id, 'has session');

        a = res from web_session_set(
            ('{
                "session_id": "'|| id ||'",
                "data": {"foo":111}
            }')::jsonb, head);
        a = res from web_sessions(null, head);
        return next ok(
            a->id->'data' = '{"foo":111}',
            'can set a session setting/data');

        a = res from web_session_set(
            ('{
                "session_id": "'|| id ||'",
                "data": {"bar":222,"foo":null}
            }')::jsonb, head);
        a = res from web_sessions(null, head);
        return next ok(
            a->id->'data' = '{"bar":222}',
            'can set a session setting/data');

        a = res from web_session_delete(
            ('{
                "session_id": "'|| id ||'"
            }')::jsonb, head);
        a = res from web_sessions(null, web_headers_t_as('test#sys'));
        return next ok(
            not (a ? id),
            'can delete a session');
    end;
    $$;

\endif

\endif