\if :{?auth_app_setting_t_sql}
\else
\set auth_app_setting_t_sql true

-- app-setting-t is a utility used in setting_t.sql

    create type auth.app_setting_t as (
        app_id text,
        setting jsonb
    );

    comment on type auth.app_setting_t
        is 'app and setting pair';

    create function auth.app_setting_ts (
        app_ids_ text[] default null,
        debug_ boolean default false
    )
        returns setof auth.app_setting_t
        language sql
        security definer
        stable
    as $$
        select (
            p.app_id,
            jsonb_object_agg(
                p.name,
                (case
                when debug_ then jsonb_build_object(
                    '_typeof', 'auth_.param',
                    '_ref_id', p.param_id,
                    '_value', p.value
                )
                else p.value
                end)
            )
        )::auth.app_setting_t
        from auth_.param p
        where app_ids_ is null or p.app_id = any(app_ids_)
        group by p.app_id
        order by p.app_id
    $$;

    comment on function auth.app_setting_ts(text[],boolean)
        is 'returns default app-settings for apps';


    create function auth.app_setting_ts (
        typeof_ text,
        ref_ids_ text[],
        app_ids_ text[] default null,
        debug_ boolean default false
    )
        returns setof auth.app_setting_t
        language sql
        security definer
    as $$
        select (
            s.app_id,
            (case
            when debug_ then (
                select jsonb_object_agg(
                    sv.key,
                    jsonb_build_object(
                        '_typeof', s.typeof,
                        '_ref_id', s.ref_id,
                        '_value', sv.value
                    )
                )
                from jsonb_each(s.value) sv
            )
            else s.value
            end)
        )::auth.app_setting_t
        from auth_.setting s
        where s.typeof = typeof_
        and (ref_ids_ is null or s.ref_id = any(ref_ids_))
        and ( app_ids_ is null or s.app_id = any(app_ids_))
    $$;

    comment on function auth.app_setting_ts(text,text[],text[],boolean)
        is 'returns app-settings stored setting';

\endif
