\if :{?auth_util_array_sql}
\else
\set auth_util_array_sql true

    create function auth.intersect(anyarray, anyarray)
        returns anyarray
        language sql
        security definer
        immutable
    as $$
        select
            array(select unnest($1)
            intersect
            select unnest($2))
    $$;

    comment on function auth.intersect(anyarray, anyarray)
        is 'returns only elements in both arrays';


    create function auth.union(anyarray, anyarray)
        returns anyarray
        language sql
        security definer
        immutable
    as $$
        select array(
            select unnest($1)
            union
            select unnest($2))
    $$;

    comment on function auth.union(anyarray, anyarray)
        is 'combine 2 arrays';


    create function auth.union(anyarray, anyarray, anyarray)
        returns anyarray
        language sql
        security definer
        immutable
    as $$
        select array(
            select unnest($1)
            union
            select unnest($2)
            union
            select unnest($3))
    $$;

    comment on function auth.union(anyarray, anyarray, anyarray)
        is 'combine 3 arrays';


    create function auth.except(anyarray, anyarray)
        returns anyarray
        language sql
        security definer
        immutable
    as $$
        select array(
            select unnest($1)
            except
            select unnest($2))
    $$;

    comment on function auth.except(anyarray, anyarray)
        is 'remove from array not in array';


    create function auth.reorder(
        array_ anyarray,
        index_ int[],
        dir_ text default 'asc'
    )
        returns anyarray
        language sql
        security definer
    as $$
        select array(
            select a
            from unnest(array_, index_) as x(a,i)
            order by
                (case when lower(dir_)='asc' then i end),
                i desc
        )
    $$;

    comment on function auth.reorder(anyarray, int[], text)
        is 're-order array based on index';
    -- select auth.reorder(array['b','a','c'], array[2,1,3]);
    -- select auth.reorder(array['b','a','c'], array[2,1,3], 'desc');

\endif