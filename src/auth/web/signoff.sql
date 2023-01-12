\if :{?auth_web_signoff_sql}
\else
\set auth_web_signoff_sql true

create type auth.signoff_it as (
    _sid text
);

create function auth.signoff (
    it auth.signoff_it
)
    returns boolean
    language plpgsql
    security definer
as $$
declare
    usr _auth.user;
begin
    if it._sid is null
    then
        raise exception 'auth.signoff.unrecognized_session';
    end if;

    delete from _auth.session
    where id = it._sid;

    if not found then
        raise exception 'auth.signoff.unrecognized_session';
    end if;

    return true;
end;
$$;

call util.export(array[
    util.web_fn_t('auth.signoff(auth.signoff_it)')
]);


\if :test
    create function tests.test_auth_web_signoff()
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

        a = auth.web_signoff(s);
        return next ok(a::text = 'true', 'able to signoff');

        return next throws_ok(
            format('select auth.web_signoff(%L::jsonb)',
                '{}'
            ),
            'auth.signoff.unrecognized_session'
        );
    end;
    $$;
\endif
\endif