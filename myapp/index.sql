\ir ../auth.sql/index.sql

drop schema if exists myapp cascade;
create schema myapp;

------------------------------------------------------------------------------
-- sets the environment vriabhles
--

create function myapp.__env__() returns text as $$
    select c1
    from (select
        set_config('auth.namespace', 'myapp', true) -- local transaction scope
    ) as t (c1)
$$ language sql  security definer;


------------------------------------------------------------------------------
-- initialize the module (it should be re-entrant -- can be called multiple
-- times without side-effect)

create function myapp.__init__(
    _ text default myapp.__env__()
) returns void as $$
declare
    ns text;
begin
    ns = auth.new_ns(current_setting('auth.namespace', true));

    -- initial users
    perform auth.new_signon('admin', '--admin--', true);
    perform auth.new_signon('test', '--test--', true);

    perform auth.new_config('ui.font', to_jsonb('verdana'::text));
    perform auth.new_config('ui.bgcolor', to_jsonb('#fff'::text));
end;
$$ language plpgsql security definer;


\ir web_signon.sql
