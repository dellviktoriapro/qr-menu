-- Cafe-wide appearance preference, closed until the reviewed operational API grant.
begin;
alter table public.rp_cafes add column design text not null default 'atelier' check(design in ('pine','atelier','wine','sage','coast'));
create function rp_private.operational_snapshot(c uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 result:=rp_private.snapshot(c);
 return jsonb_set(result,'{cafe}',(result->'cafe')||jsonb_build_object('design',(select design from public.rp_cafes where id=c)));
end $$;
create function rp_private.set_cafe_design(c uuid,r uuid,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;rec rp_private.receipts;result jsonb;
begin
 if r is null or b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>1024 then raise exception 'INVALID_COMMAND';end if;
 perform 1 from public.rp_cafes where id=c for update;
 m:=rp_private.require_member(c);
 if m.role not in ('owner','manager') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 select * into rec from rp_private.receipts where cafe_id=c and request_id=r;
 if found then
  if rec.actor_id<>auth.uid() or rec.action<>'design' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;
  return rec.result;
 end if;
 if b->>'design' is null or b->>'design' not in ('pine','atelier','wine','sage','coast') then raise exception 'INVALID_DESIGN';end if;
 update public.rp_cafes set design=b->>'design' where id=c;
 result:=jsonb_build_object('ok',true,'request_id',r,'design',b->>'design');
 insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'design',b,result);
 return result;
end $$;
create or replace function rp_private.operational_command(c uuid,r uuid,a text,b jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;
begin
 perform 1 from public.rp_cafes where id=c for update;
 m:=rp_private.require_member(c);
 if a='design' then return rp_private.set_cafe_design(c,r,b);end if;
 if a='serve' then return rp_private.serve_station(c,r,b);end if;
 if a not in ('order_create','order_edit','send','station_ready','item_ready','bill_close','stop') or a is null then raise exception 'UNKNOWN_COMMAND';end if;
 if a='item_ready' and coalesce((b->>'ready')::boolean,true)=false and exists(select 1 from public.rp_order_items where cafe_id=c and order_id=(b->>'order_id')::uuid and id=(b->>'item_id')::uuid and served_at is not null) then raise exception 'ITEM_ALREADY_SERVED';end if;
 return rp_private.command(c,r,a,b);
end $$;
create function public.rp_operational_snapshot(c uuid) returns jsonb language sql security invoker set search_path='' as $$select rp_private.operational_snapshot(c)$$;
revoke all on function rp_private.operational_snapshot(uuid),rp_private.set_cafe_design(uuid,uuid,jsonb),public.rp_operational_snapshot(uuid) from public,anon,authenticated;
commit;
