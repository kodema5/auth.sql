\if :{?util_config_sql}
\else
\set util_config_sql true


create schema if not exists util;

create or replace function util.set_config(
    name_ text,
    value_ text
)
    returns text
    language sql
    security definer
as $$
    select set_config(name_, value_, true);
$$;


create or replace function util.get_config(
    name_ text,
    default_ text default ''
)
    returns text
    language sql
    security definer
as $$
    select coalesce(current_setting(name_, true), default_);
$$;



\endif