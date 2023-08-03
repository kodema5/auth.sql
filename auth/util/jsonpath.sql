\if :{?auth_util_jsonpath_sql}
\else
\set auth_util_jsonpath_sql true

    create function auth.has(obj jsonb, arr jsonpath[])
        returns boolean
        language sql
        security definer
        stable
        strict
    as $$
        select case
        when cardinality(arr) = 0 then true
        else (
            select count(1) > 0
            from unnest(arr) rs
            where coalesce((obj @@ rs)::boolean, false)
        )
        end
    $$;


    create function auth.have(obj jsonb, arr jsonpath[])
        returns boolean
        language sql
        security definer
        stable
        strict
    as $$
        select count(1) = cardinality(arr)
        from unnest(arr) rs
        where coalesce((obj @@ rs)::boolean, false)
    $$;


\if :{?test}
    create function tests.test_auth_util_jsonpath_sql() returns setof text language plpgsql
    as $$
    begin
        return next ok(
            auth.has('{"a":{"b":true}}', '{"$.a.b"}'::jsonpath[]),
            'can query jsonpath');

        return next ok(
            auth.has('{"a":{"b":true}}', '{}'::jsonpath[]),
            'allow empty jsonpath');

        return next ok(
            auth.has('{"a":{"b":true}}', null::jsonpath[]) is null,
            'capture null');
    end;
    $$;

\endif

\endif