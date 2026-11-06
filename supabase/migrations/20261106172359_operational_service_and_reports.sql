-- Stage 1 schema/commands. Deliberately CLOSED; enabling grants is a separate reviewed step.
begin;
alter table public.rp_order_items add column served_at timestamptz;
alter table public.rp_order_items add column served_by uuid;
alter table public.rp_order_items add constraint rp_item_server_tenant foreign key(cafe_id,served_by) references public.rp_memberships(cafe_id,user_id);
-- Existing served orders keep their historical service state.
update public.rp_order_items i set served_at=o.served_at,served_by=o.waiter_id from public.rp_orders o where o.cafe_id=i.cafe_id and o.id=i.order_id and o.status='served' and i.cancelled_at is null;

create function rp_private.serve_station(c uuid,r uuid,b jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships; o public.rp_orders; rec rp_private.receipts; result jsonb; s text; ver bigint;
begin
 if r is null or b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>65536 then raise exception 'INVALID_COMMAND';end if;
 perform 1 from public.rp_cafes where id=c for update;
 m:=rp_private.require_member(c);
 if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 select * into rec from rp_private.receipts where cafe_id=c and request_id=r;
 if found then
  if rec.actor_id<>auth.uid() or rec.action<>'serve' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;
  return rec.result;
 end if;
 select * into o from public.rp_orders where cafe_id=c and id=(b->>'order_id')::uuid for update;
 if not found then raise exception 'ORDER_NOT_FOUND';end if;
 if m.role='waiter' and o.waiter_id<>auth.uid() then raise exception 'ORDER_NOT_ASSIGNED' using errcode='42501';end if;
 if not exists(select 1 from public.rp_bills where id=o.bill_id and cafe_id=c and status='open') then raise exception 'BILL_CLOSED';end if;
 if b->>'version' is null or o.version<>(b->>'version')::bigint then raise exception 'VERSION_CONFLICT' using errcode='40001';end if;
 if o.status not in ('cooking','ready') then raise exception 'INVALID_TRANSITION';end if;
 s:=b->>'station';
 if s is null or s not in ('kitchen','bar') then raise exception 'INVALID_STATION';end if;
 if not exists(select 1 from public.rp_order_items where cafe_id=c and order_id=o.id and station=s and cancelled_at is null)
 or exists(select 1 from public.rp_order_items where cafe_id=c and order_id=o.id and station=s and cancelled_at is null and ready_at is null) then raise exception 'STATION_NOT_READY';end if;
 update public.rp_order_items set served_at=coalesce(served_at,clock_timestamp()),served_by=coalesce(served_by,auth.uid()) where cafe_id=c and order_id=o.id and station=s and cancelled_at is null;
 if not exists(select 1 from public.rp_order_items where cafe_id=c and order_id=o.id and cancelled_at is null and served_at is null) then
  update public.rp_orders set status='served',served_at=clock_timestamp() where cafe_id=c and id=o.id;
 end if;
 update public.rp_orders set version=version+1 where cafe_id=c and id=o.id returning version into ver;
 insert into public.rp_order_events(cafe_id,order_id,actor_id,event_type,payload,request_id) values(c,o.id,auth.uid(),'serve',b,r);
 result:=jsonb_build_object('ok',true,'order_id',o.id,'version',ver,'request_id',r);
 insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'serve',b,result);
 return result;
end $$;

create function rp_private.operational_command(c uuid,r uuid,a text,b jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;
begin
 perform 1 from public.rp_cafes where id=c for update;
 m:=rp_private.require_member(c);
 if a='serve' then return rp_private.serve_station(c,r,b);end if;
 if a not in ('order_create','order_edit','send','station_ready','item_ready','bill_close','stop') or a is null then raise exception 'UNKNOWN_COMMAND';end if;
 if a='item_ready' and coalesce((b->>'ready')::boolean,true)=false and exists(select 1 from public.rp_order_items where cafe_id=c and order_id=(b->>'order_id')::uuid and id=(b->>'item_id')::uuid and served_at is not null) then raise exception 'ITEM_ALREADY_SERVED';end if;
 return rp_private.command(c,r,a,b);
end $$;

create function rp_private.owner_stats(c uuid,f timestamptz,t timestamptz) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;result jsonb;
begin
 m:=rp_private.require_member(c);
 if m.role not in ('owner','manager') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 if f is null or t is null or f>=t or t-f>interval '180 days' then raise exception 'INVALID_PERIOD';end if;
 select jsonb_build_object('from',f,'to',t,'orders',count(*),'order_amount',coalesce(sum((select sum(i.quantity*i.unit_price_minor) from public.rp_order_items i where i.cafe_id=c and i.order_id=o.id and i.cancelled_at is null)),0),
 'closed_bills',(select count(*) from public.rp_bills where cafe_id=c and status='closed' and closed_at>=f and closed_at<t),
 'recorded_payments',(select coalesce(sum(case when kind='refund' then -amount_minor else amount_minor end),0) from public.rp_payments where cafe_id=c and recorded_at>=f and recorded_at<t)) into result
 from public.rp_orders o where o.cafe_id=c and o.status<>'cancelled' and o.created_at>=f and o.created_at<t;
 return result;
end $$;
create function public.rp_operational_command(c uuid,r uuid,a text,b jsonb) returns jsonb language sql security invoker set search_path='' as $$select rp_private.operational_command(c,r,a,b)$$;
create function public.rp_owner_stats(c uuid,f timestamptz,t timestamptz) returns jsonb language sql security invoker set search_path='' as $$select rp_private.owner_stats(c,f,t)$$;
revoke all on function rp_private.serve_station(uuid,uuid,jsonb),rp_private.operational_command(uuid,uuid,text,jsonb),rp_private.owner_stats(uuid,timestamptz,timestamptz),public.rp_operational_command(uuid,uuid,text,jsonb),public.rp_owner_stats(uuid,timestamptz,timestamptz) from public,anon,authenticated;
commit;
