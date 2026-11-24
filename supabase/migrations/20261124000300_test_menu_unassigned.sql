begin;
create function public.rp_test_entry_submit(entry_token text,r uuid,b jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare c uuid;old rp_private.web_orders;ck jsonb;line jsonb;item public.rp_menu_items;checks jsonb:='[]';lines jsonb;total integer:=0;
begin
 if entry_token is null or entry_token!~'^[a-f0-9]{64}$' or r is null or b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>60000 then raise exception 'INVALID_ORDER';end if;
 select cafe.id into c from public.rp_cafes cafe join rp_private.guest_test_entry e on e.cafe_id=cafe.id
 where cafe.slug='sun-sea' and cafe.active and cafe.archived_at is null and e.enabled and e.entry_token_hash=encode(sha256(convert_to(entry_token,'UTF8')),'hex') for update of cafe;
 if not found then raise exception 'TEST_ENTRY_DISABLED';end if;
 select * into old from rp_private.web_orders where id=r;
 if found then
  if old.cafe_id<>c or old.items->'request'<>b or old.items->>'entry_hash'<>encode(sha256(convert_to(entry_token,'UTF8')),'hex') then raise exception 'REQUEST_ID_REUSED';end if;
  return jsonb_build_object('ok',true,'id',r);
 end if;
 if jsonb_typeof(b->'checks') is distinct from 'array' or jsonb_array_length(b->'checks') not between 1 and 20 then raise exception 'INVALID_CHECKS';end if;
 if (select count(*) from rp_private.web_orders where cafe_id=c and created_at>now()-interval '1 hour')>=300 then raise exception 'RATE_LIMIT';end if;
 for ck in select value from jsonb_array_elements(b->'checks') loop
  if length(coalesce(ck->>'label','')) not between 1 and 80 or jsonb_typeof(ck->'items') is distinct from 'array' or jsonb_array_length(ck->'items')<1 then raise exception 'INVALID_CHECK';end if;
  lines:='[]';for line in select value from jsonb_array_elements(ck->'items') loop
   total:=total+1;if total>100 or coalesce((line->>'quantity')::integer,0) not between 1 and 99 or length(coalesce(line->>'note',''))>300 then raise exception 'INVALID_ITEM';end if;
   select * into item from public.rp_menu_items where cafe_id=c and external_key=line->>'key' and active and not stopped and price_minor is not null;
   if not found then raise exception 'ITEM_UNAVAILABLE';end if;
   lines:=lines||jsonb_build_array(jsonb_build_object('id',item.id,'names',item.names,'price',item.price_minor,'quantity',(line->>'quantity')::integer,'note',coalesce(line->>'note','')));
  end loop;
  checks:=checks||jsonb_build_array(jsonb_build_object('id',gen_random_uuid(),'label',ck->>'label','items',lines));
 end loop;
 insert into rp_private.web_orders(id,cafe_id,channel,phone,items) values(r,c,'table',null,jsonb_build_object('request',b,'checks',checks,'lang',coalesce(b->>'lang','ru'),'entry_hash',encode(sha256(convert_to(entry_token,'UTF8')),'hex')));
 return jsonb_build_object('ok',true,'id',r);
end $$;
create or replace function public.rp_web_pending(c uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;
begin
 m:=rp_private.require_member(c);if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',w.id,'created_at',w.created_at,'table','—','channel',w.channel,'phone',w.phone,'lang',coalesce(w.items->>'lang','ru'),'checks',coalesce(w.items->'checks',jsonb_build_array(jsonb_build_object('id',w.id,'label','Общий счёт','items',w.items->'quote'))))) from rp_private.web_orders w where w.cafe_id=c and w.accepted_at is null and w.rejected_at is null),'[]');
end $$;
revoke all on function public.rp_test_entry_submit(text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.rp_test_entry_submit(text,uuid,jsonb) to anon,authenticated;
commit;
