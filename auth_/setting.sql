\if :{?auth__setting_sql}
\else
\set auth__setting_sql true

-- app -> param -> SETTING -> service

    create table if not exists auth_.setting (
        typeof text not null,
        ref_id text not null,
        app_id text not null
            references auth_.app(app_id)
            on delete cascade,
        unique(typeof, ref_id, app_id),

        setting_id text
            generated always as (typeof || '#' || ref_id || '#' || app_id)
            stored
            primary key,

        value jsonb default '{}',

        value_tz timestamp with time zone
            default current_timestamp
    );

    comment on column auth_.setting.typeof
        is 'class type that reference this setting. '
        'usually a table name. ex: auth_.brand';

    comment on column auth_.setting.ref_id
        is 'instance of typeof (table).'
        'usually entity-id in that table. ex: "foo"';

    comment on column auth_.setting.app_id
        is 'reference to application which settings overrides its default params';

    comment on column auth_.setting.value
        is 'the override values of application params.';


    create index if not exists auth_setting_idx on auth_.setting (
        typeof, ref_id, app_id
    );

\endif