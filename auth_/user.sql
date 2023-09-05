\if :{?auth__user_sql}
\else
\set auth__user_sql true

    create table if not exists auth_.user (
        brand_id text
            references auth_.brand(brand_id)
            on delete cascade,
        name text not null,
        unique (brand_id, name),

        user_id text
            generated always as (brand_id || '#' || name)
            stored
            primary key,

        uid text
            unique
            default gen_random_uuid()::text,

        last_signon_tz timestamp with time zone,

        user_type_id text
            references auth_.user_type(user_type_id), -- it is ok to have a null user_type

        data jsonb
            default '{}', -- persistent user-data

        services text[] -- auth_.service_id[]
    );

    comment on table auth_.user_type
        is 'contains user''s basic information';


    create table if not exists auth_.user_ (
        user_id text
            primary key
            references auth_.user(user_id)
            on delete cascade,

        private_key text
            default md5(gen_random_uuid()::text),

        password text
            not null,

        email text
    );

    comment on table auth_.user_
        is 'user private info';

\endif


