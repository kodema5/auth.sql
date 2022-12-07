\if :{?auth_web_signon_sql}
\else
\set auth_web_signon_sql true

create type auth.signon_it as (
    email text,
    password text,
    _uid text,
    _sid text
);

create function auth.signon (
    it auth.signon_it
)
    returns jsonb
    language plpgsql
    security definer
as $$
declare
    usr _auth.user;
begin
    if it._uid is not null
    or it._sid is not null
    then
        raise exception 'auth.signon.existing_session';
    end if;

    select u.*
    into usr
    from _auth.user u
    join _auth.password p on p.user_id = u.id
    where u.email = it.email
        and p.password = crypt(it.password, p.password);

    if not found then
        raise exception 'auth.signon.user_not_found';
    end if;

    return auth.web_session(
        user_id_ := usr.id
    );
end;
$$;

call util.export(array[
    util.web_fn_t('auth.signon(auth.signon_it)')
]);



\if :test
    create function tests.test_auth_web_signon()
        returns setof text
        language plpgsql
    as $$
    declare
        u _auth.user = auth.user('foo@example.com','bar');
        s jsonb;
        a jsonb;
    begin
        s = auth.web_signon(jsonb_build_object(
            'email', 'foo@example.com',
            'password', 'bar'
        ));

        a = auth.auth(s);
        return next ok(a->>'_uid' = u.id, 'able to signon');

        return next throws_ok(
            format('select auth.web_signon(%L::jsonb)',
                s
            ),
            'auth.signon.existing_session'
        );
    end;
    $$;
\endif
\endif