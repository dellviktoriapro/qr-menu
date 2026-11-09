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
  return g.result||jsonb_build_object('checks',g.items_snapshot,'created_at',g.created_at,'accepted',g.accepted_at is not null,'closed',not exists(select 1 from public.rp_bills where cafe_id=v.cafe_id and id=v.bill_id and status='open'),'states',coalesce((select jsonb_agg(jsonb_build_object('id',o.id,'number',o.number,'waiter',o.waiter_name_snapshot,'check',(select label from public.rp_checks where id=o.check_id and cafe_id=o.cafe_id),'status',o.status,'stations',(select jsonb_agg(jsonb_build_object('station',i.station,'ready',i.ready_at is not null,'served',i.served_at is not null)) from public.rp_order_items i where i.cafe_id=o.cafe_id and i.order_id=o.id and i.cancelled_at is null))) from public.rp_orders o where o.cafe_id=v.cafe_id and g.order_ids ? o.id::text),'[]'));
 end if;
 raise exception 'UNKNOWN_ACTION';
end $$;
