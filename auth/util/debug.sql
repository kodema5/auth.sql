\if :{?auth_util_debug_sql}
\else
\set auth_util_debug_sql true

-- for debugging a SQL statement often hard to see value
-- ex: select auth.inspect(('a',null)::auth_.app);
--
    create procedure auth.debug(anyelement)
        language plpgsql
        security definer
    as $$
    begin
        raise warning 'DEBUG> [%] %',
            pg_typeof($1),
            jsonb_pretty(to_jsonb($1));
    end;
    $$;

    comment on procedure auth.debug(anyelement)
        is 'logs then return ~ (a) => { console.log(a); }';


    create procedure auth.debug(text, anyelement)
        language plpgsql
        security definer
    as $$
    begin
        raise warning 'DEBUG> % [%] %',
            coalesce($1, ''),
            pg_typeof($2),
            jsonb_pretty(to_jsonb($2));
    end;
    $$;


    create function auth.inspect(text, anyelement)
        returns anyelement
        language plpgsql
        security definer
    as $$
    begin
        raise warning 'INSPECT> % [%] %',
            coalesce($1, ''),
            pg_typeof($2),
            jsonb_pretty(to_jsonb($2));
        return $2;
    end;
    $$;

    create function auth.inspect(anyelement)
        returns anyelement
        language plpgsql
        security definer
    as $$
    begin
        raise warning 'INSPECT> [%] %',
            pg_typeof($1),
            jsonb_pretty(to_jsonb($1));
        return $1;
    end;
    $$;

    comment on function auth.inspect(anyelement)
        is 'logs then return ~ (a) => { console.log(a); return a }';

\endif
