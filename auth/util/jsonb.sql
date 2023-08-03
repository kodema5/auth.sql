\if :{?auth_util_jsonb_sql}
\else
\set auth_util_jsonb_sql true

    create function auth.keys(obj_ jsonb)
        returns text[]
        language sql
        security definer
        immutable
    as $$
        select coalesce(array_agg(a), '{}')
        from jsonb_object_keys( obj_ ) a
    $$;

    comment on function auth.keys(jsonb)
        is 'returns object keys';

    create function auth.texts(arr_ jsonb)
        returns text[]
        language sql
        security definer
        immutable
    as $$
        select coalesce(array_agg(value), '{}')
        from jsonb_array_elements_text(arr_)
    $$;

    comment on function auth.texts(jsonb)
        is 'returns array as text[]';


    create function auth.filter (obj_ jsonb, keys_ text[])
        returns jsonb
        language sql
        security definer
        stable
    as $$
        select jsonb_strip_nulls(
            $1 - auth.except(auth.keys( obj_ ), keys_)
        )
    $$;

    comment on function auth.filter(jsonb, text[])
        is 'filter object only within keys';

    create function auth.except(obj_ jsonb, keys_ text[])
        returns jsonb
        language sql
        security definer
        stable
        strict
    as $$
        select jsonb_object_agg(kv.key, kv.value)
        from jsonb_each( obj_ ) kv
        where not kv.key = any(keys_)
    $$;

    comment on function auth.filter(jsonb, text[])
        is 'filter object without keys';


    create function auth.filter(obj_ jsonb, regex_ text)
        returns jsonb
        language sql
        security definer
        stable
        strict
    as $$
        select jsonb_object_agg(kv.key, kv.value)
        from jsonb_each( obj_ ) kv
        where kv.key ~* regex_
    $$;

    comment on function auth.filter(jsonb, text)
        is 'filter object with regex key';


    create function auth.except(obj_ jsonb, regex_ text)
        returns jsonb
        language sql
        security definer
        stable
        strict
    as $$
        select jsonb_object_agg(kv.key, kv.value)
        from jsonb_each( obj_ ) kv
        where kv.key !~* regex_  -- filter out based on posix regex
    $$;

    comment on function auth.filter(jsonb, text)
        is 'filter object without regex key';


    create aggregate auth.assign(jsonb) (
        sfunc  = 'jsonb_concat',
        stype = 'jsonb',
        initcond = '{}'
    );

    comment on function auth.assign(jsonb)
        is 'collect keys ~ Object.assign(....)';


    create function auth.assign(variadic jsonb[])
        returns jsonb
        language sql
        security definer
        strict
    as $$
        select auth.assign(v)
        from unnest($1) v
    $$;

    comment on function auth.assign(jsonb[])
        is 'collect keys ~ Object.assign(....)';


    -- create function auth.set(obj_ jsonb, key_ text, val_ anyelement)
    --     returns jsonb
    --     language sql
    --     security definer
    -- as $$
    --     select obj_ || jsonb_build_object(key_, val_)
    -- $$;
    -- comment on function auth.set(jsonb, text, anyelement)
    --     is 'assigns key-value to a json object. object[key] = value';

\endif