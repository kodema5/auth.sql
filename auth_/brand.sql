\if :{?auth__brand_sql}
\else
\set auth__brand_sql true

    create table if not exists auth_.brand (
        brand_id text not null
            primary key,

        name text,

        apps -- auth_.app_id[]
            text[]
            default '{}',

        services -- auth_.service_id[]
            text[]
            default '{}'
    );

    comment on table auth_.brand
        is 'the authentication model used is brand -> user_type -> user -> session';

\endif