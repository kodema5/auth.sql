\if :{?auth_web_config_sql}
\else
\set auth_web_config_sql true

create type auth.config_id_t as (
    id text,
    name text
);

create type auth.config_item_t as (
    id text,
    name text,
    value jsonb
);

create type auth.config_data_it as (
    remove auth.config_id_t[],
    set auth.config_item_t[],
    get auth.config_id_t[]
);

create type auth.config_data_t as (
    remove auth.config_id_t[],
    set auth.config_id_t[],
    get auth.config_item_t[]
);


\ir config/config.sql
\ir config/config_template.sql
\ir config/config_user.sql


create type auth.config_get_it as (
    ids text[],
    templates text[],
    user_id text
);

\ir config/get_config.sql

create type auth.config_it as (
    config auth.config_data_it,
    config_template auth.config_data_it,
    config_user auth.config_data_it,

    get_config auth.config_get_it,

    _uid text,
    _role text
);

create type auth.config_t as (
    config auth.config_data_t,
    config_template auth.config_data_t,
    config_user auth.config_data_t,
    get_config jsonb,

    _uid text
);

create function auth.config (
    it auth.config_it
)
    returns auth.config_t
    language plpgsql
    security definer
as $$
declare
    t auth.config_t;
begin
    if not (it.config is null)
    then
        t.config = auth.config(it.config);
    end if;

    if not (it.config_template is null)
    then
        t.config_template = auth.config_template(it.config_template);
    end if;

    if not (it.config_user is null)
    then
        t.config_user = auth.config_user(it.config_user);
    end if;

    if not (it.get_config is null)
    then
        t.get_config = jsonb_object_agg(a.id, a.value)
            from auth.get_config(it.get_config) a;
    end if;

    return t;
end;
$$;

call util.export(array[
    util.web_fn_t('auth.config(auth.config_it)')
]);


\if :test
    create function tests.test_auth_web_config()
        returns setof text
        language plpgsql
        security definer
    as $$
    declare
        u _auth.user = auth.user('foo@example.com', 'bar');

        d auth.config_data_it;
        g auth.config_get_it;
        it auth.config_it;
        t auth.config_t;
    begin
        -- for configuration
        d.set = array[
            ('foo', 'foo-desc', '111'),
            ('bar', 'bar-desc', '222'),
            ('baz', 'baz-desc', '333')
        ];
        it.config = d;

        -- for template
        d.set = array[
            ('bar', 'template', '2222'),
            ('bar', 'template2', '2000')
        ];
        it.config_template = d;

        -- for user
        d.set = array[
            ('foo', u.id, '11111')
        ];
        it.config_user = d;


        g.ids = array['foo', 'bar', 'baz']::text[];
        g.templates = array['template']::text[];
        g.user_id = u.id;
        it.get_config = g;

        it._uid = u.id;
        t = auth.config(it);

        return next ok(
            t.get_config->>'foo' = '11111' -- from user
            and t.get_config->>'bar' = '2222' -- from template
            and t.get_config->>'baz' = '333' -- from default config
        , 'able to get config');
    end;
    $$;
\endif

\endif