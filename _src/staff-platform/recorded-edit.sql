begin;
create or replace function rp_private.edit_recorded_order(c uuid,r uuid,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;o public.rp_orders;rec rp_private.receipts;previous jsonb;x jsonb;oldline jsonb;item public.rp_menu_items;line uuid;result jsonb;ver bigint;used uuid[]:='{}';
begin
 if r is null or b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>65000 then raise exception 'INVALID_COMMAND';end if;
 perform 1 from public.rp_cafes where id=c for update;m:=rp_private.require_member(c);
 if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 select * into rec from rp_private.receipts where cafe_id=c and request_id=r;if found then if rec.actor_id<>auth.uid() or rec.action<>'order_edit' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return rec.result;end if;
 select * into o from public.rp_orders where cafe_id=c and id=(b->>'order_id')::uuid for update;if not found then raise exception 'ORDER_NOT_FOUND';end if;
 if m.role='waiter' and o.waiter_id<>auth.uid() then raise exception 'ORDER_NOT_ASSIGNED' using errcode='42501';end if;
 if o.status<>'accepted' then raise exception 'ORDER_ALREADY_SENT';end if;
 if not exists(select 1 from public.rp_bills where cafe_id=c and id=o.bill_id and status='open') then raise exception 'BILL_CLOSED';end if;
 if b->>'version' is null or o.version<>(b->>'version')::bigint then raise exception 'VERSION_CONFLICT' using errcode='40001';end if;
 if jsonb_typeof(b->'items') is distinct from 'array' or jsonb_array_length(b->'items') not between 1 and 100 then raise exception 'INVALID_ITEMS';end if;
 select jsonb_agg(to_jsonb(i)) into previous from public.rp_order_items i where i.cafe_id=c and i.order_id=o.id and i.cancelled_at is null;
 delete from public.rp_order_items where cafe_id=c and order_id=o.id;
 for x in select value from jsonb_array_elements(b->'items') loop
  oldline:=null;if x->>'line_id' is not null then
   select value into oldline from jsonb_array_elements(coalesce(previous,'[]')) where value->>'id'=x->>'line_id';
   if oldline is null or oldline->>'menu_item_id'<>x->>'id' or (x->>'line_id')::uuid=any(used) then raise exception 'INVALID_LINE';end if;used:=array_append(used,(x->>'line_id')::uuid);
  end if;
  if oldline is not null then
   insert into public.rp_order_items(id,cafe_id,order_id,menu_item_id,name_snapshot,station,quantity,unit_price_minor,note) values((oldline->>'id')::uuid,c,o.id,(oldline->>'menu_item_id')::uuid,oldline->'name_snapshot',oldline->>'station',(x->>'quantity')::integer,(oldline->>'unit_price_minor')::bigint,coalesce(x->>'note',''));
  else
   select * into item from public.rp_menu_items where cafe_id=c and id=(x->>'id')::uuid and active and not stopped;if not found or item.price_minor is null then raise exception 'ITEM_UNAVAILABLE';end if;
   insert into public.rp_order_items(cafe_id,order_id,menu_item_id,name_snapshot,station,quantity,unit_price_minor,note) values(c,o.id,item.id,item.names,item.station,(x->>'quantity')::integer,item.price_minor,coalesce(x->>'note',''));
  end if;
 end loop;
 update public.rp_orders set comment=coalesce(b->>'comment',''),wishes=coalesce(b->'wishes','[]'),version=version+1,status=case when coalesce((b->>'send')::boolean,false) then 'cooking' else 'accepted' end,sent_at=case when coalesce((b->>'send')::boolean,false) then now() else null end where id=o.id and cafe_id=c returning version into ver;
 insert into public.rp_order_events(cafe_id,order_id,actor_id,event_type,payload,request_id) values(c,o.id,auth.uid(),'order_edit',b,r);
 result:=jsonb_build_object('ok',true,'request_id',r,'order_id',o.id,'version',ver);insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'order_edit',b,result);return result;
end $$;
revoke all on function rp_private.edit_recorded_order(uuid,uuid,jsonb) from public,anon,authenticated;
create or replace function rp_private.operational_command(c uuid,r uuid,a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;begin
 perform 1 from public.rp_cafes where id=c for update;m:=rp_private.require_member(c);
 if a='order_edit' then return rp_private.edit_recorded_order(c,r,b);end if;
 if a='design' then return rp_private.set_cafe_design(c,r,b);end if;
 if a='serve' then return rp_private.serve_station(c,r,b);end if;
 if a not in ('order_create','send','station_ready','item_ready','bill_close','stop') or a is null then raise exception 'UNKNOWN_COMMAND';end if;
 if a='item_ready' and coalesce((b->>'ready')::boolean,true)=false and exists(select 1 from public.rp_order_items where cafe_id=c and order_id=(b->>'order_id')::uuid and id=(b->>'item_id')::uuid and served_at is not null) then raise exception 'ITEM_ALREADY_SERVED';end if;
 return rp_private.command(c,r,a,b);
end $$;
commit;
