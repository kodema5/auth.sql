\if :{?auth__app_sql}
\else
\set auth__app_sql true

-- APP -> param -> setting -> service

    create table if not exists auth_.app (
        app_id text not null primary key,

        name text
    );

    comment on table auth_.app
        is 'contains the app of parameters';


\endif