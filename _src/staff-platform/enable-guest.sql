-- Reviewed activation ONLY after explicit public guest endpoint approval.
begin;
grant execute on function public.rp_guest_transport(text,jsonb),rp_private.guest_transport(text,jsonb) to service_role;
grant execute on function public.rp_guest_staff(uuid,uuid,text,jsonb),rp_private.guest_staff(uuid,uuid,text,jsonb) to authenticated;
commit;
