-- tracks various user confirmation
--
create table if not exists _auth.token (
    id text
        default md5(uuid_generate_v4()::text)
        primary key,

    -- 6 digits confirmation
    pin text
        default lpad(floor(random() * 9876543 + 1234)::text, 6, '0'),
        -- alternatively
        -- upper(substr(md5(random()::text), 1,6))

    -- a user-id if available
    signon_id text
        references _auth.signon(id)
            on delete cascade,

    used_tz timestamp with time zone,

    -- when it will be expired
    until_tz timestamp with time zone
        default now() + '5 minutes'::interval,

    data jsonb
        default '{}'::jsonb
);