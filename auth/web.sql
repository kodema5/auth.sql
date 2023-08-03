\if :{?auth_web_sql}
\else
\set auth_web_sql true

-- web_api is a composite api
-- it accesses other web_* api
-- it is a preferred way to access module

\ir header_t.sql
\ir request_t.sql
\ir response_t.sql

\ir web/signon.sql
\ir web/signoff.sql

\ir web/app.sql
\ir web/param.sql
\ir web/setting.sql
\ir web/auth.sql
\ir web/service.sql

\ir web/brand.sql
\ir web/user_type.sql
\ir web/user.sql
\ir web/session.sql

\ir web/env.sql

    create type auth.web_api_t as (
        signon jsonb,
        signup jsonb,
        signoff boolean,

        app_set jsonb,
        app_delete jsonb,
        apps jsonb,

        param_set jsonb,
        param_delete jsonb,
        params jsonb,

        setting_set jsonb,
        setting_delete jsonb,
        settings jsonb,

        service_set jsonb,
        service_delete jsonb,
        services jsonb,

        auth_set jsonb,
        auth_delete jsonb,
        auths jsonb,

        brand_set jsonb,
        brand_delete jsonb,
        brands jsonb,

        user_type_set jsonb,
        user_type_delete jsonb,
        user_types jsonb,

        user_set jsonb,
        user_delete jsonb,
        users jsonb,

        session_set jsonb,
        session_delete jsonb,
        sessions jsonb,

        env boolean
    );

    create function auth.web_api(jsonb)
        returns jsonb
        language plpgsql
        security definer
        set search_path=auth, public
    as $$
    declare
        req web_api_t;
        env env_t; -- if null, call is an un-authenticated one
        res jsonb = '{}';
    begin
        -- reset env first
        perform env_t(null);


        -- request_t updates environment by req object
        req = jsonb_populate_record(
            null::web_api_t,
            request_t($1, request_option_t(
                is_session_required => false
            )));
        env = env_t();


        -- keep env after each web_* calls
        perform set_config('auth.web_api', 't', true);

        <<session_creation>>
        begin
            if not (env.session_id is null) then
                exit session_creation;
            end if;

            res = res || jsonb_build_object(
                'signon', web_signon(req.signon)
            );

            env = env_t();
        end;


        <<authenticated>>
        begin
            if env.session_id is null then
                exit authenticated;
            end if;

            res = res || jsonb_build_object(
                'app_set', web_app_set(req.app_set),
                'app_delete', web_app_delete(req.app_delete),
                'apps', web_apps(req.apps),

                'param_set', web_param_set(req.param_set),
                'param_delete', web_param_delete(req.param_delete),
                'params', web_apps(req.params),

                'setting_set', web_setting_set(req.setting_set),
                'setting_delete', web_setting_delete(req.setting_delete),
                'settings', web_settings(req.settings),

                'service_set', web_service_set(req.service_set),
                'service_delete', web_service_delete(req.service_delete),
                'services', web_services(req.services),

                'auth_set', web_auth_set(req.auth_set),
                'auth_delete', web_auth_delete(req.auth_delete),
                'auths', web_auths(req.auths),

                'brand_set', web_brand_set(req.brand_set),
                'brand_delete', web_brand_delete(req.brand_delete),
                'brands', web_brands(req.brands),

                'user_type_set', web_user_type_set(req.user_type_set),
                'user_type_delete', web_user_type_delete(req.user_type_delete),
                'user_types', web_user_types(req.user_types),

                'user_set', web_user_set(req.user_set),
                'user_delete', web_user_delete(req.user_delete),
                'users', web_users(req.users),

                'session_set', web_session_set(req.session_set),
                'session_delete', web_session_delete(req.session_delete),
                'sessions', web_sessions(req.sessions),

                'env', web_env(to_jsonb(req.env))
            );
        end;

        <<session_removal>>
        begin
            if env.session_id is null then
                exit session_removal;
            end if;

            res = res || jsonb_build_object(
                'signoff', web_signoff(to_jsonb(req.signoff))
            );
        end;

        perform set_config('auth.web_api', '', true);

        return auth.response_t(res);

    exception
        when others then
            perform set_config('auth.web_api', '', true);
            perform auth.env_t(null);
            raise; -- rethrow
    end;
    $$;

\ir web/test.sql

\endif
