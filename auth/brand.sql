\if :{?auth_brand_sql}
\else
\set auth_brand_sql true
-- brand is the first key on user

\ir app.sql
\ir service.sql

    create function auth.brand(id text)
        returns auth_.brand
        language sql
        security definer
        stable
    as $$
        select *
        from auth_.brand
        where brand_id = id
    $$;

    create function auth.brand(jsonb)
        returns auth_.brand
        language sql
        security definer
        stable
    as $$
        select jsonb_populate_record(
            null::auth_.brand,
            coalesce(to_jsonb(auth.brand($1->>'brand_id')), '{}') ||
            $1
        )
    $$;

    create function auth.set(auth_.brand)
        returns auth_.brand
        language sql
        security definer
    as $$
        insert into auth_.brand (brand_id, name, apps, services)
        values (
            $1.brand_id,
            $1.name,
            coalesce(auth.intersect(
                $1.apps,
                auth.app_ids() ),
                '{}'),
            coalesce(auth.intersect(
                $1.services,
                auth.service_ids() ),
                '{}')
        )
        on conflict (brand_id)
        do update set
            name = excluded.name,
            apps = excluded.apps,
            services = excluded.services
        returning *
    $$;


    create function auth.delete(auth_.brand)
        returns auth_.brand
        language sql
        security definer
    as $$
        delete from auth_.brand
        where brand_id = $1.brand_id
        returning *
    $$;

\endif
