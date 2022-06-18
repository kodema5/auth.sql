-- tracks user's password
--
-- create by:
-- password = crypt('foo', gen_salt('bf'))
--
-- query by:
-- and pwd.password = crypt(v.signon_password, pwd.password)
--
create table if not exists _auth.signon_password (
    id text
        default md5(uuid_generate_v4()::text)
        primary key,

    signon_id text
        references _auth.signon(id)
        on delete cascade
        not null,

    password text
        not null,

    -- when created
    created_tz timestamp with time zone
        default current_timestamp,

    -- when expired
    expired_tz timestamp with time zone
);