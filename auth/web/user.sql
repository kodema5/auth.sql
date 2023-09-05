\if :{?auth_web_user_sql}
\else
\set auth_web_user_sql true

    create function auth.web_users(
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
        ret = jsonb_object_agg(a.user_id, a)
            from auth_.user a;

        select *
        from web_response_t(ret) into $3, $4;
    end;
    $$;


    create function auth.web_user_set(
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
        usr auth_.user;
        usr_ auth_.user_;
    begin
        usr = set(auth.user(req));
        usr_ = auth.user_(req);
        usr_.user_id = usr.user_id;
        perform set(usr_);

        select *
        from web_response_t(usr) into $3, $4;
    end;
    $$;


    create function auth.web_user_delete(
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
                auth.user (
                    web_request_t($1, $2, '{
                        "is-sys"
                    }')->>'user_id')))
    $$;


\if :{?test}

    create function tests.test_auth_web_user_sql()
        returns setof text
        language plpgsql
        set search_path=auth, public
    as $$
    declare
        head jsonb = web_headers_t_as('test#sys');
        a jsonb;
        usr auth_.user;
        id text;
    begin
        a = res from web_user_set(
            '{
                "brand_id": "test",
                "name":"foo",
                "password":"bar",
                "email":"foo@test.com"
            }', head);
        id = a->>'user_id';
        a = res from web_users(null, head);
        return next ok( a ? 'test#foo', 'can create user');


        usr = auth.user('test', 'foo', 'bar');
        return next ok(not (usr is null), 'can login with user');

        a = res from web_user_set(
            ('{
                "user_id": "' || id || '",
                "password":"baz"
            }')::jsonb, head);
        usr = auth.user('test', 'foo', 'baz');
        return next ok(not (usr is null), 'can change password');


        a = res from web_user_delete(
            ('{
                "user_id": "' || id || '"
            }')::jsonb, head);
        a = res from web_users(null, head);
        return next ok( not (a ? 'test#foo'), 'can delete user');
    end;
    $$;

\endif

\endif