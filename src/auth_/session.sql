
create table if not exists auth_.session (
    id text not null default md5(uuid_generate_v4()::text) primary key,
    user_id text references auth_.user(id) on delete cascade
);

alter table auth_.session
    add column if not exists created_tz timestamp with time zone default now();

alter table auth_.session
    add column if not exists accessed_tz timestamp with time zone;