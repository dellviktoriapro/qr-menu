begin;
create or replace function rp_private.guest_transport(a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare l rp_private.guest_table_links;v rp_private.guest_visits;g rp_private.guest_submissions;secret text;h text;bid uuid;result jsonb;
begin
 if b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>65000 then raise exception 'INVALID_REQUEST';end if;
 secret:=b->>'visit_secret';if secret is null or secret!~'^[a-f0-9]{64}$' then raise exception 'VISIT_UNAVAILABLE';end if;h:=encode(sha256(convert_to(secret,'UTF8')),'hex');
 if a='open' then
  if b->>'table_token' is null or b->>'table_token'!~'^[a-f0-9]{64}$' then raise exception 'TABLE_UNAVAILABLE';end if;
  select * into l from rp_private.guest_table_links where token_hash=encode(sha256(convert_to(b->>'table_token','UTF8')),'hex');if not found then raise exception 'TABLE_UNAVAILABLE';end if;
  perform 1 from public.rp_cafes where id=l.cafe_id and active for update;if not found or not exists(select 1 from public.rp_tables where id=l.table_id and cafe_id=l.cafe_id and active) then raise exception 'TABLE_UNAVAILABLE';end if;
  select * into v from rp_private.guest_visits where token_hash=h;
  if found then if v.cafe_id<>l.cafe_id or v.table_id<>l.table_id then raise exception 'VISIT_UNAVAILABLE';end if;
  else
   if (select count(*) from rp_private.guest_visits where table_id=l.table_id and expires_at>now() and closed_at is null)>=100 then raise exception 'RATE_LIMIT';end if;
   select id into bid from public.rp_bills where cafe_id=l.cafe_id and table_id=l.table_id and status='open';
   -- A scan alone is not a financial bill. Bind when the first order is submitted.
   insert into rp_private.guest_visits(cafe_id,table_id,token_hash,bill_id) values(l.cafe_id,l.table_id,h,bid) returning * into v;
  end if;
  if v.closed_at is not null or v.expires_at<=now() or (v.bill_id is not null and not exists(select 1 from public.rp_bills where id=v.bill_id and cafe_id=v.cafe_id and status='open')) then raise exception 'VISIT_CLOSED';end if;
  return jsonb_build_object('cafe_id',v.cafe_id,'visit_id',v.id,'table',(select label from public.rp_tables where id=v.table_id),'expires_at',v.expires_at);
 end if;
 select * into v from rp_private.guest_visits where token_hash=h;if not found then raise exception 'VISIT_UNAVAILABLE';end if;
 perform 1 from public.rp_cafes where id=v.cafe_id and active for update;if not found then raise exception 'VISIT_UNAVAILABLE';end if;
 if a='submit' then
  -- Retry an already-recorded request remains readable after the visit closes.
  select * into g from rp_private.guest_submissions where visit_id=v.id and request_id=(b->>'request_id')::uuid;
  if found then return rp_private.guest_submit(secret,(b->>'request_id')::uuid,b->'order');end if;
  if v.closed_at is not null or v.expires_at<=now() then raise exception 'VISIT_CLOSED';end if;
  if v.bill_id is null then
   select id into bid from public.rp_bills where cafe_id=v.cafe_id and table_id=v.table_id and status='open';
   if bid is null then insert into public.rp_bills(cafe_id,table_id,currency) select v.cafe_id,v.table_id,currency from public.rp_cafes where id=v.cafe_id returning id into bid;end if;
   update rp_private.guest_visits set bill_id=bid where cafe_id=v.cafe_id and table_id=v.table_id and bill_id is null and closed_at is null and expires_at>now();v.bill_id:=bid;
  end if;
  if not exists(select 1 from public.rp_bills where id=v.bill_id and cafe_id=v.cafe_id and status='open') then raise exception 'VISIT_CLOSED';end if;
  return rp_private.guest_submit(secret,(b->>'request_id')::uuid,b->'order');
 elsif a='status' then
  select * into g from rp_private.guest_submissions where visit_id=v.id and request_id=(b->>'request_id')::uuid;if not found then raise exception 'REQUEST_UNAVAILABLE';end if;
  return g.result||jsonb_build_object('checks',g.items_snapshot,'created_at',g.created_at,'accepted',g.accepted_at is not null,'rejected',g.rejected_at is not null,'closed',not exists(select 1 from public.rp_bills where cafe_id=v.cafe_id and id=v.bill_id and status='open'),'states',coalesce((select jsonb_agg(jsonb_build_object('id',o.id,'number',o.number,'waiter',o.waiter_name_snapshot,'check',(select label from public.rp_checks where id=o.check_id and cafe_id=o.cafe_id),'status',o.status,'stations',(select jsonb_agg(jsonb_build_object('station',i.station,'ready',i.ready_at is not null,'served',i.served_at is not null)) from public.rp_order_items i where i.cafe_id=o.cafe_id and i.order_id=o.id and i.cancelled_at is null))) from public.rp_orders o where o.cafe_id=v.cafe_id and g.order_ids ? o.id::text),'[]'));
 end if;
 raise exception 'UNKNOWN_ACTION';
end $$;

create or replace function rp_private.guest_service(a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
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


create function pg_temp.idle_assert(ok boolean,msg text) returns void language plpgsql as $$begin if ok is distinct from true then raise exception 'TEST: %',msg;end if;end$$;
insert into auth.users(id) values('00000000-0000-4000-8000-000000000101');
insert into public.rp_cafes(id,slug,name) values('10000000-0000-4000-8000-000000000101','idle-visit-fixture','Idle visit fixture');
insert into public.rp_memberships(cafe_id,user_id,role,display_name) values('10000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000101','owner','Fixture owner');
insert into public.rp_tables(id,cafe_id,label,seats) values('20000000-0000-4000-8000-000000000101','10000000-0000-4000-8000-000000000101','3',4);
insert into public.rp_menu_items(cafe_id,external_key,names,station,price_minor) values('10000000-0000-4000-8000-000000000101','chez|coffee|0','{"vi":"Coffee"}','bar',40000);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000101',true);
do $$declare c uuid:='10000000-0000-4000-8000-000000000101';link jsonb;v jsonb;bill uuid;g uuid;begin
 link:=rp_private.guest_staff(c,gen_random_uuid(),'table_link','{"table_id":"20000000-0000-4000-8000-000000000101"}');
 perform rp_private.guest_transport('open',jsonb_build_object('table_token',link->>'table_token','visit_secret',repeat('1',64)));
 perform rp_private.guest_transport('open',jsonb_build_object('table_token',link->>'table_token','visit_secret',repeat('2',64)));
 perform pg_temp.idle_assert(not exists(select 1 from public.rp_bills where cafe_id=c),'browsing alone must not create a financial bill');
 v:=rp_private.guest_service('context',jsonb_build_object('visit_secret',repeat('1',64)));perform pg_temp.idle_assert(v->>'closed'='false' and v->>'total'='0','unbound browsing visit is valid');
 perform rp_private.guest_transport('submit',jsonb_build_object('visit_secret',repeat('1',64),'request_id',gen_random_uuid(),'order','{"lang":"ru","checks":[{"label":"Anna","items":[{"key":"chez|coffee|0","quantity":1}]}]}'::jsonb));
 perform pg_temp.idle_assert((select count(*) from public.rp_bills where cafe_id=c)=1 and (select count(distinct bill_id) from rp_private.guest_visits where cafe_id=c)=1,'first order creates exactly one shared bill');
 select id into g from rp_private.guest_submissions where cafe_id=c;perform rp_private.guest_staff(c,gen_random_uuid(),'accept',jsonb_build_object('submission_id',g));
 v:=rp_private.guest_service('context',jsonb_build_object('visit_secret',repeat('2',64)));perform pg_temp.idle_assert(v->>'total'='40000','other scanner sees the same table bill');
 select id into bill from public.rp_bills where cafe_id=c;update public.rp_bills set status='closed',closed_at=now() where id=bill;
 v:=rp_private.guest_service('context',jsonb_build_object('visit_secret',repeat('2',64)));perform pg_temp.idle_assert(v->>'closed'='true','closing bill closes both scanners');
end $$;
rollback;
select 'PASS idle visit: scanning has no financial effect, first order creates one bill, concurrent visitors share it, closure invalidates both' as result;
