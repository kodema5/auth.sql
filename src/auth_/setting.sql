create table if not exists auth_.setting (
    key ltree primary key not null,
    value jsonb
);



create table if not exists auth_.setting_namespace (
    ns_id text references auth_.namespace(id) on delete cascade,
    key ltree references auth_.setting(key) on delete cascade,
    value jsonb,
    unique (ns_id, key)
);


create table if not exists auth_.setting_user (
    user_id text references auth_.user(id) on delete cascade,
    key ltree references auth_.setting(key) on delete cascade,
    value jsonb,
    unique (user_id, key)
);
