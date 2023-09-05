\if :{?auth_web_api_sql}
\else
\set auth_web_api_sql true

-- web_api is a composite API

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


    create function auth.web_api(
        jsonb,
        jsonb default null,
        out res jsonb,
        out res_ jsonb
    )
        language plpgsql
        security definer
        set search_path=auth, public
    as $$
    declare
        req web_api_t;
        env env_t; -- if null, call is an un-authenticated one
        ret jsonb = '{}';
        is_set_headers boolean = false;
    begin
        -- reset env first and get req
        perform env_t(null);
        req = jsonb_populate_record(null::web_api_t, web_request_t($1, $2));
        env = env_t();

        perform set_config('auth.web_response_t.is_reset_env', 'f', true);

        -- creates sessions
        <<session_creation>>
        begin
            if not (env.session_id is null) then
                exit session_creation;
            end if;

            if req.signon is not null then
                ret = ret
                    || jsonb_build_object('signon', (select f.res from web_signon(req.signon) f));
                is_set_headers = true;
            end if;

            env = env_t();
        end;


        <<authenticated>>
        begin
            if env.session_id is null then
                exit authenticated;
            end if;

            ret = ret || jsonb_build_object(
                'app_set',
                    case when req.app_set is not null then (select f.res from web_app_set(req.app_set) f) else null end,
                'app_delete',
                    case when req.app_delete is not null then (select f.res from web_app_delete(req.app_delete) f) else null end,
                'apps',
                    case when req.apps is not null then (select f.res from web_apps(req.apps) f) else null end,

                'param_set',
                    case when req.param_set is not null then (select f.res from web_param_set(req.param_set) f) else null end,
                'param_delete',
                    case when req.param_delete is not null then (select f.res from web_param_delete(req.param_delete) f) else null end,
                'params',
                    case when req.params is not null then (select f.res from web_params(req.params) f) else null end,

                'setting_set',
                    case when req.setting_set is not null then (select f.res from web_setting_set(req.setting_set) f) else null end,
                'setting_delete',
                    case when req.setting_delete is not null then (select f.res from web_setting_delete(req.setting_delete) f) else null end,
                'settings',
                    case when req.settings is not null then (select f.res from web_settings(req.settings) f) else null end,

                'service_set',
                    case when req.service_set is not null then (select f.res from web_service_set(req.service_set) f) else null end,
                'service_delete',
                    case when req.service_delete is not null then (select f.res from web_service_delete(req.service_delete) f) else null end,
                'services',
                    case when req.services is not null then (select f.res from web_services(req.services) f) else null end,

                'auth_set',
                    case when req.auth_set is not null then (select f.res from web_auth_set(req.auth_set) f) else null end,
                'auth_delete',
                    case when req.auth_delete is not null then (select f.res from web_auth_delete(req.auth_delete) f) else null end,
                'auths',
                    case when req.auths is not null then (select f.res from web_auths(req.auths) f) else null end,

                'brand_set',
                    case when req.brand_set is not null then (select f.res from web_brand_set(req.brand_set) f) else null end,
                'brand_delete',
                    case when req.brand_delete is not null then (select f.res from web_brand_delete(req.brand_delete) f) else null end,
                'brands',
                    case when req.brands is not null then (select f.res from web_brands(req.brands) f) else null end,

                'user_type_set',
                    case when req.user_type_set is not null then (select f.res from web_user_type_set(req.user_type_set) f) else null end,
                'user_type_delete',
                    case when req.user_type_delete is not null then (select f.res from web_user_type_delete(req.user_type_delete) f) else null end,
                'user_types',
                    case when req.user_types is not null then (select f.res from web_user_types(req.user_types) f) else null end,

                'user_set',
                    case when req.user_set is not null then (select f.res from web_user_set(req.user_set) f) else null end,
                'user_delete',
                    case when req.user_delete is not null then (select f.res from web_user_delete(req.user_delete) f) else null end,
                'users',
                    case when req.users is not null then (select f.res from web_users(req.users) f)else null end,

                'session_set',
                    case when req.session_set is not null then (select f.res from web_session_set(req.session_set) f) else null end,
                'session_delete',
                    case when req.session_delete is not null then (select f.res from web_session_delete(req.session_delete) f) else null end,
                'sessions',
                    case when req.sessions is not null then (select f.res from web_sessions(req.sessions) f) else null end,

                'env',
                    case when req.env is not null then (select f.res from web_env(null) f) else null end
            );
        end;

        <<session_removal>>
        begin
            if env.session_id is null then
                exit session_removal;
            end if;


            if req.signoff is not null then
                ret = ret
                    || jsonb_build_object('signoff', (select f.res from web_signoff(to_jsonb(req.signoff)) f));
                is_set_headers = false;
            end if;
        end;

        -- perform set_config('auth.web_api', '', true);

        perform set_config('auth.web_response_t.is_reset_env', 't', true);

        select * from web_response_t(
            ret,
            is_set_headers => is_set_headers
        ) into $3, $4;

    exception
        when others then
            perform set_config('auth.web_response_t.is_reset_env', 't', true);
            perform auth.env_t(null);
            raise; -- rethrow
    end;
    $$;

\if :{?test}

    -- \set test_pattern web_api

    create function tests.test_auth_web_api()
        returns setof text
        language plpgsql
        set search_path=auth, public
    as $$
    declare
        head jsonb;
        a jsonb;
    begin
        select *
        from web_api(
            '{
                "signon": { "brand_id": "test", "name":"sys", "password":"test" },
                "env": true
            }'::jsonb,
            null)
        into a, head;
        return next ok(a ? 'signon' and head->>'authorization' is not null, 'able to signin');
        return next ok(a ? 'env' and a->'env'->>'session_id' is not null, 'able to call multiple command');

        a = res from web_api(
            '{
                "env": true
            }'::jsonb,
            head);
        return next ok(a ? 'env' and a->'env'->>'session_id' is not null, 'able to reuse header');

        a = res from web_api(
            '{
                "signoff": true
            }'::jsonb,
            head);
        return next ok(a ? 'signoff', 'able to signoff');

        return next throws_ok(
            format('select auth.web_env(%L::jsonb,%L::jsonb)', '{}', head),
            'auth.request_t.unrecognized_session',
            'header has been invalidated');


        -- it is possible to do it at a single shot
        select *
        from web_api(
            '{
                "signon": { "brand_id": "test", "name":"sys", "password":"test" },
                "settings": {},
                "env": true,
                "signoff": true
            }'::jsonb,
            null)
        into a, head;
        return next ok(a ? 'signon' and a ? 'env' and a ? 'settings' and a ? 'signoff', 'got signon, env, settings and signoff');
        return next ok(head is null, 'header is null since signed off');

    end;
    $$;


\endif

\endif
