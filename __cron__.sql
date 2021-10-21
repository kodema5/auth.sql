create procedure auth.__cron__() as $$
begin

    -- cleanup expired after 1-hr inactive session
    --
    raise warning 'scheduling auth.delete_expired_sessions';
    perform cron.schedule(
        'auth.delete_expired_sessions',
        '1 * * * *',
        'call auth.delete_expired_sessions()'
    );

end;
$$ language plpgsql;
