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
rollback;
select 'PASS guest intake: receipt retry, separate checks, server prices, atomic acceptance, price-change rejection, independent bar/kitchen service, exact payment retry; fixture rolled back' as result;
