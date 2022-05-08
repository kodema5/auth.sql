-- various environment values
--
create table if not exists _auth.sys (
    id ltree
        primary key
        not null,

    data jsonb not null
);

insert into _auth.sys (id, data)
values
    ('version', jsonb_build_object(
        'version', '0.0.1-alpha'
    )),
    ('session', jsonb_build_object(
        'setting_id', 'session.*'
    ))
on conflict(id) do update
set data = excluded.data;

