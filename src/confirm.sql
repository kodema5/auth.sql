\if :{?confirm_sql}
\else
\set confirm_sql true

\ir util/export.web_fn_t.sqL

\if :test
\if :local
drop schema if exists _confirm cascade;
\endif
\endif
create schema if not exists _confirm;

drop schema if exists confirm cascade;
create schema confirm;

-- confirmation id is associated with calling a confirm_f
--
create table if not exists _confirm.confirm (
    id text
        default md5(gen_random_uuid()::text)
        primary key,
    code text
        default lpad(floor(random() * 9876543 + 1234)::text, 6, '0'),
        -- default left(md5(gen_random_uuid()::text), 8),

    created_tz timestamp with time zone
        default current_timestamp,
    expired_tz timestamp with time zone
        default current_timestamp + '10 mins'::interval,

    confirmed_tz timestamp with time zone,
    confirm_f text
        check (to_regproc(confirm_f) is not null),
    context_t text
        check (to_regtype(context_t) is not null),
    context jsonb not null
);

create type confirm.confirm_t as (
    id text,
    code text
);

create function confirm.confirm (
    confirm_f_ regproc,
    context_t_ regtype,
    context_ jsonb,
    code_ text
        default lpad(floor(random() * 9876543 + 1234)::text, 6, '0'),
    expired_tz_ timestamp with time zone
        default current_timestamp + '10 mins'::interval
)
    returns confirm.confirm_t
    language sql
    security definer
as $$
    with
    inserted as (
        insert into _confirm.confirm (
            context,
            confirm_f,
            context_t,
            code,
            expired_tz
        ) values (
            context_,
            confirm_f_,
            context_t_,
            code_,
            expired_tz_
        )
        returning *
    )
    select (id, code)::confirm.confirm_t
    from inserted
$$;

create function confirm.confirm (
    id_ text
)
    returns confirm.confirm_t
    language sql
    security definer
as $$
    select (id, code)::confirm.confirm_t
    from _confirm.confirm
    where id=id_
$$;


create function confirm.confirm (
    it confirm.confirm_t
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    r _confirm.confirm;
    a jsonb;
begin
    select *
    into r
    from _confirm.confirm c
    where
        id = it.id
        and (code is null or code=it.code)
        and expired_tz >= current_timestamp
        and confirmed_tz is null;
    if not found then
        raise exception 'confirm.confirm.record_not_found';
    end if;

    begin
        execute format(
            'select to_jsonb(%s(jsonb_populate_record('
                'null::%s, %L::jsonb'
            ')))',
            r.confirm_f,
            r.context_t,
            r.context
        ) into a;
    exception
        when others then
        raise warning 'confirm.confirm.error_on_callback %', sqlerrm;
        raise exception 'confirm.confirm.error_on_callback';
    end;

    update _confirm.confirm
    set confirmed_tz = current_timestamp
    where id = it.id;

    return a;
end;
$$;

call util.export(array[
    util.web_fn_t('confirm.confirm(confirm.confirm_t)')
]);


\if :test
    create type tests.confirm_callback_it as (
        a text,
        b text
    );
    create function tests.confirm_callback(
        it tests.confirm_callback_it
    )
        returns jsonb
        language sql
    as $$
        select to_jsonb(it) || '{"c":123}'::jsonb;
    $$;

    create function tests.test_confirm_web_confirm ()
        returns setof text
        language plpgsql
    as $$
    declare
        c confirm.confirm_t;
        a jsonb;
    begin
        c = confirm.confirm(
            confirm_f_ := 'tests.confirm_callback',
            context_t_ := 'tests.confirm_callback_it',
            context_ := '{"a":"foo","b":"foo"}',
            code_ := '0000'
        );
        return next ok(c.id is not null, 'has confirmation id');
        return next ok(c.code = '0000', 'has confirmation code');

        a = confirm.confirm(c);
        return next ok(a->>'a' = 'foo', 'able to confirm with code');


        -- to simulate link only access (no code needed)
        c = confirm.confirm(
            confirm_f_ := 'tests.confirm_callback',
            context_t_ := 'tests.confirm_callback_it',
            context_ := '{"a":"bar","b":"bar"}',
            code_ := null::text -- no code needed to access
        );
        return next ok(c.id is not null, 'has confirmation id');
        return next ok(c.code is null, 'has no confirmation code');

        a = confirm.confirm(c);
        return next ok(a->>'a' = 'bar', 'able to confirm without code');


        return next throws_ok(
            format('select confirm.web_confirm(%L::jsonb)',
                jsonb_build_object('id', '--', 'code', '--')
            ),
            'confirm.confirm.record_not_found'
        );
    end;
    $$;
\endif

\endif