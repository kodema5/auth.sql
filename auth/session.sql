\if :{?auth_session_sql}
\else
\set auth_session_sql true
-- accesses auth_.session

\ir setting_t.sql

    create function auth.session(usr auth_.user)
        returns auth_.session
        language sql
        security definer
    as $$
        insert into auth_.session (user_id, setting)
        values (
            usr.user_id,
            auth.setting_t(usr)
        )
        returning *
    $$;

    create function auth.session (
        sid_ text default current_setting('auth.session_id', true)
    )
        returns auth_.session
        language sql
        security definer
        stable
    as $$
        select *
        from auth_.session s
        where session_id = sid_
    $$;


    create function auth._session_merge_keys(jsonb, jsonb, keys text[])
        returns jsonb
        language sql
        security definer
        stable
    as $$
        with
        kv as (
            select key,
            coalesce($1->key, '{}') || coalesce($2->key, '{}') value
            from unnest(keys) cs(key)
        )
        select coalesce($1,'{}')
            || coalesce($1,'{}')
            || jsonb_object_agg(key, value)
        from kv
    $$;


    create function auth.session(jsonb)
        returns auth_.session
        language sql
        security definer
        stable
    as $$
        select jsonb_populate_record(
            null::auth_.session,
            auth._session_merge_keys(
                coalesce(to_jsonb(auth.session($1->>'session_id')), '{}'),
                $1,
                '{"setting","data"}')
        )
    $$;

    create function auth.set(auth_.session)
        returns auth_.session
        language sql
        security definer
    as $$
        insert into auth_.session (session_id, user_id, setting, data)
        values (
            $1.session_id,
            $1.user_id,
            jsonb_strip_nulls(coalesce($1.setting,'{}')), -- should this be original user's setting?
            jsonb_strip_nulls(coalesce($1.data, '{}'))
        )
        on conflict (session_id)
        do update set
            user_id = excluded.user_id,
            setting = excluded.setting,
            data = excluded.data
        returning *
    $$;


    create function auth.delete(auth_.session)
        returns auth_.session
        language sql
        security definer
    as $$
        delete from auth_.session
        where session_id = $1.session_id
        returning *
    $$;

\endif
