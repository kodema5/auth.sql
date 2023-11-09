\if :{?auth_has_sql}
\else
\set auth_has_sql true

    create function auth.auth_jsonpaths(
        auth_ids text[]
    )
        returns jsonpath[]
        language sql
        security definer
        stable
    as $$
        select array_agg(
            coalesce(a.path, id::jsonpath))
        from unnest(auth_ids) arr (id)
        left outer join auth_.auth a
            on a.auth_id = arr.id
    $$;

    create function auth.has_any(
        obj jsonb,
        arr jsonpath[]
    )
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

    create function auth.has_any(
        auths text[],
        obj_ jsonb default (auth.env_t()).setting
    )
        returns boolean
        language sql
        security definer
        stable
    as $$
        select auth.has_any(obj_, auth.auth_jsonpaths(auths))
    $$;

    comment on function auth.has_any(text[], jsonb)
        is 'if setting has any of the auth-id';


    create function auth.has_all(
        obj jsonb,
        arr jsonpath[]
    )
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


    create function auth.has_all(
        auth_ids text[],
        obj_ jsonb default (auth.env_t()).setting
    )
        returns boolean
        language sql
        security definer
        stable
    as $$
        select auth.has_all(obj_, auth.auth_jsonpaths(auth_ids))
    $$;

    comment on function auth.has_all(text[], jsonb)
        is 'if setting has all of the auth-ids';

\if :{?test}
    create function tests.test_auth_has_sql() returns setof text language plpgsql
    as $$
    begin
        return next ok(
            auth.has_any('{"a":{"b":true}}', '{"$.a.b"}'::jsonpath[]),
            'can query jsonpath');

        return next ok(
            auth.has_any('{"a":{"b":true}}', '{}'::jsonpath[]),
            'allow empty jsonpath');

        return next ok(
            auth.has_any('{"a":{"b":true}}', null::jsonpath[]) is null,
            'capture null');
    end;
    $$;

\endif


\endif
