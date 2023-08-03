\if :{?auth_setting_t_sql}
\else
\set auth_setting_t_sql true

-- build user setting (a jsonb)

\ir app_setting_t.sql
\ir param.sql

    create function auth.setting_t(
        usr_ auth_.user,
        debug_ boolean default false
    )
        returns jsonb
        language sql
        security definer
        stable
    as $$
        with
        user_params as (
            with
            brand_user_type as (
            select
                (select b from auth_.brand b where brand_id=usr_.brand_id) as brand,
                (select r from auth_.user_type r where user_type_id=usr_.user_type_id) as user_type
            )
            select
                usr_.user_id,
                usr_.brand_id,
                usr_.user_type_id,
                -- , coalesce(usr_.apps, (br.user_type).apps, (br.brand).apps) as app_ids
                coalesce((br.user_type).apps, (br.brand).apps) as app_ids,
                auth.union(usr_.services, (br.user_type).services, (br.brand).services) as service_ids
            from brand_user_type br
        )
        select usr_setting.*
        from user_params us
        left join lateral
        (
            with
            -- collect params [order#, app-id, setting]
            user_param_rows as not materialized (
                -- get default-settings
                select 1 as idx,
                    default_setting.*
                from auth.app_setting_ts(
                    app_ids_ => us.app_ids,
                    debug_ => debug_
                ) default_setting

                -- service-settings
                union all
                select 2,
                    services_overrides.*
                from auth.app_setting_ts(
                    'auth_.service',
                    ref_ids_ => us.service_ids,
                    app_ids_ => us.app_ids,
                    debug_ => debug_
                ) services_overrides

                -- brand-settings
                union all
                select 3,
                    brand_overrides.*
                from auth.app_setting_ts(
                    'auth_.brand',
                    ref_ids_ => array[us.brand_id],
                    app_ids_ => us.app_ids,
                    debug_ => debug_
                ) brand_overrides

                -- user-role/type settings
                union all
                select 4,
                    user_type_overrides.*
                from auth.app_setting_ts(
                    'auth_.user_type',
                    ref_ids_ => array[us.user_type_id],
                    app_ids_ => us.app_ids,
                    debug_ => debug_
                ) user_type_overrides

                -- user settings
                union all
                select 5,
                    user_overrides.*
                from auth.app_setting_ts(
                    'auth_.user',
                    ref_ids_ => array[us.user_id],
                    app_ids_ => us.app_ids,
                    debug_ => debug_
                ) user_overrides
            ),

            -- grouped by app-id
            -- set setting in ascending order#
            -- then use assign to apply overrides
            app_settings as not materialized (
                select app_id,
                    auth.filter( -- 4. check setting entries
                        auth.assign( -- 2. combine the params
                            variadic auth.reorder( -- 1. ensure params-array order
                                array_agg(setting),
                                array_agg(idx)
                            )
                        ),
                        auth.param_names(app_id) -- 3. get valid param names
                    ) as setting
                from user_param_rows
                group by app_id
            )

            -- combined based on app-id
            select jsonb_object_agg(
                app_id,
                setting
            )
            from app_settings
        ) usr_setting on true
    $$;

    comment on function auth.setting_t(auth_.user, boolean)
        is 'returns the setting of a user';

\endif
