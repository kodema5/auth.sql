create table if not exists auth_.userdata (
    user_id text not null references auth_.user(id) on delete cascade,
    key ltree not null,
    unique(user_id, key),
    value jsonb
);
