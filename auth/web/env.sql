\if :{?auth_web_env_sql}
\else
\set auth_web_env_sql true

create function auth.web_env(jsonb)
    returns jsonb
    language plpgsql
    security definer
    strict
    set search_path=auth, public
as $$
declare
    req jsonb = request_t($1);
    env env_t = env_t();
begin
    return response_t(env);
end;
$$;


\endif
