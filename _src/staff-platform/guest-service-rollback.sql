begin;
-- Guest service requests. No raw client table grants; same capability and fresh membership checks.

create table rp_private.guest_service_requests(
 id uuid primary key default gen_random_uuid(),cafe_id uuid not null,bill_id uuid not null,visit_id uuid not null references rp_private.guest_visits(id),
 request_id uuid not null,body jsonb not null,created_at timestamptz not null default now(),resolved_at timestamptz,resolved_by uuid,
 foreign key(cafe_id,bill_id) references public.rp_bills(cafe_id,id),foreign key(cafe_id,resolved_by) references public.rp_memberships(cafe_id,user_id),unique(visit_id,request_id));
create index guest_service_bill on rp_private.guest_service_requests(cafe_id,bill_id,created_at) where resolved_at is null;
alter table rp_private.guest_service_requests enable row level security;
revoke all on rp_private.guest_service_requests from public,anon,authenticated;
create function rp_private.guest_service(a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare v rp_private.guest_visits;q rp_private.guest_service_requests;s rp_private.cafe_settings;w public.rp_memberships;ck text;method text;paid boolean;result jsonb;closed boolean;
begin
 if a not in ('context','service') then return rp_private.guest_transport(a,b);end if;
 if b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>4096 or coalesce(b->>'visit_secret','')!~'^[a-f0-9]{64}$' then raise exception 'VISIT_UNAVAILABLE';end if;
 select * into v from rp_private.guest_visits where token_hash=encode(sha256(convert_to(b->>'visit_secret','UTF8')),'hex');if not found then raise exception 'VISIT_UNAVAILABLE';end if;
 perform 1 from public.rp_cafes where id=v.cafe_id and active for update;if not found then raise exception 'VISIT_UNAVAILABLE';end if;
 closed:=v.closed_at is not null or v.expires_at<=now() or not exists(select 1 from public.rp_bills where id=v.bill_id and cafe_id=v.cafe_id and status='open');
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


create function pg_temp.check_guest(ok boolean,msg text) returns void language plpgsql as $$begin if ok is distinct from true then raise exception 'TEST: %',msg;end if;end$$;
insert into auth.users(id) values('00000000-0000-4000-8000-000000000061'),('00000000-0000-4000-8000-000000000062');
insert into public.rp_cafes(id,slug,name) values('10000000-0000-4000-8000-000000000061','launch-service-fixture','Service fixture');
insert into public.rp_memberships(cafe_id,user_id,role,display_name) values('10000000-0000-4000-8000-000000000061','00000000-0000-4000-8000-000000000061','owner','Fixture owner'),('10000000-0000-4000-8000-000000000061','00000000-0000-4000-8000-000000000062','bar','Fixture bar');
insert into public.rp_tables(id,cafe_id,label,seats) values('20000000-0000-4000-8000-000000000061','10000000-0000-4000-8000-000000000061','3',4);
insert into public.rp_menu_items(id,cafe_id,external_key,names,station,price_minor) values('30000000-0000-4000-8000-000000000061','10000000-0000-4000-8000-000000000061','chez|coffee|0','{"ru":"Fixture coffee"}','bar',40000);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000061',true);
do $$declare c uuid:='10000000-0000-4000-8000-000000000061';v jsonb;link jsonb;bill uuid;g uuid;srv uuid:='90000000-0000-4000-8000-000000000061';payload jsonb;before_pay bigint;begin
 link:=rp_private.guest_staff(c,gen_random_uuid(),'table_link','{"table_id":"20000000-0000-4000-8000-000000000061"}');
 v:=rp_private.guest_transport('open',jsonb_build_object('table_token',link->>'table_token','visit_secret',repeat('e',64)));
 select bill_id into bill from rp_private.guest_visits where id=(v->>'visit_id')::uuid;
 v:=rp_private.guest_service('context',jsonb_build_object('visit_secret',repeat('e',64)));perform pg_temp.check_guest(v->>'total'='0','empty table has no invented amount');
 perform rp_private.guest_transport('submit',jsonb_build_object('visit_secret',repeat('e',64),'request_id',gen_random_uuid(),'order','{"lang":"ru","checks":[{"label":"Anna","items":[{"key":"chez|coffee|0","quantity":2}]}]}'::jsonb));
 select id into g from rp_private.guest_submissions where cafe_id=c;
 perform rp_private.guest_staff(c,gen_random_uuid(),'accept',jsonb_build_object('submission_id',g));
 insert into rp_private.cafe_settings(cafe_id,payment_path,reviews) values(c,c::text||'/payment/fixture','{"g":"https://maps.google.com"}');
 insert into rp_private.member_profiles(cafe_id,user_id,tip_path,phone) values(c,'00000000-0000-4000-8000-000000000061',c::text||'/tip/fixture','PRIVATE PHONE');
 v:=rp_private.guest_service('context',jsonb_build_object('visit_secret',repeat('e',64)));perform pg_temp.check_guest(v->>'total'='80000' and v->'checks'->0->>'sum'='80000','authoritative amount and named check');
 perform pg_temp.check_guest(v->>'payment_path'=c::text||'/payment/fixture' and v->'waiters'->0->>'tip_path'=c::text||'/tip/fixture','only cafe payment and assigned waiter tip');
 perform pg_temp.check_guest(v::text not like '%PRIVATE PHONE%' and v::text not like '%email%','no private staff contact');
 payload:=jsonb_build_object('visit_secret',repeat('e',64),'request_id',srv,'service','{"method":"qr_transfer","check":"Anna","paid":true}'::jsonb);
 v:=rp_private.guest_service('service',payload);perform pg_temp.check_guest(v=rp_private.guest_service('service',payload),'service retry exact receipt');
 perform pg_temp.check_guest((select count(*) from rp_private.guest_service_requests where cafe_id=c)=1,'one service request');
 perform pg_temp.check_guest(not exists(select 1 from public.rp_payments where cafe_id=c) and (select status='open' from public.rp_bills where id=bill),'guest paid flag never creates payment or closes bill');
 begin perform rp_private.guest_service('service',payload||jsonb_build_object('service','{"method":"cash","check":"Anna","paid":false}'::jsonb));raise exception 'REUSE_ALLOWED';exception when others then if sqlerrm<>'REQUEST_ID_REUSED' then raise;end if;end;
 v:=rp_private.guest_services_staff(c,null,'services','{}');perform pg_temp.check_guest(jsonb_array_length(v)=1 and v->0->>'table'='3','staff sees persistent request');
 perform rp_private.guest_services_staff(c,gen_random_uuid(),'service_done',jsonb_build_object('service_id',(v->0->>'id')::uuid));
 perform pg_temp.check_guest(rp_private.guest_services_staff(c,null,'services','{}')='[]','handled request stays recorded but no longer pending');
 perform set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000062',true);
 begin perform rp_private.guest_services_staff(c,null,'services','{}');raise exception 'BAR_ALLOWED';exception when insufficient_privilege then null;end;
 perform set_config('request.jwt.claim.sub','',true);
 begin perform rp_private.guest_services_staff(c,null,'services','{}');raise exception 'ANON_ALLOWED';exception when insufficient_privilege then null;end;
 begin perform rp_private.guest_service('context',jsonb_build_object('visit_secret',repeat('f',64)));raise exception 'OTHER_VISIT_ALLOWED';exception when others then if sqlerrm<>'VISIT_UNAVAILABLE' then raise;end if;end;
 update public.rp_bills set status='closed',closed_at=now() where id=bill;
 v:=rp_private.guest_service('context',jsonb_build_object('visit_secret',repeat('e',64)));perform pg_temp.check_guest(v->>'closed'='true' and not v?'payment_path' and v->'waiters'='[]','closed visit exposes no QR');
 perform pg_temp.check_guest(rp_private.guest_service('service',payload)->>'ok'='true','receipt recovery after closure');
 begin perform rp_private.guest_service('service',payload||jsonb_build_object('request_id',gen_random_uuid()));raise exception 'CLOSED_WRITE_ALLOWED';exception when others then if sqlerrm<>'VISIT_CLOSED' then raise;end if;end;
 perform pg_temp.check_guest(not has_table_privilege('anon','rp_private.guest_service_requests','select') and not has_table_privilege('authenticated','rp_private.guest_service_requests','select'),'no raw client access');
end $$;
rollback;
select 'PASS guest service: authoritative sums, QR scope, no private contacts, idempotent requests, no automatic payment, roles and closure' as result;
