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
