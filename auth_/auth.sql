\if :{?auth__auth_sql}
\else
\set auth__auth_sql true


    create table if not exists auth_.auth (
        auth_id text not null primary key,

        path jsonpath not null
    );

    comment on table auth_.auth
        is 'contains tagged setting query for authorization.'
        ' so that user need not need to remember path.'
        ' see is_auth for usage.';


\endif