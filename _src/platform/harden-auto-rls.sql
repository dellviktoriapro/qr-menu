-- Dashboard-created event-trigger function needs no direct API callers.
-- Revoke only direct EXECUTE; leave event trigger and automatic RLS enabled.
begin;
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
commit;
select has_function_privilege('anon','public.rls_auto_enable()','EXECUTE') as anon_execute,
       has_function_privilege('authenticated','public.rls_auto_enable()','EXECUTE') as authenticated_execute;
