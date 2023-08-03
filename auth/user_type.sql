\if :{?auth_user_type_sql}
\else
\set auth_user_type_sql true

\ir service.sql

    create function auth.user_type(id text)
        returns auth_.user_type
        language sql
        security definer
        stable
    as $$
        select *
        from auth_.user_type
        where user_type_id = id
    $$;

    create function auth.user_type(jsonb)
        returns auth_.user_type
        language sql
        security definer
        stable
    as $$
        select jsonb_populate_record(
            null::auth_.user_type,
            coalesce(to_jsonb(auth.user_type($1->>'user_type_id')), '{}') ||
            $1
        )
    $$;

    create function auth.set(auth_.user_type)
        returns auth_.user_type
        language sql
        security definer
    as $$
        insert into auth_.user_type (brand_id, name, apps, services)
        values (
            $1.brand_id,
            $1.name,
            coalesce(auth.intersect(
                $1.apps,
                auth.app_ids() ), --- should be this limited to brand.apps instead?
                '{}'),
            coalesce(auth.intersect(
                $1.services,
                auth.service_ids() ),
                '{}')
        )
        on conflict (brand_id, name)
        do update set
            name = excluded.name,
            apps = excluded.apps,
            services = excluded.services
        returning *
    $$;


    create function auth.delete(auth_.user_type)
        returns auth_.user_type
        language sql
        security definer
    as $$
        delete from auth_.user_type
        where user_type_id = $1.user_type_id
        returning *
    $$;

\endif
