-- Review/delete are queue acknowledgements, never physical financial deletion.
begin;
alter table public.rp_bills add column if not exists deleted_at timestamptz;
alter table public.rp_bills add column if not exists deleted_by uuid references auth.users(id);
create or replace function rp_private.can_review_bills(c uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and (
 exists(select 1 from public.rp_memberships m where m.cafe_id=c and m.user_id=auth.uid() and m.active and m.role='owner')
 or exists(select 1 from rp_private.platform_admins a join auth.users u on u.id=a.user_id where a.user_id=auth.uid() and a.active and u.email_confirmed_at is not null and u.deleted_at is null))
$$;
revoke all on function rp_private.can_review_bills(uuid) from public,anon,authenticated;
create or replace function rp_private.bill_queue_action(c uuid, bill_ids uuid[], queue_action text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare ids uuid[]; row_bill public.rp_bills; n integer:=0;
begin
 perform rp_private.require_member(c);
 if not rp_private.can_review_bills(c) then raise exception 'OWNER_REQUIRED' using errcode='42501';end if;
 if queue_action is null or queue_action not in ('review','delete','restore') then raise exception 'INVALID_ACTION';end if;
 if bill_ids is null or cardinality(bill_ids) not between 1 and 500 or array_position(bill_ids,null) is not null then raise exception 'INVALID_BILLS';end if;
 select array_agg(distinct x) into ids from unnest(bill_ids) x;
 -- Validate every target before changing anything. Stable lock order avoids deadlocks.
 for row_bill in select * from public.rp_bills where cafe_id=c and id=any(ids) order by id for update loop
  if row_bill.status<>'closed' then raise exception 'BILL_NOT_CLOSED';end if;
  n:=n+1;
 end loop;
 if n<>cardinality(ids) then raise exception 'BILL_NOT_FOUND';end if;
 if queue_action='review' then
  update public.rp_bills set reviewed_at=coalesce(reviewed_at,clock_timestamp()),reviewed_by=coalesce(reviewed_by,auth.uid()) where cafe_id=c and id=any(ids);
 elsif queue_action='delete' then
  update public.rp_bills set deleted_at=coalesce(deleted_at,clock_timestamp()),deleted_by=coalesce(deleted_by,auth.uid()) where cafe_id=c and id=any(ids);
 else
  update public.rp_bills set deleted_at=null,deleted_by=null where cafe_id=c and id=any(ids);
 end if;
 return jsonb_build_object('ok',true,'count',n,'action',queue_action);
end $$;
create or replace function public.rp_bill_queue_action(c uuid,bill_ids uuid[],queue_action text) returns jsonb
language sql security invoker set search_path='' as $$select rp_private.bill_queue_action(c,bill_ids,queue_action)$$;
revoke all on function rp_private.bill_queue_action(uuid,uuid[],text),public.rp_bill_queue_action(uuid,uuid[],text) from public,anon,authenticated;
grant execute on function rp_private.bill_queue_action(uuid,uuid[],text),public.rp_bill_queue_action(uuid,uuid[],text) to authenticated;
create or replace function rp_private.bill_review(c uuid,bill uuid) returns jsonb
language sql security definer set search_path='' as $$select rp_private.bill_queue_action(c,array[bill],'review')$$;
-- Keep the complete existing snapshot, only replace its capability predicate.
do $patch$
declare ddl text; old text;
begin
 ddl:=pg_get_functiondef('rp_private.snapshot(uuid)'::regprocedure);
 old:=$old$exists(select 1 from public.rp_memberships own where own.cafe_id=c and own.user_id=auth.uid() and own.active and own.role='owner')$old$;
 if position(old in ddl)=0 then raise exception 'SNAPSHOT_ME_CHANGED';end if;
 execute replace(ddl,old,'rp_private.can_review_bills(c)');
end $patch$;
commit;
