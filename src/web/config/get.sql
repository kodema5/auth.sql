
drop type if exists web.config_get_it cascade;
create type web.config_get_it as (
    ids text[],
    templates text[]
);

create or replace function web.config_get(
    it web.config_get_it
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    uid text = util.get_config('session.user_id');
begin
    if uid = ''
    then
        raise exception 'web.config_get.user_not_found';
    end if;

    return jsonb_object_agg(a.id, a.value)
        from config.get((
            coalesce(
                it.ids,
                (select array_agg(id)
                from config_.config)),
            coalesce(
                it.templates,
                (select templates
                from user_.user
                where id=uid)),
            uid
        )::config.get_it) as a;
end;
$$;


create or replace function web.config_get (
    it jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select web.config_get(jsonb_populate_record(
        null::web.config_get_it,
        session.auth(it)
    ))
$$;

\if :test
    create function tests.test_web_config_get()
        returns setof text
        language plpgsql
    as $$
    declare
        u user_.user = "user".new(
            'foo@example.com',
            'bar',
            templates_ => array['template']::text[]
        );
        s session_.session = session.new(u.id);
        d config.data_it;
        g config.get_it;
        res jsonb;
    begin
        -- for configuration
        d.set = array[
            ('foo', 'foo-desc', '111'),
            ('bar', 'bar-desc', '222'),
            ('baz', 'baz-desc', '333')
        ];
        perform config.set_config(d);

        -- for template
        d.set = array[
            ('bar', 'template', '2222'),
            ('bar', 'template2', '2000')
        ];
        perform config.set_template(d);

        -- for user
        d.set = array[
            ('foo', u.id, '11111')
        ];
        perform config.set_user(d);

        res = web.config_get(jsonb_build_object(
            '_headers', jsonb_build_object(
                'authorization', s.id
            ) -- ,
            -- 'ids', array['foo', 'bar', 'baz']::text[] -- ,
            -- 'templates', array['template']::text[]
        ));
        return next ok(
            res->>'foo' = '11111' -- from user
            and res->>'bar' = '2222' -- from template
            and res->>'baz' = '333' -- from config
            ,
            'can retrieve user specific config');

        perform session.end();
    end;
    $$;
\endif