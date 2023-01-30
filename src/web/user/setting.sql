drop type if exists web.user_setting_it cascade;
create type web.user_setting_it as (
    delete text[],
    set jsonb, -- {setting_id: value}
    get text[]
);


create or replace function web.user_setting (
    it web.user_setting_it
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    uid text = util.get_config('session.user_id');
begin
    if uid=''
    then
        raise exception 'web.user_setting.unrecognized_user';
    end if;

    perform setting.user(
        uid,
        set_ => it.set,
        delete_ => it.delete
    );

    if not (it.get is null)
    then
        return jsonb_object_agg(a.key, a.value)
            from setting.get(
                it.get, -- setting_ids
                (select templates from user_.user where id=uid),
                uid
            ) a;
    end if;

    return null;
end;
$$;

create or replace function web.user_setting (
    it jsonb
)
    returns jsonb
    language sql
    security definer
as $$
    select web.user_setting(jsonb_populate_record(
        null::web.user_setting_it,
        session.auth(it)
    ))
$$;


\if :test
    create function tests.test_web_user_setting()
        returns setof text
        language plpgsql
    as $$
    declare
        u user_.user = "user".new(
            'foo@example.com',
            'bar',
            templates_ => array['template']::text[]
        );
        s jsonb = session.head(u.id);
        req jsonb;
        res jsonb;
    begin

        perform setting.setting(
            set_ => array[
                ('foo', 'foo-desc', '111'),
                ('bar', 'bar-desc', '222'),
                ('baz', 'baz-desc', '333')
            ]::setting_.setting[]
        );

        perform setting.template(
            set_ => array[
                ('bar', 'template', '2222'),
                ('bar', 'template2', '2000')
            ]::setting_.template[]
        );

        res = web.user_setting(s || jsonb_build_object(
            'set', jsonb_build_object(
                'foo', 11111,
                'bar', 22222,
                'baz', 33333
            )
        ));

        res = web.user_setting(s || jsonb_build_object(
            'delete', array['foo', 'bar']
        ));

        res = web.user_setting(s || jsonb_build_object(
            'get', array['foo', 'bar', 'baz']
        ));

        return next ok(
            res->>'foo' = '111' -- from setting
            and res->>'bar' = '2222' -- from template
            and res->>'baz' = '33333' -- from user
        , 'able to set/delete/get settings');

        perform session.end();
    end;
    $$;
\endif


