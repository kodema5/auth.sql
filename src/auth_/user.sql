create table if not exists auth_.user (
    id text default md5(uuid_generate_v4()::text) primary key,
    ns_id text default 'dev' references auth_.namespace(id) on delete cascade,

    signon_id text not null,
    signon_key text not null,
    unique (ns_id, signon_id),

    role text default 'user' check (role in ('system', 'admin', 'user'))
);
