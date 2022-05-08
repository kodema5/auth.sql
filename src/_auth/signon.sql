-- user signon
--
create table if not exists _auth.signon (
    -- unique internal id, should not be made public
    id text
        default md5(uuid_generate_v4()::text)
        primary key,

    -- name of user
    name text
        unique
        not null,

    -- role of user
    role text
        default 'user'
        not null,

    -- if user has been activated
    is_active boolean
);
