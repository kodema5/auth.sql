\if :{?auth_web_storage_sql}
\else
\set auth_web_storage_sql true

create type auth.storage_data_it as (
    remove text[],
    set jsonb,
    get text[]
);

create type auth.storage_data_t as (
    remove text[],
    set text[],
    get jsonb,
    keys text[]
);


-- for user-storage
--
create function auth.user_storage (
    user_id_ text,
    it auth.storage_data_it
)
    returns auth.storage_data_t
    language plpgsql
    security definer
as $$
declare
    t auth.storage_data_t;
begin
    if not (it.remove is null)
    then
        with
        removed as (
            delete from _auth.user_storage
            where user_id = user_id_
            and key = any(it.remove)
            returning key
        )
        select array_agg(key)
        into t.remove
        from removed;
    end if;

    if not (it.set is null)
    then
        with
        inserted as (
            insert into _auth.user_storage
                (user_id, key, value)
                select user_id_, a.key, a.value
                from jsonb_each(it.set) a
            on conflict (user_id, key)
            do update set
                value = excluded.value
            returning key
        )
        select array_agg(key)
        into t.set
        from inserted;
    end if;

    if not (it.get is null)
    then
        select jsonb_object_agg(key, value)
        into t.get
        from _auth.user_storage
        where user_id = user_id_
        and key=any(it.get);
    end if;

    select array_agg(key)
    into t.keys
    from (select key
        from _auth.user_storage
        where user_id = user_id_
        order by key
    ) t;

    return t;
end;
$$;

-- session storage
--
create function auth.session_storage (
    session_id_ text,
    it auth.storage_data_it
)
    returns auth.storage_data_t
    language plpgsql
    security definer
as $$
declare
    t auth.storage_data_t;
begin
    if not (it.remove is null)
    then
        with
        removed as (
            delete from _auth.session_storage
            where session_id = session_id_
            and key = any(it.remove)
            returning key
        )
        select array_agg(key)
        into t.remove
        from removed;
    end if;

    if not (it.set is null)
    then
        with
        inserted as (
            insert into _auth.session_storage
                (session_id, key, value)
                select session_id_, a.key, a.value
                from jsonb_each(it.set) a
            on conflict (session_id, key)
            do update set
                value = excluded.value
            returning key
        )
        select array_agg(key)
        into t.set
        from inserted;
    end if;

    if not (it.get is null)
    then
        select jsonb_object_agg(key, value)
        into t.get
        from _auth.session_storage
        where session_id = session_id_
        and key=any(it.get);
    end if;

    select array_agg(key)
    into t.keys
    from (select key
        from _auth.session_storage
        where session_id = session_id_
        order by key
    ) t;

    return t;
end;
$$;


create type auth.storage_it as (
    session auth.storage_data_it,
    "user" auth.storage_data_it,
    _uid text,
    _sid text
);

create type auth.storage_t as (
    session auth.storage_data_t,
    "user" auth.storage_data_t
);

create function auth.storage (
    it auth.storage_it
)
    returns auth.storage_t
    language plpgsql
    security definer
as $$
declare
    t auth.storage_t;
begin
    if not (it.user is null)
    then
        t.user = auth.user_storage(
            it._uid,
            it.user
        );
    end if;


    if not (it.session is null)
    then
        t.session = auth.session_storage(
            it._sid,
            it.session
        );
    end if;

    return t;
end;
$$;


call util.export(array[
    util.web_fn_t('auth.storage(auth.storage_it)')
]);


\if :test
    create function tests.test_auth_web_storage()
        returns setof text
        language plpgsql
    as $$
    declare
        u _auth.user = auth.user('foo@example.com','bar');
        it auth.storage_it;
        t auth.storage_t;
    begin
        it._uid = u.id;
        it._sid = auth.session(u.id);

        it.user.set = jsonb_build_object('foo', 111, 'bar', 222, 'baz', 333);
        it.user.get = array['bar', 'baz', 'bbb'];
        t = auth.storage(it);
        return next ok(
            (t.user).keys = array['bar', 'baz', 'foo'],
            'stored user keys'
        );

        it.user.set = jsonb_build_object('bbb', 444);
        it.user.get = null;
        it.user.remove = array['baz', 'not-a-key'];
        t = auth.storage(it);

        return next ok(
            (t.user).keys = array['bar', 'bbb', 'foo'],
            'updated user keys'
        );

        it.user = null;

        it.session.set = jsonb_build_object('foo', 111, 'bar', 222, 'baz', 333);
        it.session.get = array['bar', 'baz', 'bbb'];
        t = auth.storage(it);
        return next ok(
            (t.session).keys = array['bar', 'baz', 'foo'],
            'stored session keys'
        );

        it.session.set = jsonb_build_object('bbb', 444);
        it.session.get = null;
        it.session.remove = array['baz', 'not-a-key'];
        t = auth.storage(it);

        return next ok(
            (t.session).keys = array['bar', 'bbb', 'foo'],
            'updated session keys'
        );
    end;
    $$;
\endif

\endif