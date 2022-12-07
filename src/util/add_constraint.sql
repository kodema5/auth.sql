
\if :{?util_add_constraint_sql}
\else
\set util_add_constraint_sql true

create schema if not exists util;

-- drops and add constraints if one does not exists
-- when dependent functions are remove,
-- the related constraints may be removed also
-- this procedures can be useful to recreate them
--
drop type if exists util.add_constraint_it cascade;
create type util.add_constraint_it as (
    table_name text,
    constraint_name text,
    constraint_source text
);

create or replace procedure util.add_constraint (
    it util.add_constraint_it
)
    language plpgsql
    security definer
as $$
declare
    ident text[] = parse_ident(it.table_name);
    src text;
begin
    if not exists (
        select constraint_name
        from information_schema.constraint_column_usage
        where table_schema = ident[1]
        and table_name = ident[2]
        and constraint_name = it.constraint_name
    ) then
        src = format(
            'alter table %I.%I add constraint %I %s',
            ident[1], ident[2],
            it.constraint_name,
            it.constraint_source);
        execute src;
    end if;
end;
$$;

create or replace procedure util.add_constraints (
    arr util.add_constraint_it[]
)
    language plpgsql
    security definer
as $$
declare
    a util.add_constraint_it;
begin
    foreach a in array arr
    loop
        call util.add_constraint(a);
    end loop;
end;
$$;

\endif