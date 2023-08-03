\if :{?auth_setting_sql}
\else
\set auth_setting_sql true

-- setting stores app-setting of an object

\ir param.sql

    create function auth.setting(text)
        returns auth_.setting
        language sql
        security definer
        stable
        strict
    as $$
        select *
        from auth_.setting
        where setting_id = $1
    $$;

    create function auth.setting(jsonb)
        returns auth_.setting
        language sql
        security definer
        stable
    as $$
        select jsonb_populate_record(
            null::auth_.setting,
            coalesce(to_jsonb(auth.setting($1->>'setting_id')), '{}') ||
            $1
        )
    $$;

    create function auth.set(auth_.setting)
        returns auth_.setting
        language sql
        security definer
    as $$
        insert into auth_.setting(typeof, ref_id, app_id, value, value_tz)
        values (
            $1.typeof,
            $1.ref_id,
            $1.app_id,
            auth.filter(
                $1.value,
                auth.param_names($1.app_id) ),
            current_timestamp
        )
        on conflict (typeof, ref_id, app_id)
        do update set
            value = excluded.value,
            value_tz = current_timestamp
        returning *
    $$;

    create function auth.delete(auth_.setting)
        returns auth_.setting
        language sql
        security definer
    as $$
        delete from auth_.setting
        where setting_id = $1.setting_id
        returning *
    $$;






    -- create function auth.setting(
    --     typeof_ text,
    --     ref_id_ text,
    --     app_id_ text,
    --     setting_ jsonb
    -- )
    --     returns auth_.setting
    --     language sql
    --     security definer
    -- as $$
    --     insert into auth_.setting(typeof, ref_id, app_id, value, value_tz)
    --     values (
    --         typeof_,
    --         ref_id_,
    --         app_id_,
    --         auth.filter(
    --             setting_,
    --             auth.param_names(app_id_) ),
    --         current_timestamp
    --     )
    --     on conflict (typeof, ref_id, app_id)
    --     do update set
    --         value = excluded.value,
    --         value_tz = current_timestamp
    --     returning *
    -- $$;

    -- comment on function auth.setting(text,text,text,jsonb)
    --     is 'stores into setting table';


    -- create function auth.setting(
    --     typeof_ text,
    --     ref_id_ text,
    --     app_settings_ jsonb
    -- )
    --     returns setof auth_.setting
    --     language sql
    --     security definer
    -- as $$
    --     select auth.setting(
    --         typeof_,
    --         ref_id_,
    --         app.app_id,
    --         t.value -- {param_id:value}
    --     )
    --     from jsonb_each(app_settings_) t,
    --         auth_.app
    --     where app.app_id = t.key
    -- $$;

    -- comment on function auth.setting(text,text,jsonb)
    --     is 'stores into setting table with app_settings is {app_id:setting}';


    -- create function auth.setting(
    --     svc_ auth_.service,
    --     app_settings_ jsonb
    -- )
    --     returns setof auth_.setting
    --     language sql
    --     security definer
    -- as $$
    --     select auth.setting(
    --         typeof_ => 'auth_.service',
    --         ref_id_ => svc_.service_id,
    --         app_settings_ => app_settings_
    --     )
    -- $$;

    -- create function auth.setting (
    --     brand_  auth_.brand,
    --     app_settings_ jsonb
    -- )
    --     returns setof auth_.setting
    --     language sql
    --     security definer
    -- as $$
    --     select auth.setting(
    --         typeof_ => 'auth_.brand',
    --         ref_id_ => brand_.brand_id,
    --         app_settings_ => app_settings_
    --     )
    -- $$;

    -- create function auth.setting(
    --     typ_ auth_.user_type,
    --     app_settings_ jsonb
    -- )
    --     returns setof auth_.setting
    --     language sql
    --     security definer
    -- as $$
    --     select auth.setting(
    --         typeof_ => 'auth_.user_type',
    --         ref_id_ => typ_.user_type_id,
    --         app_settings_ => app_settings_
    --     )
    -- $$;

    -- create function auth.setting(
    --     usr_ auth_.user,
    --     app_settings_ jsonb
    -- )
    --     returns setof auth_.setting
    --     language sql
    --     security definer
    -- as $$
    --     select auth.setting(
    --         typeof_ => 'auth_.user',
    --         ref_id_ => usr_.user_id,
    --         app_settings_ => app_settings_
    --     )
    -- $$;


\endif
