\if :{?auth_auth_sql}
\else
\set auth_auth_sql true
-- auth is a pair of code and jsonbpath to query setting (jsonb)

\ir env_t.sql

    create function auth.auth(id text)
        returns auth_.auth
        language sql
        security definer
        stable
    as $$
        select *
        from auth_.auth
        where auth_id = id
    $$;

    create function auth.auth(jsonb)
        returns auth_.auth
        language sql
        security definer
        stable
    as $$
        select jsonb_populate_record(
            null::auth_.auth,
            coalesce(to_jsonb(auth.auth($1->>'auth_id')), '{}') ||
            $1
        )
    $$;

    create function auth.set(auth_.auth)
        returns auth_.auth
        language sql
        security definer
    as $$
        insert into auth_.auth (auth_id, path)
        values (
            $1.auth_id,
            $1.path)
        on conflict (auth_id)
        do update set
            path = excluded.path
        returning *
    $$;

    create function auth.delete(auth_.auth)
        returns auth_.auth
        language sql
        security definer
    as $$
        delete from auth_.auth
        where auth_id = $1.auth_id
        returning *
    $$;


    create function auth.auth_paths(auth_ids text[])
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


    comment on function auth.auth_paths(text[])
        is 'collects the auth paths for given ids';


    create function auth.has(
        auths text[],
        obj_ jsonb default (auth.env_t()).setting)
        returns boolean
        language sql
        security definer
        stable
    as $$
        select auth.has(obj_, auth.auth_paths(auths))
    $$;

    create function auth.have(
        auths text[],
        obj_ jsonb default (auth.env_t()).setting)
        returns boolean
        language sql
        security definer
        stable
    as $$
        select auth.have(obj_, auth.auth_paths(auths))
    $$;


\endif
