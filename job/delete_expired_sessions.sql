---------------------------------------------------------------------------
-- deletes old session

create procedure auth.delete_expired_sessions() as $$
declare
    n int;
begin
    delete from auth.session
    where last_accessed_tz < current_timestamp - (interval '1 hour');

    get diagnostics n = row_count;
    call auth.log(format('deleted %s expired sessions', n));
end;
$$ language plpgsql;

---------------------------------------------------------------------------
-- at minute 1 minute (of every hour)

select cron.schedule(
    'auth.delete_expired_sessions',
    '1 * * * *',
    'call auth.delete_expired_sessions()'
);



