\if :{?util_export_jsonb_fn_t_sql}
\else
\set util_export_jsonb_fn_t_sql true

-- creates a josn mapping to a user-defined-type
-- ex: call util.export(util.jsonb_fn_t('auth.auth_t'));
-- creates auth.auth_t(jsomb)
--
create schema if not exists util;

drop type if exists util.jsonb_fn_t cascade;
create type util.jsonb_fn_t as (
    typ regtype,
    val jsonb
);
create or replace function util.jsonb_fn_t (
    typ regtype,
    val jsonb default '{}'
)
    returns util.jsonb_fn_t
    language sql
    security definer
    stable
as $$
    select (typ, val)::util.jsonb_fn_t
$$;

create or replace procedure util.export (
    it util.jsonb_fn_t
)
    language plpgsql
    security definer
as $$
declare
    src text;
begin
    src = format('create function %s(it jsonb) '
    'returns %s language sql security definer as $fn$ '
        'select jsonb_populate_record(null::%s, %L::jsonb || it)'
    '$fn$',
    it.typ, it.typ, it.typ, coalesce(it.val, '{}'::jsonb)
    );

    execute src;
end;
$$;

\endif