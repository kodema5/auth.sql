---------------------------------------------------------------------------
-- system log

create table auth.log (
    ts timestamp with time zone default clock_timestamp(),
    msg text,
    data jsonb,
    src text
);

---------------------------------------------------------------------------
-- get initial caller function

create function auth.get_caller_fn() returns text as $$
declare
    s text;
    arr text[];
    fn text;
begin
    get diagnostics s = pg_context;
    arr = regexp_split_to_array ( s, E'\n');
    fn = substring(arr[array_length(arr,1)] from 'function (.*?) line');
    return fn;
end;
$$ language plpgsql;

---------------------------------------------------------------------------
-- log

create procedure auth.log (
    msg_ text,
    data_ jsonb default null,
    src_ text default null
) as $$
declare
    l auth.log;
begin
    insert into auth.log(msg, data, src)
    values (
        msg_,
        data_,
        coalesce(src_, auth.get_caller_fn())
    ) returning * into l;
    raise warning '% %', l.src, l.msg;
end;
$$ language plpgsql;