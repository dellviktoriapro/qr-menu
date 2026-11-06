-- Only these membership/role-checked RPCs. No raw table access, no anonymous access.
begin;
grant usage on schema rp_private to authenticated;
grant execute on function public.rp_my_cafes(),public.rp_operational_snapshot(uuid),public.rp_operational_command(uuid,uuid,text,jsonb),public.rp_owner_stats(uuid,timestamptz,timestamptz) to authenticated;
grant execute on function rp_private.my_cafes(),rp_private.operational_snapshot(uuid),rp_private.operational_command(uuid,uuid,text,jsonb),rp_private.owner_stats(uuid,timestamptz,timestamptz) to authenticated;
commit;
select has_function_privilege('anon','public.rp_operational_snapshot(uuid)','execute') as anonymous_read,
 has_function_privilege('authenticated','public.rp_operational_snapshot(uuid)','execute') as staff_read,
 has_table_privilege('authenticated','public.rp_orders','select') as direct_orders;
