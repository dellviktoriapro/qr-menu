begin;
create or replace function public.rp_staff_gateway(a text,b jsonb) returns jsonb language sql security invoker set search_path='' as $$select rp_private.staff_link_gateway(a,b)$$;
grant execute on function rp_private.staff_link_gateway(text,jsonb) to service_role;
commit;
