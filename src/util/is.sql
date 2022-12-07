\if :{?util_is_sql}
\else
\set util_is_sql true

create schema if not exists util;

create or replace function util.is_id (
    a text
)
    returns boolean
    language sql
    security definer
    immutable
    strict
as $$
    select a = lower(a)
    and a ~ '^[a-zA-Z0-9_]+$';
$$;

create or replace function util.is_email(
    a text
)
    returns boolean
    language sql
    security definer
    immutable
    strict
as $$
    select a ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'
$$;

\endif