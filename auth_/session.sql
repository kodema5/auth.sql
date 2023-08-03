\if :{?auth__session_sql}
\else
\set auth__session_sql true

    create table if not exists auth_.session (
        session_id text
            default md5(gen_random_uuid()::text)
            primary key,

        user_id text
            references auth_.user(user_id)
            on delete cascade,

        created_tz timestamp with time zone
            default current_timestamp,

        last_tz timestamp with time zone
            default current_timestamp,

        setting jsonb,

        data jsonb
            default '{}'
    );

    comment on column auth_.session.setting
        is 'contains cached setting when user logs-in';

\endif