-- Staged guest intake. No public execution grants; no live table QR is issued here.
begin;
create table rp_private.guest_visits(id uuid primary key default gen_random_uuid(),cafe_id uuid not null references public.rp_cafes(id),table_id uuid not null,token_hash text not null unique,expires_at timestamptz not null default now()+interval '6 hours',closed_at timestamptz,foreign key(cafe_id,table_id) references public.rp_tables(cafe_id,id));
create table rp_private.guest_submissions(id uuid primary key default gen_random_uuid(),cafe_id uuid not null,visit_id uuid not null references rp_private.guest_visits(id),request_id uuid not null,body jsonb not null,items_snapshot jsonb not null,result jsonb not null,created_at timestamptz not null default now(),accepted_by uuid,accepted_at timestamptz,order_ids jsonb,unique(visit_id,request_id),foreign key(cafe_id,accepted_by) references public.rp_memberships(cafe_id,user_id));
alter table rp_private.guest_visits enable row level security;
alter table rp_private.guest_submissions enable row level security;
revoke all on rp_private.guest_visits,rp_private.guest_submissions from public,anon,authenticated;
create index guest_pending_cafe on rp_private.guest_submissions(cafe_id,created_at) where accepted_at is null;
create function rp_private.guest_submit(secret text,r uuid,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare v rp_private.guest_visits;g rp_private.guest_submissions;item public.rp_menu_items;ck jsonb;x jsonb;rows jsonb:='[]';lines jsonb;labels text[]:='{}';ids jsonb:='[]';n int:=0;rid uuid;
begin
 if secret is null or secret!~'^[a-f0-9]{64}$' or r is null or b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>60000 then raise exception 'INVALID_REQUEST';end if;
 select * into v from rp_private.guest_visits where token_hash=encode(sha256(convert_to(secret,'UTF8')),'hex');if not found then raise exception 'VISIT_UNAVAILABLE';end if;
 perform 1 from public.rp_cafes where id=v.cafe_id and active for update;if not found then raise exception 'VISIT_UNAVAILABLE';end if;
 select * into v from rp_private.guest_visits where id=v.id for update;
 select * into g from rp_private.guest_submissions where visit_id=v.id and request_id=r;
 if found then if g.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return g.result;end if;
 if v.closed_at is not null or v.expires_at<=now() or not exists(select 1 from public.rp_tables where cafe_id=v.cafe_id and id=v.table_id and active) then raise exception 'VISIT_UNAVAILABLE';end if;
 if (select count(*) from rp_private.guest_submissions where visit_id=v.id and created_at>now()-interval '1 minute')>=6 then raise exception 'RATE_LIMIT';end if;
 if b->>'lang' is null or b->>'lang' not in ('ru','vi','en','de','zh','ko') or jsonb_typeof(b->'checks') is distinct from 'array' or jsonb_array_length(b->'checks') not between 1 and 20 then raise exception 'INVALID_CHECKS';end if;
 for ck in select value from jsonb_array_elements(b->'checks') loop
  if length(trim(coalesce(ck->>'label',''))) not between 1 and 80 or ck->>'label'=any(labels) or jsonb_typeof(ck->'items') is distinct from 'array' or jsonb_array_length(ck->'items')<1 then raise exception 'INVALID_CHECK';end if;labels:=array_append(labels,ck->>'label');lines:='[]';
  for x in select value from jsonb_array_elements(ck->'items') loop
   n:=n+1;if n>100 or jsonb_typeof(x->'quantity') is distinct from 'number' or (x->>'quantity')::numeric<>trunc((x->>'quantity')::numeric) or (x->>'quantity')::numeric not between 1 and 99 or length(coalesce(x->>'note',''))>300 then raise exception 'INVALID_ITEM';end if;
   select * into item from public.rp_menu_items where cafe_id=v.cafe_id and external_key=x->>'key' and active and not stopped;
   if not found or item.price_minor is null then raise exception 'ITEM_UNAVAILABLE';end if;
   lines:=lines||jsonb_build_array(jsonb_build_object('id',item.id,'quantity',(x->>'quantity')::int,'note',coalesce(x->>'note',''),'names',item.names,'price',item.price_minor,'station',item.station));
  end loop;
  rid:=gen_random_uuid();ids:=ids||jsonb_build_array(rid);rows:=rows||jsonb_build_array(jsonb_build_object('id',rid,'label',ck->>'label','items',lines));
 end loop;
 insert into rp_private.guest_submissions(cafe_id,visit_id,request_id,body,items_snapshot,result) values(v.cafe_id,v.id,r,b,rows,jsonb_build_object('ok',true,'request_id',r,'order_ids',ids)) returning * into g;
 return g.result;
end $$;
create function rp_private.accept_guest(c uuid,r uuid,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;g rp_private.guest_submissions;v rp_private.guest_visits;rec rp_private.receipts;ck jsonb;x jsonb;lines jsonb;result jsonb;one jsonb;ids jsonb:='[]';label text;
begin
 perform 1 from public.rp_cafes where id=c for update;m:=rp_private.require_member(c);if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 if r is null or b is null or jsonb_typeof(b)<>'object' then raise exception 'INVALID_REQUEST';end if;
 select * into rec from rp_private.receipts where cafe_id=c and request_id=r;if found then if rec.actor_id<>auth.uid() or rec.action<>'accept_guest' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return rec.result;end if;
 select * into g from rp_private.guest_submissions where cafe_id=c and id=(b->>'submission_id')::uuid for update;if not found or g.accepted_at is not null then raise exception 'SUBMISSION_UNAVAILABLE';end if;
 select * into v from rp_private.guest_visits where id=g.visit_id;
 if v.closed_at is not null or v.expires_at<=now() then raise exception 'VISIT_UNAVAILABLE';end if;
 select t.label into label from public.rp_tables t where t.cafe_id=c and t.id=v.table_id and active;if label is null then raise exception 'TABLE_NOT_FOUND';end if;
 for ck in select value from jsonb_array_elements(g.items_snapshot) loop
  lines:='[]';for x in select value from jsonb_array_elements(ck->'items') loop
   if not exists(select 1 from public.rp_menu_items where cafe_id=c and id=(x->>'id')::uuid and active and not stopped and price_minor=(x->>'price')::bigint) then raise exception 'ITEM_OR_PRICE_CHANGED';end if;
   lines:=lines||jsonb_build_array(jsonb_build_object('id',x->>'id','quantity',x->'quantity','note',x->>'note'));
  end loop;
  one:=rp_private.command(c,gen_random_uuid(),'order_create',jsonb_build_object('table',label,'check',ck->>'label','lang',g.body->>'lang','items',lines));
  update public.rp_orders set created_at=g.created_at where cafe_id=c and id=(one->>'order_id')::uuid;
  insert into public.rp_order_events(cafe_id,order_id,actor_id,event_type,payload,request_id) values(c,(one->>'order_id')::uuid,auth.uid(),'accept',jsonb_build_object('submission_id',g.id),gen_random_uuid());ids:=ids||jsonb_build_array(one->>'order_id');
 end loop;
 update rp_private.guest_submissions set accepted_by=auth.uid(),accepted_at=clock_timestamp(),order_ids=ids where id=g.id;
 result:=jsonb_build_object('ok',true,'request_id',r,'order_ids',ids);
 insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'accept_guest',b,result);return result;
end $$;
revoke all on function rp_private.guest_submit(text,uuid,jsonb),rp_private.accept_guest(uuid,uuid,jsonb) from public,anon,authenticated;


create table rp_private.guest_table_links(cafe_id uuid not null,table_id uuid primary key,token_hash text not null unique,created_at timestamptz not null default now(),foreign key(cafe_id,table_id) references public.rp_tables(cafe_id,id));
alter table rp_private.guest_table_links enable row level security;
revoke all on rp_private.guest_table_links from public,anon,authenticated;
alter table rp_private.guest_visits add column bill_id uuid;
alter table rp_private.guest_visits add constraint guest_visit_bill foreign key(cafe_id,bill_id) references public.rp_bills(cafe_id,id);
create function rp_private.guest_transport(a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
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
   if bid is null then insert into public.rp_bills(cafe_id,table_id,currency) select l.cafe_id,l.table_id,currency from public.rp_cafes where id=l.cafe_id returning id into bid;end if;
   insert into rp_private.guest_visits(cafe_id,table_id,token_hash,bill_id) values(l.cafe_id,l.table_id,h,bid) returning * into v;
  end if;
  if v.closed_at is not null or v.expires_at<=now() or not exists(select 1 from public.rp_bills where id=v.bill_id and cafe_id=v.cafe_id and status='open') then raise exception 'VISIT_CLOSED';end if;
  return jsonb_build_object('cafe_id',v.cafe_id,'visit_id',v.id,'table',(select label from public.rp_tables where id=v.table_id),'expires_at',v.expires_at);
 end if;
 select * into v from rp_private.guest_visits where token_hash=h;if not found then raise exception 'VISIT_UNAVAILABLE';end if;
 perform 1 from public.rp_cafes where id=v.cafe_id and active for update;if not found then raise exception 'VISIT_UNAVAILABLE';end if;
 if a='submit' then
  -- Retry an already-recorded request remains readable after the visit closes.
  select * into g from rp_private.guest_submissions where visit_id=v.id and request_id=(b->>'request_id')::uuid;
  if found then return rp_private.guest_submit(secret,(b->>'request_id')::uuid,b->'order');end if;
  if not exists(select 1 from public.rp_bills where id=v.bill_id and cafe_id=v.cafe_id and status='open') then raise exception 'VISIT_CLOSED';end if;
  return rp_private.guest_submit(secret,(b->>'request_id')::uuid,b->'order');
 elsif a='status' then
  select * into g from rp_private.guest_submissions where visit_id=v.id and request_id=(b->>'request_id')::uuid;if not found then raise exception 'REQUEST_UNAVAILABLE';end if;
  return g.result||jsonb_build_object('accepted',g.accepted_at is not null,'closed',not exists(select 1 from public.rp_bills where cafe_id=v.cafe_id and id=v.bill_id and status='open'),'states',coalesce((select jsonb_agg(jsonb_build_object('id',o.id,'status',o.status,'stations',(select jsonb_agg(jsonb_build_object('station',i.station,'ready',i.ready_at is not null,'served',i.served_at is not null)) from public.rp_order_items i where i.cafe_id=o.cafe_id and i.order_id=o.id and i.cancelled_at is null))) from public.rp_orders o where o.cafe_id=v.cafe_id and g.order_ids ? o.id::text),'[]'));
 end if;
 raise exception 'UNKNOWN_ACTION';
end $$;
create function rp_private.guest_staff(c uuid,r uuid,a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;secret text;t uuid;v rp_private.guest_visits;g rp_private.guest_submissions;rec rp_private.receipts;result jsonb;
begin
 perform 1 from public.rp_cafes where id=c for update;m:=rp_private.require_member(c);
 if a='pending' and m.role in ('owner','manager','waiter') then return coalesce((select jsonb_agg(jsonb_build_object('id',gs.id,'created_at',gs.created_at,'table',gt.label,'lang',gs.body->>'lang','checks',gs.items_snapshot)) from rp_private.guest_submissions gs join rp_private.guest_visits gv on gv.id=gs.visit_id join public.rp_tables gt on gt.id=gv.table_id and gt.cafe_id=gs.cafe_id where gs.cafe_id=c and gs.accepted_at is null and gv.closed_at is null and gv.expires_at>now() and exists(select 1 from public.rp_bills where id=gv.bill_id and cafe_id=c and status='open')),'[]');end if;
 if a='accept' then
  select s.* into g from rp_private.guest_submissions s where s.id=(b->>'submission_id')::uuid and s.cafe_id=c;
  select * into v from rp_private.guest_visits where id=g.visit_id;
  if not exists(select 1 from public.rp_bills where id=v.bill_id and cafe_id=c and status='open') then
   -- A previously acknowledged acceptance may still be retried after payment.
   if not exists(select 1 from rp_private.receipts where cafe_id=c and request_id=r and actor_id=auth.uid() and action='accept_guest' and body=b) then raise exception 'VISIT_CLOSED';end if;
  end if;
  return rp_private.accept_guest(c,r,b);
 end if;
 if a='table_link' and m.role in ('owner','manager') then
  if r is null then raise exception 'REQUEST_ID_REQUIRED';end if;
  select * into rec from rp_private.receipts where cafe_id=c and request_id=r;if found then if rec.actor_id<>auth.uid() or rec.action<>'guest:table_link' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return rec.result;end if;
  t:=(b->>'table_id')::uuid;if not exists(select 1 from public.rp_tables where cafe_id=c and id=t and active) then raise exception 'TABLE_NOT_FOUND';end if;
  if exists(select 1 from rp_private.guest_table_links where table_id=t) and coalesce((b->>'replace')::boolean,false)=false then raise exception 'LINK_EXISTS_CONFIRM_REISSUE';end if;
  secret:=replace(gen_random_uuid()::text,'-','')||replace(gen_random_uuid()::text,'-','');
  insert into rp_private.guest_table_links(cafe_id,table_id,token_hash) values(c,t,encode(sha256(convert_to(secret,'UTF8')),'hex')) on conflict(table_id) do update set token_hash=excluded.token_hash,created_at=now();
  update rp_private.guest_visits set closed_at=now() where cafe_id=c and table_id=t and closed_at is null;
  result:=jsonb_build_object('table_token',secret,'table',(select label from public.rp_tables where id=t));
  insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'guest:table_link',b,(result-'table_token')||'{"reissue_required":true}');return result;
 end if;
 raise exception 'ROLE_DENIED' using errcode='42501';
end $$;
create function public.rp_guest_transport(a text,b jsonb) returns jsonb language sql security invoker set search_path='' as $$select rp_private.guest_transport(a,b)$$;
create function public.rp_guest_staff(c uuid,r uuid,a text,b jsonb) returns jsonb language sql security invoker set search_path='' as $$select rp_private.guest_staff(c,r,a,b)$$;
revoke all on function rp_private.guest_transport(text,jsonb),public.rp_guest_transport(text,jsonb),rp_private.guest_staff(uuid,uuid,text,jsonb),public.rp_guest_staff(uuid,uuid,text,jsonb) from public,anon,authenticated;
create function rp_private.guest_bill_guard() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if old.status='open' and new.status<>'open' then
  if exists(select 1 from rp_private.guest_submissions g join rp_private.guest_visits v on v.id=g.visit_id where g.cafe_id=new.cafe_id and v.bill_id=new.id and g.accepted_at is null and v.closed_at is null and v.expires_at>now()) then raise exception 'GUEST_ORDERS_PENDING';end if;
  update rp_private.guest_visits set closed_at=clock_timestamp() where cafe_id=new.cafe_id and bill_id=new.id and closed_at is null;
 end if;return new;
end $$;
revoke all on function rp_private.guest_bill_guard() from public,anon,authenticated;
create trigger guest_bill_close before update of status on public.rp_bills for each row execute function rp_private.guest_bill_guard();
-- All grants deliberately absent until reviewed activation.

create function pg_temp.guest_assert(ok boolean,msg text) returns void language plpgsql as $$begin if ok is distinct from true then raise exception 'TEST: %',msg;end if;end$$;
insert into auth.users(id) values('00000000-0000-4000-8000-000000000051');
insert into public.rp_cafes(id,slug,name) values('10000000-0000-4000-8000-000000000051','guest-fixture','Guest fixture');
insert into public.rp_memberships(cafe_id,user_id,role,display_name) values('10000000-0000-4000-8000-000000000051','00000000-0000-4000-8000-000000000051','owner','Owner fixture');
insert into public.rp_tables(id,cafe_id,label,seats) values('20000000-0000-4000-8000-000000000051','10000000-0000-4000-8000-000000000051','5',4);
insert into public.rp_menu_items(id,cafe_id,external_key,names,station,price_minor) values('30000000-0000-4000-8000-000000000051','10000000-0000-4000-8000-000000000051','fish|0|0','{"ru":"Fish fixture","vi":"Ca"}','kitchen',160000);
insert into rp_private.guest_visits(id,cafe_id,table_id,token_hash) values('40000000-0000-4000-8000-000000000051','10000000-0000-4000-8000-000000000051','20000000-0000-4000-8000-000000000051',encode(sha256(convert_to(repeat('a',64),'UTF8')),'hex'));
insert into public.rp_menu_items(id,cafe_id,external_key,names,station,price_minor) values('30000000-0000-4000-8000-000000000052','10000000-0000-4000-8000-000000000051','coffee|0|0','{"ru":"Coffee fixture","vi":"Ca phe"}','bar',30000);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000051',true);
do $$declare b jsonb:='{"lang":"ru","checks":[{"label":"Anna","items":[{"key":"fish|0|0","quantity":2,"note":"No spice","price":1},{"key":"coffee|0|0","quantity":1,"note":"No ice"}]},{"label":"Ivan","items":[{"key":"fish|0|0","quantity":1,"note":""}]}]}';v jsonb;g uuid;payload jsonb;begin
 v:=rp_private.guest_submit(repeat('a',64),'50000000-0000-4000-8000-000000000051',b);
 perform pg_temp.guest_assert(jsonb_array_length(v->'order_ids')=2,'separate checks recorded');
 perform pg_temp.guest_assert(v=rp_private.guest_submit(repeat('a',64),'50000000-0000-4000-8000-000000000051',b),'submit retry exact receipt');
 perform pg_temp.guest_assert((select count(*) from rp_private.guest_submissions)=1,'one submission after retry');
 perform pg_temp.guest_assert((select items_snapshot->0->'items'->0->>'price' from rp_private.guest_submissions)='160000','forged client price ignored');
 begin perform rp_private.guest_submit(repeat('b',64),gen_random_uuid(),b);raise exception 'INVALID_TOKEN_ALLOWED';exception when others then if sqlerrm<>'VISIT_UNAVAILABLE' then raise;end if;end;
 begin perform rp_private.guest_submit(repeat('a',64),'50000000-0000-4000-8000-000000000051',b||'{"lang":"en"}');raise exception 'REQUEST_OVERWRITTEN';exception when others then if sqlerrm<>'REQUEST_ID_REUSED' then raise;end if;end;
 select id into g from rp_private.guest_submissions;payload:=jsonb_build_object('submission_id',g);
 update public.rp_menu_items set price_minor=170000 where id='30000000-0000-4000-8000-000000000051';
 begin perform rp_private.accept_guest('10000000-0000-4000-8000-000000000051',gen_random_uuid(),payload);raise exception 'PRICE_CHANGE_IGNORED';exception when others then if sqlerrm<>'ITEM_OR_PRICE_CHANGED' then raise;end if;end;
 perform pg_temp.guest_assert((select count(*) from public.rp_orders where cafe_id='10000000-0000-4000-8000-000000000051')=0,'failed acceptance atomic');
 update public.rp_menu_items set price_minor=160000 where id='30000000-0000-4000-8000-000000000051';
 v:=rp_private.accept_guest('10000000-0000-4000-8000-000000000051','60000000-0000-4000-8000-000000000051',payload);
 perform pg_temp.guest_assert(v=rp_private.accept_guest('10000000-0000-4000-8000-000000000051','60000000-0000-4000-8000-000000000051',payload),'acceptance retry exact receipt');
 perform pg_temp.guest_assert((select count(*) from public.rp_orders where cafe_id='10000000-0000-4000-8000-000000000051')=2,'one order per named check');
 perform pg_temp.guest_assert((select sum(i.quantity*i.unit_price_minor) from public.rp_order_items i where cafe_id='10000000-0000-4000-8000-000000000051')=510000,'server prices and quantities');
 -- Full existing station/service/payment commands, using accepted orders only.
 perform pg_temp.guest_assert((select count(*) from public.rp_orders where cafe_id='10000000-0000-4000-8000-000000000051' and status='accepted')=2,'accepted drafts not sent before waiter');
 for g in select id from public.rp_orders where cafe_id='10000000-0000-4000-8000-000000000051' loop
  perform rp_private.operational_command('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'send',jsonb_build_object('order_id',g,'version',(select version from public.rp_orders where id=g)));
 end loop;
 select order_id into g from public.rp_order_items where cafe_id='10000000-0000-4000-8000-000000000051' and station='bar';
 perform rp_private.operational_command('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'station_ready',jsonb_build_object('order_id',g,'station','bar','version',(select version from public.rp_orders where id=g)));
 perform pg_temp.guest_assert((select status from public.rp_orders where id=g)='cooking','bar ready does not finish kitchen');
 perform rp_private.operational_command('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'serve',jsonb_build_object('order_id',g,'station','bar','version',(select version from public.rp_orders where id=g)));
 perform pg_temp.guest_assert(not exists(select 1 from public.rp_order_items where order_id=g and station='kitchen' and served_at is not null),'bar service does not serve food');
 for g in select id from public.rp_orders where cafe_id='10000000-0000-4000-8000-000000000051' loop
  perform rp_private.operational_command('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'station_ready',jsonb_build_object('order_id',g,'station','kitchen','version',(select version from public.rp_orders where id=g)));
  perform rp_private.operational_command('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'serve',jsonb_build_object('order_id',g,'station','kitchen','version',(select version from public.rp_orders where id=g)));
 end loop;
 select id into g from public.rp_bills where cafe_id='10000000-0000-4000-8000-000000000051';
 payload:=jsonb_build_object('bill_id',g,'version',(select version from public.rp_bills where id=g),'payments',(select jsonb_object_agg(id::text,'cash') from public.rp_checks where bill_id=g));
 perform rp_private.operational_command('10000000-0000-4000-8000-000000000051','70000000-0000-4000-8000-000000000051','bill_close',payload);
 perform rp_private.operational_command('10000000-0000-4000-8000-000000000051','70000000-0000-4000-8000-000000000051','bill_close',payload);
 perform pg_temp.guest_assert((select sum(amount_minor) from public.rp_payments where cafe_id='10000000-0000-4000-8000-000000000051')=510000,'recorded payments exact, close retry no duplicate');
 perform pg_temp.guest_assert(not has_function_privilege('anon','rp_private.guest_submit(text,uuid,jsonb)','execute'),'closed until Edge review');
end$$;

do $$declare c uuid:='10000000-0000-4000-8000-000000000051';t uuid:='20000000-0000-4000-8000-000000000051';link jsonb;v jsonb;v2 jsonb;r jsonb;g uuid;bill uuid;body jsonb:='{"lang":"ru","checks":[{"label":"Guest","items":[{"key":"coffee|0|0","quantity":1,"note":"No ice"}]}]}';begin
 link:=rp_private.guest_staff(c,'80000000-0000-4000-8000-000000000051','table_link',jsonb_build_object('table_id',t));
 perform pg_temp.guest_assert(length(link->>'table_token')=64,'high entropy table link');
 v:=rp_private.guest_staff(c,'80000000-0000-4000-8000-000000000051','table_link',jsonb_build_object('table_id',t));perform pg_temp.guest_assert(v->>'reissue_required'='true' and not v?'table_token','no plaintext table secret in receipt');
 v:=rp_private.guest_transport('open',jsonb_build_object('table_token',link->>'table_token','visit_secret',repeat('c',64)));
 v2:=rp_private.guest_transport('open',jsonb_build_object('table_token',link->>'table_token','visit_secret',repeat('d',64)));
 perform pg_temp.guest_assert((select count(distinct bill_id) from rp_private.guest_visits where closed_at is null)=1,'two guests share one bill');
 r:=rp_private.guest_transport('submit',jsonb_build_object('visit_secret',repeat('c',64),'request_id','90000000-0000-4000-8000-000000000051','order',body));
 v:=rp_private.guest_staff(c,null,'pending','{}');perform pg_temp.guest_assert(jsonb_array_length(v)=1,'waiter incoming queue');g:=(v->0->>'id')::uuid;
 select bill_id into bill from rp_private.guest_visits where token_hash=encode(sha256(convert_to(repeat('c',64),'UTF8')),'hex');
 begin update public.rp_bills set status='closed',closed_at=now() where id=bill;raise exception 'UNREAD_ORDER_CLOSED';exception when others then if sqlerrm<>'GUEST_ORDERS_PENDING' then raise;end if;end;
 v:=rp_private.guest_transport('status',jsonb_build_object('visit_secret',repeat('c',64),'request_id','90000000-0000-4000-8000-000000000051'));perform pg_temp.guest_assert(v->>'accepted'='false','guest sees pending');
 v:=rp_private.guest_staff(c,'a0000000-0000-4000-8000-000000000051','accept',jsonb_build_object('submission_id',g));
 v:=rp_private.guest_transport('status',jsonb_build_object('visit_secret',repeat('c',64),'request_id','90000000-0000-4000-8000-000000000051'));perform pg_temp.guest_assert(v->>'accepted'='true','guest sees actual acceptance');
 begin perform rp_private.guest_transport('status',jsonb_build_object('visit_secret',repeat('d',64),'request_id','90000000-0000-4000-8000-000000000051'));raise exception 'OTHER_GUEST_READ_ORDER';exception when others then if sqlerrm<>'REQUEST_UNAVAILABLE' then raise;end if;end;
 -- Explicitly close the fixture bill to test visit invalidation; operational payment guards are covered above.
 update public.rp_bills set status='void',closed_at=now() where id=bill;
 begin perform rp_private.guest_transport('submit',jsonb_build_object('visit_secret',repeat('c',64),'request_id',gen_random_uuid(),'order',body));raise exception 'OLD_VISIT_WROTE';exception when others then if sqlerrm<>'VISIT_CLOSED' then raise;end if;end;
 perform pg_temp.guest_assert(r=rp_private.guest_transport('submit',jsonb_build_object('visit_secret',repeat('c',64),'request_id','90000000-0000-4000-8000-000000000051','order',body)),'receipt retry after visit closure');
 perform pg_temp.guest_assert(not has_function_privilege('anon','public.rp_guest_transport(text,jsonb)','execute') and not has_function_privilege('authenticated','public.rp_guest_staff(uuid,uuid,text,jsonb)','execute'),'new endpoints remain closed');
end$$;


insert into auth.users(id) values('00000000-0000-4000-8000-000000000052'),('00000000-0000-4000-8000-000000000053');
insert into public.rp_memberships(cafe_id,user_id,role,display_name) values('10000000-0000-4000-8000-000000000051','00000000-0000-4000-8000-000000000052','waiter','Waiter fixture'),('10000000-0000-4000-8000-000000000051','00000000-0000-4000-8000-000000000053','bar','Bar fixture');
grant execute on function public.rp_guest_staff(uuid,uuid,text,jsonb),rp_private.guest_staff(uuid,uuid,text,jsonb) to authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000052',true);
set local role authenticated;
do $$begin
 perform public.rp_guest_staff('10000000-0000-4000-8000-000000000051',null,'pending','{}');
 begin perform public.rp_guest_staff('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'table_link','{"table_id":"20000000-0000-4000-8000-000000000051"}');raise exception 'WAITER_ISSUED_TABLE_CAP';exception when insufficient_privilege then null;end;
 begin perform public.rp_guest_staff('10000000-0000-4000-8000-000000000099',null,'pending','{}');raise exception 'CROSS_CAFE_QUEUE';exception when insufficient_privilege then null;end;
end$$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000053',true);
do $$begin
 begin perform public.rp_guest_staff('10000000-0000-4000-8000-000000000051',null,'pending','{}');raise exception 'BAR_READ_GUEST_QUEUE';exception when insufficient_privilege then null;end;
end$$;
reset role;

rollback;
select 'PASS guest transport: QR issuance/retry, two visitors/one bill, incoming queue, status isolation, close guard, stale-visit rejection + intake: receipt retry, separate checks, server prices, atomic acceptance, price-change rejection, independent bar/kitchen service, exact payment retry; fixture rolled back' as result;
