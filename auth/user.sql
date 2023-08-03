\if :{?auth_user_sql}
\else
\set auth_user_sql true
-- accesses auth_.user

\ir service.sql
    create function auth.user(id text)
        returns auth_.user
        language sql
        security definer
        stable
    as $$
        select *
        from auth_.user
        where user_id = id
    $$;

    comment on function auth.user(text)
        is 'returns a user of a user-id';


    create function auth.user(jsonb)
        returns auth_.user
        language sql
        security definer
        stable
    as $$
        select jsonb_populate_record(
            null::auth_.user,
            coalesce(to_jsonb(auth.user($1->>'user_id')), '{}') ||
            $1
        )
    $$;

    create function auth.user(ses auth_.session)
        returns auth_.user
        language sql
        security definer
        stable
    as $$
        select *
        from auth_.user
        where user_id = ses.user_id
    $$;

    comment on function auth.user(auth_.session)
        is 'returns a user of a session';


    create function auth.user(brand_id_ text, name_ text, password_ text)
        returns auth_.user
        language sql
        security definer
        stable
    as $$
        select u.*
        from auth_.user u
        join auth_.user_ p on p.user_id = u.user_id
        where u.brand_id = brand_id_
        and u.name = name_
        and p.password = crypt(password_, p.password)
    $$;

    comment on function auth.user(text, text, text)
        is 'returns a user of a brand with user name and password';


    create function auth.set(auth_.user)
        returns auth_.user
        language sql
        security definer
    as $$
        insert into auth_.user (brand_id, name, user_type_id, data, services)
        values (
            $1.brand_id,
            $1.name,
            $1.user_type_id,
            $1.data,
            coalesce(auth.intersect(
                $1.services,
                auth.service_ids() ),
                '{}')
        )
        on conflict (brand_id, name)
        do update set
            user_type_id = excluded.user_type_id,
            data = excluded.data,
            services = excluded.services
        returning *
    $$;


    create function auth.delete(auth_.user)
        returns auth_.user
        language sql
        security definer
    as $$
        delete from auth_.user
        where user_id = $1.user_id
        returning *
    $$;


    create function auth.user_(id text)
        returns auth_.user_
        language sql
        security definer
        stable
    as $$
        select *
        from auth_.user_
        where user_id = id
    $$;


    create function auth.user_(jsonb)
        returns auth_.user_
        language sql
        security definer
        stable
    as $$
        select jsonb_populate_record(
            null::auth_.user_,
            coalesce(to_jsonb(auth.user_($1->>'user_id')), '{}') ||
            $1
        )
    $$;


    create function auth.set(auth_.user_)
        returns auth_.user_
        language sql
        security definer
    as $$
        insert into auth_.user_ (user_id, password, email)
        values (
            $1.user_id,
            crypt($1.password, gen_salt('bf')),
            $1.email
        )
        on conflict (user_id)
        do update set
            password = excluded.password,
            email = excluded.email
        returning *
    $$;

\endif
