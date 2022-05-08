-- tracks various user confirmation
-- TODO
--
create table if not exists _auth.confirmation (
    id text
        default md5(uuid_generate_v4()::text)
        primary key,

    -- the pin that user needs to enter
    pin int,

    signon_id text
        references _auth.signon(id)
            on delete cascade
        not null,

    -- type of confirmation, ex: account_activation
    type text
        not null,

    -- helper data in confirmation
    data jsonb
        default '{}'::jsonb,

    confirmed_tz timestamp with time zone,

    -- when it will be expired
    until_tz timestamp with time zone
);