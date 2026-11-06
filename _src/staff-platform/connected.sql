-- Versioned change for development; remains closed until enable-api.sql is approved.
begin;
create schema if not exists rp_private;
revoke all on schema rp_private from public,anon,authenticated;
alter table public.rp_cafes add column next_order_no bigint not null default 1;
alter table public.rp_orders add column number bigint not null default 0;
alter table public.rp_orders add column comment text not null default '' check(length(comment)<=1000);
alter table public.rp_orders add column wishes jsonb not null default '[]' check(jsonb_typeof(wishes)='array');
alter table public.rp_orders add column guest_lang text not null default 'vi';
create unique index rp_order_number on public.rp_orders(cafe_id,number);
create table rp_private.receipts(
 cafe_id uuid not null references public.rp_cafes(id), request_id uuid not null,
 actor_id uuid not null references auth.users(id), action text not null, body jsonb not null,
 result jsonb not null, created_at timestamptz not null default now(), primary key(cafe_id,request_id)
);
alter table rp_private.receipts enable row level security;

create function rp_private.require_member(c uuid) returns public.rp_memberships
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED' using errcode='42501'; end if;
 select * into m from public.rp_memberships where cafe_id=c and user_id=auth.uid() and active for share;
 if not found or not exists(select 1 from public.rp_cafes where id=c and active) then
  raise exception 'ACCESS_DENIED' using errcode='42501'; end if;
 return m;
end $$;

create function rp_private.my_cafes() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',c.id,'name',c.name,'role',m.role,'display_name',m.display_name))
 from public.rp_memberships m join public.rp_cafes c on c.id=m.cafe_id
 where m.user_id=auth.uid() and m.active and c.active),'[]');
end $$;

create function rp_private.snapshot(c uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships; result jsonb;
begin
 m:=rp_private.require_member(c);
 select jsonb_build_object(
 'cafe',(select jsonb_build_object('id',id,'name',name,'currency',currency,'timezone',timezone) from public.rp_cafes where id=c),
 'me',jsonb_build_object('id',m.user_id,'name',m.display_name,'role',m.role),
 'staff',coalesce((select jsonb_agg(jsonb_build_object('id',user_id,'name',display_name,'role',role,'active',active)) from public.rp_memberships where cafe_id=c),'[]'),
 'tables',coalesce((select jsonb_agg(to_jsonb(t)) from public.rp_tables t where cafe_id=c and active),'[]'),
 'menu',coalesce((select jsonb_agg(to_jsonb(t)) from public.rp_menu_items t where cafe_id=c),'[]'),
 'bills',coalesce((select jsonb_agg(to_jsonb(t)) from public.rp_bills t where cafe_id=c and (status='open' or closed_at>now()-interval '1 day')),'[]'),
 'checks',coalesce((select jsonb_agg(to_jsonb(t)) from public.rp_checks t join public.rp_bills b on b.cafe_id=t.cafe_id and b.id=t.bill_id where t.cafe_id=c and (b.status='open' or b.closed_at>now()-interval '1 day')),'[]'),
 'orders',coalesce((select jsonb_agg(to_jsonb(t)||jsonb_build_object('items',coalesce((select jsonb_agg(to_jsonb(i) order by i.id) from public.rp_order_items i where i.cafe_id=c and i.order_id=t.id),'[]'))) from public.rp_orders t join public.rp_bills b on b.id=t.bill_id and b.cafe_id=t.cafe_id where t.cafe_id=c and (b.status='open' or b.closed_at>now()-interval '1 day')),'[]'),
 'server_at',clock_timestamp()) into result;
 return result;
end $$;

create function rp_private.command(c uuid,r uuid,a text,b jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships; o public.rp_orders; bill public.rp_bills; item public.rp_menu_items;
 rec rp_private.receipts; result jsonb; x jsonb; oid uuid; bid uuid; ckid uuid; tid uuid; total bigint; n bigint;
 v_station text; ck text; method text; target uuid; ver bigint;
begin
 if r is null or a is null or b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>65536 then raise exception 'INVALID_COMMAND'; end if;
 -- Serialize a restaurant's commands, including retries and table-visit creation.
 perform 1 from public.rp_cafes where id=c for update;
 m:=rp_private.require_member(c);
 select * into rec from rp_private.receipts where cafe_id=c and request_id=r;
 if found then
  if rec.actor_id<>auth.uid() or rec.action<>a or rec.body<>b then raise exception 'REQUEST_ID_REUSED'; end if;
  return rec.result;
 end if;
 if a in ('order_create','order_edit','send','serve','bill_close') and m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501'; end if;
 if a in ('menu_put','table_put','member_set') and m.role not in ('owner','manager') then raise exception 'ROLE_DENIED' using errcode='42501'; end if;
 if a='order_create' then
  select id into tid from public.rp_tables where cafe_id=c and label=b->>'table' and active;
  if tid is null then raise exception 'TABLE_NOT_FOUND'; end if;
  select * into bill from public.rp_bills where cafe_id=c and table_id=tid and status='open' for update;
  bid:=bill.id;
  if bid is null then
   insert into public.rp_bills(cafe_id,table_id,currency) select c,tid,currency from public.rp_cafes where id=c returning id into bid;
  end if;
  ck:=coalesce(nullif(b->>'check',''),'Общий счёт');
  select id into ckid from public.rp_checks where cafe_id=c and bill_id=bid and label=ck;
  if ckid is null then insert into public.rp_checks(cafe_id,bill_id,label) values(c,bid,ck) returning id into ckid; end if;
  update public.rp_cafes set next_order_no=next_order_no+1 where id=c returning next_order_no-1 into n;
  insert into public.rp_orders(cafe_id,bill_id,check_id,waiter_id,waiter_name_snapshot,request_id,number,comment,wishes,guest_lang)
  values(c,bid,ckid,auth.uid(),m.display_name,r,n,coalesce(b->>'comment',''),coalesce(b->'wishes','[]'),coalesce(b->>'lang','vi')) returning id into oid;
 elsif a in ('order_edit','send','station_ready','item_ready','serve') then
  oid:=(b->>'order_id')::uuid;
  select * into o from public.rp_orders where cafe_id=c and id=oid for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if not exists(select 1 from public.rp_bills where cafe_id=c and id=o.bill_id and status='open') then raise exception 'BILL_CLOSED'; end if;
  if (b->>'version') is null or o.version<>(b->>'version')::bigint then raise exception 'VERSION_CONFLICT' using errcode='40001'; end if;
  if m.role='waiter' and o.waiter_id<>auth.uid() then raise exception 'ORDER_NOT_ASSIGNED' using errcode='42501'; end if;
  if a='order_edit' and o.status<>'accepted' then raise exception 'ORDER_ALREADY_SENT'; end if;
 end if;
 if a in ('order_create','order_edit') then
  if jsonb_typeof(b->'items') is distinct from 'array' or jsonb_array_length(b->'items') not between 1 and 100 then raise exception 'INVALID_ITEMS'; end if;
  if a='order_edit' then
   -- No prep items can be removed after sending; accepted draft only.
   delete from public.rp_order_items where cafe_id=c and order_id=oid;
   update public.rp_orders set comment=coalesce(b->>'comment',''),wishes=coalesce(b->'wishes','[]') where id=oid and cafe_id=c;
  end if;
  for x in select value from jsonb_array_elements(b->'items') loop
   select * into item from public.rp_menu_items where cafe_id=c and id=(x->>'id')::uuid and active and not stopped;
   if not found or item.price_minor is null then raise exception 'ITEM_UNAVAILABLE'; end if;
   insert into public.rp_order_items(cafe_id,order_id,menu_item_id,name_snapshot,station,quantity,unit_price_minor,note)
   values(c,oid,item.id,item.names,item.station,(x->>'quantity')::integer,item.price_minor,coalesce(x->>'note',''));
  end loop;
  if coalesce((b->>'send')::boolean,false) then update public.rp_orders set status='cooking',sent_at=clock_timestamp() where cafe_id=c and id=oid; end if;
 elsif a='send' then
  if o.status<>'accepted' then raise exception 'INVALID_TRANSITION'; end if;
  update public.rp_orders set status='cooking',sent_at=clock_timestamp() where cafe_id=c and id=oid;
 elsif a in ('station_ready','item_ready') then
  if m.role not in ('owner','manager','kitchen','bar') then raise exception 'ROLE_DENIED' using errcode='42501'; end if;
  if o.status<>'cooking' then raise exception 'INVALID_TRANSITION'; end if;
  v_station:=b->>'station';
  if v_station is null or v_station not in ('kitchen','bar') or (m.role in ('kitchen','bar') and m.role<>v_station) then raise exception 'STATION_DENIED' using errcode='42501'; end if;
  if a='station_ready' then
   update public.rp_order_items set ready_at=coalesce(ready_at,clock_timestamp()) where cafe_id=c and order_id=oid and rp_order_items.station=v_station and cancelled_at is null;
   if not found then raise exception 'NO_STATION_ITEMS'; end if;
  else
   update public.rp_order_items set ready_at=case when coalesce((b->>'ready')::boolean,true) then clock_timestamp() else null end
   where cafe_id=c and order_id=oid and id=(b->>'item_id')::uuid and rp_order_items.station=v_station and cancelled_at is null;
   if not found then raise exception 'ITEM_NOT_FOUND'; end if;
  end if;
  if not exists(select 1 from public.rp_order_items where cafe_id=c and order_id=oid and cancelled_at is null and ready_at is null) then
   update public.rp_orders set status='ready',ready_at=clock_timestamp() where cafe_id=c and id=oid;
  end if;
 elsif a='serve' then
  if o.status<>'ready' then raise exception 'ORDER_NOT_READY'; end if;
  update public.rp_orders set status='served',served_at=clock_timestamp() where cafe_id=c and id=oid;
 elsif a='bill_close' then
  bid:=(b->>'bill_id')::uuid;select * into bill from public.rp_bills where cafe_id=c and id=bid for update;
  if not found or bill.status<>'open' then raise exception 'BILL_NOT_OPEN'; end if;
  if b->>'version' is null or bill.version<>(b->>'version')::bigint then raise exception 'VERSION_CONFLICT' using errcode='40001'; end if;
  if m.role='waiter' and exists(select 1 from public.rp_orders where cafe_id=c and bill_id=bid and waiter_id<>auth.uid()) then raise exception 'BILL_NOT_ASSIGNED'; end if;
  if exists(select 1 from public.rp_orders where cafe_id=c and bill_id=bid and status not in ('served','cancelled')) then raise exception 'UNSERVED_ORDERS'; end if;
  for ckid in select id from public.rp_checks where cafe_id=c and bill_id=bid loop
   select sum(i.quantity*i.unit_price_minor) into total from public.rp_order_items i join public.rp_orders oo on oo.id=i.order_id and oo.cafe_id=i.cafe_id
   where oo.cafe_id=c and oo.bill_id=bid and oo.check_id=ckid and oo.status<>'cancelled' and i.cancelled_at is null;
   if total>0 then
    method:=b->'payments'->>ckid::text;
    if method is null or method not in ('cash','card','qr_transfer') then raise exception 'PAYMENT_METHOD_REQUIRED'; end if;
    insert into public.rp_payments(cafe_id,bill_id,check_id,kind,method,amount_minor,recorded_by,request_id) values(c,bid,ckid,'payment',method,total,auth.uid(),gen_random_uuid());
   end if;
  end loop;
  update public.rp_bills set status='closed',closed_at=clock_timestamp(),version=version+1 where cafe_id=c and id=bid;
 elsif a='stop' then
  if m.role not in ('owner','manager','kitchen','bar') then raise exception 'ROLE_DENIED'; end if;
  update public.rp_menu_items set stopped=(b->>'stopped')::boolean where cafe_id=c and id=(b->>'item_id')::uuid and (m.role in ('owner','manager') or rp_menu_items.station=m.role);
  if not found then raise exception 'ITEM_NOT_FOUND'; end if;
 elsif a='member_set' then
  target:=(b->>'user_id')::uuid;
  if target=auth.uid() then raise exception 'SELF_ROLE_CHANGE_DENIED'; end if;
  if m.role<>'owner' or b->>'role' not in ('manager','waiter','kitchen','bar') then raise exception 'ROLE_DENIED'; end if;
  update public.rp_memberships set role=b->>'role',active=(b->>'active')::boolean where cafe_id=c and user_id=target and role<>'owner';
  if not found then raise exception 'MEMBER_NOT_FOUND'; end if;
 elsif a='menu_put' then
  insert into public.rp_menu_items(cafe_id,external_key,names,station,price_minor) values(c,b->>'key',b->'names',b->>'station',(b->>'price')::bigint)
  on conflict(cafe_id,external_key) do update set names=excluded.names,station=excluded.station,price_minor=excluded.price_minor;
 elsif a='table_put' then
  insert into public.rp_tables(cafe_id,label,seats) values(c,b->>'label',(b->>'seats')::int)
  on conflict(cafe_id,label) do update set seats=excluded.seats;
 elsif a not in ('order_create','order_edit') then raise exception 'UNKNOWN_COMMAND';
 end if;
 if oid is not null then
  update public.rp_orders set version=version+1 where cafe_id=c and id=oid returning version into ver;
  insert into public.rp_order_events(cafe_id,order_id,actor_id,event_type,payload,request_id) values(c,oid,auth.uid(),a,b,r);
 end if;
 result:=jsonb_build_object('ok',true,'order_id',oid,'bill_id',bid,'version',ver,'request_id',r);
 insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),a,b,result);
 return result;
end $$;

create function public.rp_my_cafes() returns jsonb language sql security invoker set search_path='' as $$select rp_private.my_cafes()$$;
create function public.rp_snapshot(c uuid) returns jsonb language sql security invoker set search_path='' as $$select rp_private.snapshot(c)$$;
create function public.rp_command(c uuid,r uuid,a text,b jsonb) returns jsonb language sql security invoker set search_path='' as $$select rp_private.command(c,r,a,b)$$;
revoke all on all functions in schema rp_private from public,anon,authenticated;
revoke all on function public.rp_my_cafes(),public.rp_snapshot(uuid),public.rp_command(uuid,uuid,text,jsonb) from public,anon,authenticated;
commit;
select 'COMMANDS_INSTALLED_CLOSED' as result;
