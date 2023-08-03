\if :{?auth_web_user_sql}
\else
\set auth_web_user_sql true

    create function auth.web_users(jsonb)
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
        res = jsonb_object_agg(a.user_id, a)
            from auth_.user a;

        return response_t(res);
    end;
    $$;

    create function auth.web_user_set(jsonb)
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
        usr auth_.user;
        usr_ auth_.user_;
    begin
        usr = set(auth.user(req));
        usr_ = auth.user_(req);
        usr_.user_id = usr.user_id;
        perform set(usr_);
        return response_t(usr);
    end;
    $$;

    create function auth.web_user_delete(jsonb)
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
        return response_t(delete(auth.user(req->>'user_id')));
    end;
    $$;

\if :{?test}

    create function tests.test_auth_web_user_sql() returns setof text language plpgsql
    set search_path=auth, public
    as $$
    declare
        res jsonb;
        usr auth_.user;
        id text;
    begin
        res = web_user_set(header_t_as('test::sys') || '{
            "brand_id": "test",
            "name":"foo",
            "password":"bar",
            "email":"foo@test.com"
        }');
        id = res->>'user_id';

        res = web_users(header_t_as('test::sys'));
        return next ok( res ? 'test::foo', 'can create user');

        usr = auth.user('test', 'foo', 'bar');
        return next ok(not (usr is null), 'can login with user');

        res = web_user_set(header_t_as('test::sys') || ('{
            "user_id": "' || id || '",
            "password":"baz"
        }')::jsonb);
        usr = auth.user('test', 'foo', 'baz');
        return next ok(not (usr is null), 'can change password');


        res = web_user_delete(header_t_as('test::sys') || ('{
            "user_id": "' || id || '"
        }')::jsonb);
        res = web_users(header_t_as('test::sys'));
        return next ok( not (res ? 'test::foo'), 'can delete user');
    end;
    $$;

\endif

\endif