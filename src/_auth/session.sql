-- tracks user-access session
--
create table if not exists _auth.session (
    -- unique public id
    id text
        default md5(uuid_generate_v4()::text)
        primary key,

    -- session for
    signon_id text
        references _auth.signon(id)
        on delete cascade
        not null,

    -- a session data
    data jsonb,

    -- if id authenticated
    authenticated boolean
        default false,

    -- ip of signon, to be checked for subsequent call
    -- to prevent session hijacking
    origin text,

    -- when user signed-off
    signed_off_tz timestamp with time zone,

    -- when system expired it
    expired_tz timestamp with time zone
);

