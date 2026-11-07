begin;
-- Expand the ALREADY owner/manager-scoped report; no new grants or raw table access.
-- Revenue is staff-recorded net payments; order amounts are historical price snapshots.
create or replace function rp_private.owner_stats(c uuid,f timestamptz,t timestamptz) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;result jsonb;tz text;first_day date;last_day date;history_start timestamptz;
begin
 m:=rp_private.require_member(c);
 if m.role not in ('owner','manager') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 if f is null or t is null or f>=t or t-f>interval '180 days' then raise exception 'INVALID_PERIOD';end if;
 select timezone into tz from public.rp_cafes where id=c;
 first_day:=(f at time zone tz)::date;last_day:=((t-interval '1 microsecond') at time zone tz)::date;
 history_start:=((first_day-(last_day-first_day+1))::timestamp at time zone tz);
 with
 ob as materialized (
  select o.*, (o.created_at at time zone tz)::date as d,
   coalesce(v.total,0) as amount,
   case when o.ready_at>=o.sent_at then extract(epoch from o.ready_at-o.sent_at)/60 end as cook_minutes,
   case when ac.at>=o.created_at then extract(epoch from ac.at-o.created_at) end as accept_seconds
  from public.rp_orders o
  left join lateral(select sum(i.quantity*i.unit_price_minor) total from public.rp_order_items i where i.cafe_id=c and i.order_id=o.id and i.cancelled_at is null) v on true
  left join lateral(select min(e.occurred_at) at from public.rp_order_events e where e.cafe_id=c and e.order_id=o.id and e.event_type='accept') ac on true
  where o.cafe_id=c and o.status<>'cancelled' and o.created_at>=history_start and o.created_at<t
 ),
 pb as materialized (
  select (p.recorded_at at time zone tz)::date d,extract(hour from p.recorded_at at time zone tz)::int hr,
   case when p.method='qr_transfer' then 'qr' else p.method end method,
   case when p.kind='refund' then -p.amount_minor else p.amount_minor end amount
  from public.rp_payments p where p.cafe_id=c and p.recorded_at>=history_start and p.recorded_at<t
 ),
 oa as (select d,count(*) n,coalesce(sum(accept_seconds),0) acc_sum,count(accept_seconds) acc_n,coalesce(sum(cook_minutes),0) cook_sum,count(cook_minutes) cook_n from ob group by d),
 ba as (select (closed_at at time zone tz)::date d,count(*) n from public.rp_bills where cafe_id=c and status='closed' and closed_at>=history_start and closed_at<t group by 1),
 pa as (select d,sum(amount) amount from pb group by d),
 wp as (select d,waiter_id,count(*) n,sum(amount) r,coalesce(sum(accept_seconds),0) a,count(accept_seconds) an,count(*) filter(where accept_seconds>45) late from ob group by d,waiter_id),
 wa as (select d,jsonb_object_agg(waiter_id::text,jsonb_build_object('n',n,'r',r,'acc',jsonb_build_array(a,an),'late',late)) val from wp group by d),
 ip as (select o.d,coalesce(i.menu_item_id::text,'history:'||i.id::text) k,sum(i.quantity) n from ob o join public.rp_order_items i on i.cafe_id=c and i.order_id=o.id and i.cancelled_at is null group by o.d,2),
 ia as (select d,jsonb_object_agg(k,n) val from ip group by d),
 lp as (select d,guest_lang,count(*) n from ob group by d,guest_lang),
 la as (select d,jsonb_object_agg(guest_lang,n) val from lp group by d),
 hp as (select d,hr,sum(amount) n from pb group by d,hr),
 ha as (select d,jsonb_object_agg(hr::text,n) val from hp group by d),
 pp as (select d,method,sum(amount) n from pb group by d,method),
 ppa as (select d,jsonb_object_agg(method,n) val from pp group by d),
 days as (select g::date d from generate_series(first_day-(last_day-first_day+1),last_day,interval '1 day') g),
 daily as (select days.d,jsonb_build_object('rev',coalesce(pa.amount,0),'bills',coalesce(ba.n,0),'orders',coalesce(oa.n,0),
  'acc',jsonb_build_array(coalesce(oa.acc_sum,0),coalesce(oa.acc_n,0)), 'cook',jsonb_build_array(coalesce(oa.cook_sum,0),coalesce(oa.cook_n,0)),
  'w',coalesce(wa.val,'{}'),'items',coalesce(ia.val,'{}'),'lang',coalesce(la.val,'{}'),'hrs',coalesce(ha.val,'{}'),
  'pay','{"cash":0,"card":0,"qr":0,"none":0}'::jsonb||coalesce(ppa.val,'{}')) val
  from days left join oa using(d) left join ba using(d) left join pa using(d) left join wa using(d) left join ia using(d) left join la using(d) left join ha using(d) left join ppa using(d))
 select jsonb_build_object('from',f,'to',t,'timezone',tz,'history_from',history_start,
  'orders',(select count(*) from ob where created_at>=f),
  'order_amount',(select coalesce(sum(amount),0) from ob where created_at>=f),
  'closed_bills',(select count(*) from public.rp_bills where cafe_id=c and status='closed' and closed_at>=f and closed_at<t),
  'recorded_payments',(select coalesce(sum(case when kind='refund' then -amount_minor else amount_minor end),0) from public.rp_payments where cafe_id=c and recorded_at>=f and recorded_at<t),
  'days',(select jsonb_object_agg(d::text,val order by d) from daily),
  'item_names',coalesce((select jsonb_object_agg(k,names) from (select distinct on(coalesce(i.menu_item_id::text,'history:'||i.id::text)) coalesce(i.menu_item_id::text,'history:'||i.id::text) k,i.name_snapshot names from ob o join public.rp_order_items i on i.cafe_id=c and i.order_id=o.id and i.cancelled_at is null order by coalesce(i.menu_item_id::text,'history:'||i.id::text),o.created_at desc,i.id) n),'{}'),
  'staff_names',coalesce((select jsonb_object_agg(waiter_id::text,waiter_name_snapshot) from (select distinct on(waiter_id) waiter_id,waiter_name_snapshot from ob order by waiter_id,created_at desc) n),'{}'),
  'definitions',jsonb_build_object('revenue','staff_recorded_payments_minus_refunds','orders','created_not_cancelled','waiter_amount','historical_order_amount','acceptance','actual_accept_event_only','cooking','sent_to_all_items_ready')) into result;
 return result;
end $$;

create function pg_temp.report_assert(ok boolean,msg text) returns void language plpgsql as $$begin if ok is distinct from true then raise exception 'REPORT_TEST_FAILED: %',msg;end if;end$$;
insert into auth.users(id) values('00000000-0000-4000-8000-000000000011'),('00000000-0000-4000-8000-000000000012');
insert into public.rp_cafes(id,slug,name) values('10000000-0000-4000-8000-000000000011','report-fixture-a','Report fixture'),('10000000-0000-4000-8000-000000000012','report-fixture-b','Other cafe');
insert into public.rp_memberships(cafe_id,user_id,role,display_name) values('10000000-0000-4000-8000-000000000011','00000000-0000-4000-8000-000000000011','owner','Report owner'),('10000000-0000-4000-8000-000000000011','00000000-0000-4000-8000-000000000012','waiter','Report waiter');
insert into public.rp_tables(id,cafe_id,label,seats) values('20000000-0000-4000-8000-000000000011','10000000-0000-4000-8000-000000000011','1',4);
insert into public.rp_menu_items(id,cafe_id,external_key,names,station,price_minor) values('30000000-0000-4000-8000-000000000011','10000000-0000-4000-8000-000000000011','report-fish','{"ru":"Рыба"}','kitchen',999000);
insert into public.rp_bills(id,cafe_id,table_id,status,currency,opened_at,closed_at) values('40000000-0000-4000-8000-000000000011','10000000-0000-4000-8000-000000000011','20000000-0000-4000-8000-000000000011','closed','VND','2026-11-05 18:00Z','2026-11-06 00:00Z');
insert into public.rp_checks(id,cafe_id,bill_id,label) values('50000000-0000-4000-8000-000000000011','10000000-0000-4000-8000-000000000011','40000000-0000-4000-8000-000000000011','Anna');
insert into public.rp_orders(id,cafe_id,bill_id,check_id,waiter_id,waiter_name_snapshot,status,request_id,number,created_at,sent_at,ready_at,served_at,guest_lang) values('60000000-0000-4000-8000-000000000011','10000000-0000-4000-8000-000000000011','40000000-0000-4000-8000-000000000011','50000000-0000-4000-8000-000000000011','00000000-0000-4000-8000-000000000012','Recorded waiter','served',gen_random_uuid(),1,'2026-11-05 18:00Z','2026-11-05 18:01Z','2026-11-05 18:10Z','2026-11-05 18:11Z','ru');
insert into public.rp_order_items(cafe_id,order_id,menu_item_id,name_snapshot,station,quantity,unit_price_minor) values('10000000-0000-4000-8000-000000000011','60000000-0000-4000-8000-000000000011','30000000-0000-4000-8000-000000000011','{"ru":"Рыба историческая"}','kitchen',2,100000);
insert into public.rp_order_items(cafe_id,order_id,name_snapshot,station,quantity,unit_price_minor,cancelled_at) values('10000000-0000-4000-8000-000000000011','60000000-0000-4000-8000-000000000011','{}','kitchen',10,999999,now());
insert into public.rp_order_events(cafe_id,order_id,actor_id,event_type,request_id,occurred_at) values('10000000-0000-4000-8000-000000000011','60000000-0000-4000-8000-000000000011','00000000-0000-4000-8000-000000000012','accept',gen_random_uuid(),'2026-11-05 18:00:30Z');
insert into public.rp_payments(cafe_id,bill_id,check_id,kind,method,amount_minor,recorded_by,request_id,recorded_at) values
('10000000-0000-4000-8000-000000000011','40000000-0000-4000-8000-000000000011','50000000-0000-4000-8000-000000000011','payment','qr_transfer',200000,'00000000-0000-4000-8000-000000000012',gen_random_uuid(),'2026-11-06 00:00Z'),
('10000000-0000-4000-8000-000000000011','40000000-0000-4000-8000-000000000011','50000000-0000-4000-8000-000000000011','refund','qr_transfer',10000,'00000000-0000-4000-8000-000000000012',gen_random_uuid(),'2026-11-06 00:01Z');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000011',true);
set local role authenticated;
do $$declare r jsonb;d jsonb;begin
 r:=public.rp_owner_stats('10000000-0000-4000-8000-000000000011','2026-11-05 17:00Z','2026-11-06 17:00Z');d:=r->'days'->'2026-11-06';
 perform pg_temp.report_assert((r->>'orders')::int=1,'order count');
 perform pg_temp.report_assert((r->>'order_amount')::bigint=200000,'snapshot price, not current menu; cancelled item excluded');
 perform pg_temp.report_assert((r->>'recorded_payments')::bigint=190000,'net recorded payments');
 perform pg_temp.report_assert((d->>'rev')::bigint=190000 and (d->>'bills')::int=1,'revenue and closed bills');
 perform pg_temp.report_assert(d->'items'->>'30000000-0000-4000-8000-000000000011'='2','top dishes quantities');
 perform pg_temp.report_assert(d->'lang'->>'ru'='1','guest language');
 perform pg_temp.report_assert(d->'pay'->>'qr'='190000','QR and refund');
 perform pg_temp.report_assert(d->'hrs'->>'7'='190000','local cafe hour');
 perform pg_temp.report_assert(d->'acc'='[30.000000, 1]'::jsonb and d->'cook'='[9.0000000000000000, 1]'::jsonb,'actual acceptance and cooking duration');
 perform pg_temp.report_assert(r->'days'->'2026-11-05'->>'orders'='0','previous period empty, no generated data');
 perform pg_temp.report_assert(r->'item_names'->'30000000-0000-4000-8000-000000000011'->>'ru'='Рыба историческая','historical name');
 begin perform public.rp_owner_stats('10000000-0000-4000-8000-000000000012','2026-11-05 17:00Z','2026-11-06 17:00Z');raise exception 'CROSS_CAFE_ALLOWED';exception when insufficient_privilege then null;end;
 begin perform public.rp_owner_stats('10000000-0000-4000-8000-000000000011','2026-11-07Z','2026-11-06Z');raise exception 'BAD_PERIOD_ALLOWED';exception when others then if sqlerrm<>'INVALID_PERIOD' then raise;end if;end;
end$$;
reset role;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000012',true);
set local role authenticated;
do $$begin begin perform public.rp_owner_stats('10000000-0000-4000-8000-000000000011','2026-11-05 17:00Z','2026-11-06 17:00Z');raise exception 'WAITER_REPORT_ALLOWED';exception when insufficient_privilege then null;end;end$$;
reset role;
rollback;
select 'PASS report: historical amounts, refund, timezone, periods, breakdowns, owner-only and tenant isolation; fixture rolled back' as result;
