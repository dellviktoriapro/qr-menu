-- Reviewing receipts is reserved to the cafe's active owner membership.
-- Platform administrator emulation in require_member must not bypass this rule.
begin;
create or replace function rp_private.bill_review(c uuid,bill uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships; row_bill public.rp_bills;
begin
 m:=rp_private.require_member(c);
 if not exists(select 1 from public.rp_memberships where cafe_id=c and user_id=auth.uid() and active and role='owner') then
  raise exception 'OWNER_REQUIRED' using errcode='42501';
 end if;
 select * into row_bill from public.rp_bills where cafe_id=c and id=bill for update;
 if not found or row_bill.status<>'closed' then raise exception 'BILL_NOT_CLOSED';end if;
 if row_bill.reviewed_at is null then
  update public.rp_bills set reviewed_at=clock_timestamp(),reviewed_by=auth.uid() where cafe_id=c and id=bill;
 end if;
 return jsonb_build_object('ok',true,'bill_id',bill);
end $$;
do $patch$
declare ddl text;old text;replacement text;
begin
 ddl:=pg_get_functiondef('rp_private.snapshot(uuid)'::regprocedure);
 old:=$old$jsonb_build_object('id',m.user_id,'name',m.display_name,'role',m.role)$old$;
 replacement:=$new$jsonb_build_object('id',m.user_id,'name',m.display_name,'role',m.role,'can_review_bills',exists(select 1 from public.rp_memberships own where own.cafe_id=c and own.user_id=auth.uid() and own.active and own.role='owner'))$new$;
 if position(old in ddl)=0 then raise exception 'SNAPSHOT_ME_CHANGED';end if;
 execute replace(ddl,old,replacement);
end $patch$;
commit;
