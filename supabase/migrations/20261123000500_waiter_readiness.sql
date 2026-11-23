begin;
create function public.rp_waiter_ready(c uuid,r uuid,b jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;o public.rp_orders;rec rp_private.receipts;s text;result jsonb;ver bigint;
begin
 perform 1 from public.rp_cafes where id=c for update;
 m:=rp_private.require_member(c);
 if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 if r is null or b is null or jsonb_typeof(b)<>'object' then raise exception 'INVALID_COMMAND';end if;
 select * into rec from rp_private.receipts where cafe_id=c and request_id=r;
 if found then
  if rec.actor_id<>auth.uid() or rec.action<>'waiter_ready' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;
  return rec.result;
 end if;
 select * into o from public.rp_orders where cafe_id=c and id=(b->>'order_id')::uuid for update;
 if not found then raise exception 'ORDER_NOT_FOUND';end if;
 if m.role='waiter' and o.waiter_id<>auth.uid() then raise exception 'ORDER_NOT_ASSIGNED' using errcode='42501';end if;
 if not exists(select 1 from public.rp_bills where cafe_id=c and id=o.bill_id and status='open') then raise exception 'BILL_CLOSED';end if;
 if b->>'version' is null or o.version<>(b->>'version')::bigint then raise exception 'VERSION_CONFLICT' using errcode='40001';end if;
 if o.status<>'cooking' then raise exception 'INVALID_TRANSITION';end if;
 s:=b->>'station';if s is null or s not in ('kitchen','bar') then raise exception 'INVALID_STATION';end if;
 update public.rp_order_items set ready_at=coalesce(ready_at,clock_timestamp()) where cafe_id=c and order_id=o.id and station=s and cancelled_at is null and served_at is null;
 if not found then raise exception 'NO_STATION_ITEMS';end if;
 update public.rp_orders set version=version+1,
 status=case when not exists(select 1 from public.rp_order_items where cafe_id=c and order_id=o.id and cancelled_at is null and ready_at is null) then 'ready' else status end,
 ready_at=case when not exists(select 1 from public.rp_order_items where cafe_id=c and order_id=o.id and cancelled_at is null and ready_at is null) then clock_timestamp() else ready_at end
 where cafe_id=c and id=o.id returning version into ver;
 insert into public.rp_order_events(cafe_id,order_id,actor_id,event_type,payload,request_id) values(c,o.id,auth.uid(),'waiter_ready',b,r);
 result:=jsonb_build_object('ok',true,'order_id',o.id,'version',ver);
 insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'waiter_ready',b,result);
 return result;
end $$;
revoke all on function public.rp_waiter_ready(uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.rp_waiter_ready(uuid,uuid,jsonb) to authenticated;
commit;
