\if :{?auth_param_sql}
\else
\set auth_param_sql true

    create function auth.param_names(app_id_ text)
        returns text[]
        language sql
        security definer
        stable
    as $$
        select array_agg(name)
        from auth_.param
        where app_id = app_id_
    $$;

    create function auth.param(id text)
        returns auth_.param
        language sql
        security definer
        stable
    as $$
        select *
        from auth_.param
        where param_id = id
    $$;

    create function auth.param(jsonb)
        returns auth_.param
        language sql
        security definer
        stable
    as $$
        select jsonb_populate_record(
            null::auth_.param,
            coalesce(to_jsonb(auth.param($1->>'param_id')), '{}') ||
            $1
        )
    $$;

    comment on function auth.param(jsonb)
        is 'builds auth_.param from jsonb. '
        'retrieves record if param_id is available.';

    create function auth.set(auth_.param)
        returns auth_.param
        language sql
        security definer
    as $$
        insert into auth_.param(app_id, name, description, value, option)
        values (
            $1.app_id,
            $1.name,
            $1.description,
            $1.value,
            $1.option)
        on conflict (app_id, name)
        do update set
        description = excluded.description,
        value = excluded.value,
        option = excluded.option
        returning *
    $$;


    create function auth.delete(auth_.param)
        returns auth_.param
        language sql
        security definer
    as $$
        delete from auth_.param
        where param_id = $1.param_id
        returning *
    $$;

\endif
