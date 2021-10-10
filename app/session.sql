------------------------------------------------------------------------------

alter table auth.SESSION
    add column created_tz timestamp with time zone default current_timestamp,
    add column last_accessed_tz timestamp with time zone default current_timestamp;

------------------------------------------------------------------------------