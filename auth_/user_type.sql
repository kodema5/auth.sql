\if :{?auth__user_type_sql}
\else
\set auth__user_type_sql true

    create table if not exists auth_.user_type (
        brand_id text
            not null
            references auth_.brand(brand_id)
            on delete cascade,
        name text not null,
        unique (brand_id, name),

        user_type_id text
            generated always as (brand_id || '#' || name) stored
            primary key,

        apps text[], -- auth_.app_id[], a subset of brand.apps

        services text[] -- auth_.service_id[]
    );

    comment on table auth_.user_type
        is 'user_type is for re-using setings';
\endif
