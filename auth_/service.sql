\if :{?auth__service_sql}
\else
\set auth__service_sql true

    create table if not exists auth_.service (
        service_id text
            not null
            primary key,

        name text
    );

    comment on table auth_.service
        is 'a service can be used to manage common/template entitlements.'
        ' ex: USD service uses us$ denomination in app1, app2, app2,....';



\endif