-- setting tracks state values of user

create table if not exists _auth.setting (
    id ltree
        primary key
        not null,

    description text
        not null,

    value jsonb
);


create table if not exists _auth.setting_template (
    setting_id ltree
        references _auth.setting(id)
        on delete cascade,

    id ltree        -- ex: brand for brand-default
        not null,   -- and brand.role for specified role
                    -- 'brand.role{0,1}'::lquery can retrieve both
                    -- then order by nlevel(id) desc limit 1
    value jsonb,

    unique (setting_id, id)
);


create table if not exists _auth.setting_signon (
    setting_id ltree
        references _auth.setting(id)
        on delete cascade,

    signon_id text
        references _auth.signon(id)
        on delete cascade,

    value jsonb,

    unique (setting_id, signon_id)
);


