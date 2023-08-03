\if :{?auth_app_sql}
\else
\set auth_app_sql true
-- app is the first key on entitlement

    create function auth.app_ids()
        returns text[]
        language sql
        security definer
        stable
    as $$
        select array_agg(app_id)
        from auth_.app
    $$;

    comment on function auth.app_ids()
        is 'list of available app-ids';


    create function auth.app(id text)
        returns auth_.app
        language sql
        security definer
        stable
    as $$
        select *
        from auth_.app
        where app_id = id
    $$;


    create function auth.app(jsonb)
        returns auth_.app
        language sql
        security definer
        stable
    as $$
        select jsonb_populate_record(
            null::auth_.app,
            coalesce(to_jsonb(auth.app($1->>'app_id')), '{}') ||
            $1
        )
    $$;


    create function auth.set(auth_.app)
        returns auth_.app
        language sql
        security definer
    as $$
        insert into auth_.app (app_id, name)
        values ($1.app_id, $1.name)
        on conflict (app_id)
        do update
            set name = excluded.name
        returning *
    $$;


    create function auth.delete(auth_.app)
        returns auth_.app
        language sql
        security definer
    as $$
        delete from auth_.app
        where app_id = $1.app_id
        returning *
    $$;

\endif
