\if :{?auth__param_sql}
\else
\set auth__param_sql true

    create table if not exists auth_.param (
        app_id text not null
            references auth_.app(app_id)
            on delete cascade,
        name text not null,
        unique (app_id, name),

        param_id text
            generated always as (app_id || '::' || name)
            stored
            primary key,


        description text,
        value jsonb,

        option jsonb -- TODO strengthen options validations
    );

    comment on table auth_.param
        is 'contains an application parameters';


\endif