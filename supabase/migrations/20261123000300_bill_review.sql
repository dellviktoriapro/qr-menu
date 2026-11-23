-- Review acknowledges a paid bill; it never removes the bill or its analytics.
begin;
alter table public.rp_bills add column if not exists reviewed_at timestamptz;
alter table public.rp_bills add column if not exists reviewed_by uuid references auth.users(id);
create or replace function rp_private.snapshot(c uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships; result jsonb;
begin
 m:=rp_private.require_member(c);
 select jsonb_build_object(
 'cafe',(select jsonb_build_object('id',id,'name',name,'currency',currency,'timezone',timezone) from public.rp_cafes where id=c),
 'me',jsonb_build_object('id',m.user_id,'name',m.display_name,'role',m.role),
 'staff',coalesce((select jsonb_agg(jsonb_build_object('id',user_id,'name',display_name,'role',role,'active',active)) from public.rp_memberships where cafe_id=c),'[]'),
 'tables',coalesce((select jsonb_agg(to_jsonb(t)) from public.rp_tables t where cafe_id=c and active),'[]'),
 'menu',coalesce((select jsonb_agg(to_jsonb(t)) from public.rp_menu_items t where cafe_id=c),'[]'),
 'bills',coalesce((select jsonb_agg(to_jsonb(t)) from public.rp_bills t where cafe_id=c and (status='open' or closed_at>now()-interval '1 day' or reviewed_at is null)),'[]'),
 'checks',coalesce((select jsonb_agg(to_jsonb(t)) from public.rp_checks t join public.rp_bills b on b.cafe_id=t.cafe_id and b.id=t.bill_id where t.cafe_id=c and (b.status='open' or (b.closed_at>now()-interval '1 day' or b.reviewed_at is null))),'[]'),
 'orders',coalesce((select jsonb_agg(to_jsonb(t)||jsonb_build_object('items',coalesce((select jsonb_agg(to_jsonb(i) order by i.id) from public.rp_order_items i where i.cafe_id=c and i.order_id=t.id),'[]'))) from public.rp_orders t join public.rp_bills b on b.id=t.bill_id and b.cafe_id=t.cafe_id where t.cafe_id=c and (b.status='open' or (b.closed_at>now()-interval '1 day' or b.reviewed_at is null))),'[]'),
 'server_at',clock_timestamp()) into result;
 return result;
end $$;

create or replace function rp_private.bill_review(c uuid,bill uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships; row_bill public.rp_bills;
begin
 m:=rp_private.require_member(c);
 if m.role<>'owner' then raise exception 'OWNER_REQUIRED' using errcode='42501'; end if;
 select * into row_bill from public.rp_bills where cafe_id=c and id=bill for update;
 if not found or row_bill.status<>'closed' then raise exception 'BILL_NOT_CLOSED'; end if;
 if row_bill.reviewed_at is null then
  update public.rp_bills set reviewed_at=clock_timestamp(),reviewed_by=auth.uid()
  where cafe_id=c and id=bill;
 end if;
 return jsonb_build_object('ok',true,'bill_id',bill);
end $$;
create or replace function public.rp_bill_review(c uuid,bill uuid) returns jsonb
language sql security invoker set search_path='' as $$select rp_private.bill_review(c,bill)$$;
revoke all on function rp_private.bill_review(uuid,uuid),public.rp_bill_review(uuid,uuid) from public,anon,authenticated;
grant execute on function rp_private.bill_review(uuid,uuid),public.rp_bill_review(uuid,uuid) to authenticated;
commit;

