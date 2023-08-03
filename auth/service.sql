\if :{?auth_service_sql}
\else
\set auth_service_sql true

    create function auth.service_ids()
        returns text[]
        language sql
        security definer
        stable
    as $$
        select array_agg(service_id)
        from auth_.service
    $$;

    comment on function auth.service_ids()
        is 'list of available service-ids';


    create function auth.service(id text)
        returns auth_.service
        language sql
        security definer
        stable
    as $$
        select *
        from auth_.service
        where service_id = id
    $$;


    create function auth.service(jsonb)
        returns auth_.service
        language sql
        security definer
        stable
    as $$
        select jsonb_populate_record(
            null::auth_.service,
            coalesce(to_jsonb(auth.service($1->>'service_id')), '{}') ||
            $1
        )
    $$;


    create function auth.set(auth_.service)
        returns auth_.service
        language sql
        security definer
    as $$
        insert into auth_.service (service_id, name)
        values ($1.service_id, $1.name)
        on conflict (service_id)
        do update
            set name = excluded.name
        returning *
    $$;


    create function auth.delete(auth_.service)
        returns auth_.service
        language sql
        security definer
    as $$
        delete from auth_.service
        where service_id = $1.service_id
        returning *
    $$;

\endif