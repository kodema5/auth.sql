
\if :{?auth_web_test_signon_sql}
\else
\set auth_web_test_signon_sql true

    create function tests.test_auth_web_test_signon_sql() returns setof text language plpgsql
    as $$
    declare
        res jsonb;
    begin
        res = auth.web_api('{
            "signon": { "brand_id": "test", "name":"user", "password":"test" },
            "signoff": true,
            "env": true
        }');

        return next ok(
            res->'signon' is not null,
            'able to signon');
    end;
    $$;

\endif
