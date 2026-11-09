-- Guest service requests. No raw client table grants; same capability and fresh membership checks.
begin;
create table rp_private.guest_service_requests(
 id uuid primary key default gen_random_uuid(),cafe_id uuid not null,bill_id uuid not null,visit_id uuid not null references rp_private.guest_visits(id),
 request_id uuid not null,body jsonb not null,created_at timestamptz not null default now(),resolved_at timestamptz,resolved_by uuid,
 foreign key(cafe_id,bill_id) references public.rp_bills(cafe_id,id),foreign key(cafe_id,resolved_by) references public.rp_memberships(cafe_id,user_id),unique(visit_id,request_id));
create index guest_service_bill on rp_private.guest_service_requests(cafe_id,bill_id,created_at) where resolved_at is null;
alter table rp_private.guest_service_requests enable row level security;
revoke all on rp_private.guest_service_requests from public,anon,authenticated;
create function rp_private.guest_service(a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare v rp_private.guest_visits;q rp_private.guest_service_requests;s rp_private.cafe_settings;w public.rp_memberships;ck text;method text;paid boolean;result jsonb;closed boolean;bid uuid;
begin
 if a not in ('context','service') then return rp_private.guest_transport(a,b);end if;
 if b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>4096 or coalesce(b->>'visit_secret','')!~'^[a-f0-9]{64}$' then raise exception 'VISIT_UNAVAILABLE';end if;
 select * into v from rp_private.guest_visits where token_hash=encode(sha256(convert_to(b->>'visit_secret','UTF8')),'hex');if not found then raise exception 'VISIT_UNAVAILABLE';end if;
 perform 1 from public.rp_cafes where id=v.cafe_id and active for update;if not found then raise exception 'VISIT_UNAVAILABLE';end if;
 if v.bill_id is null and v.closed_at is null and v.expires_at>now() then
  select id into bid from public.rp_bills where cafe_id=v.cafe_id and table_id=v.table_id and status='open';if bid is not null then update rp_private.guest_visits set bill_id=bid where id=v.id;v.bill_id:=bid;end if;
 end if;
 closed:=v.closed_at is not null or v.expires_at<=now() or (v.bill_id is not null and not exists(select 1 from public.rp_bills where id=v.bill_id and cafe_id=v.cafe_id and status='open'));
 if a='service' then
  if b->>'request_id' is null then raise exception 'INVALID_REQUEST';end if;
  select * into q from rp_private.guest_service_requests where visit_id=v.id and request_id=(b->>'request_id')::uuid;
  if found then if q.body<>b->'service' then raise exception 'REQUEST_ID_REUSED';end if;return jsonb_build_object('ok',true,'request_id',q.request_id);end if;
  if closed then raise exception 'VISIT_CLOSED';end if;
  method:=b->'service'->>'method';ck:=coalesce(b->'service'->>'check','');paid:=coalesce((b->'service'->>'paid')::boolean,false);
  if method is null or method not in ('cash','card','qr_transfer') or (paid and method<>'qr_transfer') or length(ck)>80 then raise exception 'INVALID_REQUEST';end if;
  if not exists(select 1 from public.rp_orders where cafe_id=v.cafe_id and bill_id=v.bill_id and status<>'cancelled') then raise exception 'NO_ACCEPTED_ORDERS';end if;
  if ck<>'' and not exists(select 1 from public.rp_checks where cafe_id=v.cafe_id and bill_id=v.bill_id and label=ck) then raise exception 'CHECK_UNAVAILABLE';end if;
  if (select count(*) from rp_private.guest_service_requests where visit_id=v.id and created_at>now()-interval '1 minute')>=6 then raise exception 'RATE_LIMIT';end if;
  insert into rp_private.guest_service_requests(cafe_id,bill_id,visit_id,request_id,body) values(v.cafe_id,v.bill_id,v.id,(b->>'request_id')::uuid,b->'service') returning * into q;
  -- A guest statement never creates a payment or closes a bill.
  return jsonb_build_object('ok',true,'request_id',q.request_id);
 end if;
 select * into s from rp_private.cafe_settings where cafe_id=v.cafe_id;
 result:=jsonb_build_object('cafe_id',v.cafe_id,'closed',closed,'reviews',coalesce(s.reviews,'{}'),'stop',coalesce((select jsonb_agg(external_key) from public.rp_menu_items where cafe_id=v.cafe_id and (stopped or not active)),'[]'));
 if closed then return result||'{"checks":[],"total":0,"waiters":[]}';end if;
 result:=result||jsonb_build_object('payment_path',s.payment_path,'checks',coalesce((select jsonb_agg(jsonb_build_object('label',c.label,'sum',coalesce((select sum(i.quantity*i.unit_price_minor) from public.rp_order_items i join public.rp_orders o on o.cafe_id=i.cafe_id and o.id=i.order_id where o.cafe_id=v.cafe_id and o.bill_id=v.bill_id and o.check_id=c.id and o.status<>'cancelled' and i.cancelled_at is null),0))) from public.rp_checks c where c.cafe_id=v.cafe_id and c.bill_id=v.bill_id),'[]'),
 'total',coalesce((select sum(i.quantity*i.unit_price_minor) from public.rp_order_items i join public.rp_orders o on o.cafe_id=i.cafe_id and o.id=i.order_id where o.cafe_id=v.cafe_id and o.bill_id=v.bill_id and o.status<>'cancelled' and i.cancelled_at is null),0),
 'service_pending',exists(select 1 from rp_private.guest_service_requests where visit_id=v.id and resolved_at is null),
 'waiters',coalesce((select jsonb_agg(jsonb_build_object('id',m.user_id,'name',m.display_name,'tip_path',p.tip_path)) from public.rp_memberships m left join rp_private.member_profiles p on p.cafe_id=m.cafe_id and p.user_id=m.user_id where m.cafe_id=v.cafe_id and m.active and exists(select 1 from public.rp_orders o where o.cafe_id=v.cafe_id and o.bill_id=v.bill_id and o.waiter_id=m.user_id and o.status<>'cancelled')),'[]'));
 return result;
end $$;
create function rp_private.guest_services_staff(c uuid,r uuid,a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;q rp_private.guest_service_requests;rec rp_private.receipts;result jsonb;
begin
 if a not in ('services','service_done') then return rp_private.guest_staff(c,r,a,b);end if;
 perform 1 from public.rp_cafes where id=c for update;m:=rp_private.require_member(c);
 if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 if a='services' then return coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'bill_id',s.bill_id,'table',t.label,'created_at',s.created_at,'method',s.body->>'method','check',s.body->>'check','paid',s.body->'paid') order by s.created_at) from rp_private.guest_service_requests s join public.rp_bills b on b.cafe_id=s.cafe_id and b.id=s.bill_id and b.status='open' join public.rp_tables t on t.cafe_id=b.cafe_id and t.id=b.table_id where s.cafe_id=c and s.resolved_at is null),'[]');end if;
 if r is null then raise exception 'REQUEST_ID_REQUIRED';end if;
 select * into rec from rp_private.receipts where cafe_id=c and request_id=r;if found then if rec.actor_id<>auth.uid() or rec.action<>a or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return rec.result;end if;
 select * into q from rp_private.guest_service_requests where cafe_id=c and id=(b->>'service_id')::uuid for update;if not found then raise exception 'REQUEST_UNAVAILABLE';end if;
 if m.role='waiter' and exists(select 1 from public.rp_orders where cafe_id=c and bill_id=q.bill_id and waiter_id<>auth.uid()) then raise exception 'BILL_NOT_ASSIGNED';end if;
 update rp_private.guest_service_requests set resolved_at=coalesce(resolved_at,now()),resolved_by=coalesce(resolved_by,auth.uid()) where id=q.id;
 result:=jsonb_build_object('ok',true,'request_id',r);insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),a,b,result);return result;
end $$;
revoke all on function rp_private.guest_service(text,jsonb),rp_private.guest_services_staff(uuid,uuid,text,jsonb) from public,anon,authenticated;
-- Activate public wrappers only after reviewed guest QR visibility approval.
commit;
