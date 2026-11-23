-- Accepting a guest order immediately sends its kitchen and bar items to work.
begin;
create or replace function rp_private.accept_guest(c uuid,r uuid,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;g rp_private.guest_submissions;v rp_private.guest_visits;rec rp_private.receipts;ck jsonb;x jsonb;lines jsonb;result jsonb;one jsonb;ids jsonb:='[]';label text;
begin
 perform 1 from public.rp_cafes where id=c for update;m:=rp_private.require_member(c);if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 if r is null or b is null or jsonb_typeof(b)<>'object' then raise exception 'INVALID_REQUEST';end if;
 select * into rec from rp_private.receipts where cafe_id=c and request_id=r;if found then if rec.actor_id<>auth.uid() or rec.action<>'accept_guest' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return rec.result;end if;
 select * into g from rp_private.guest_submissions where cafe_id=c and id=(b->>'submission_id')::uuid for update;if not found or g.accepted_at is not null or g.rejected_at is not null then raise exception 'SUBMISSION_UNAVAILABLE';end if;
 select * into v from rp_private.guest_visits where id=g.visit_id;
 if v.closed_at is not null or v.expires_at<=now() then raise exception 'VISIT_UNAVAILABLE';end if;
 select t.label into label from public.rp_tables t where t.cafe_id=c and t.id=v.table_id and active;if label is null then raise exception 'TABLE_NOT_FOUND';end if;
 for ck in select value from jsonb_array_elements(g.items_snapshot) loop
  lines:='[]';for x in select value from jsonb_array_elements(ck->'items') loop
   if not exists(select 1 from public.rp_menu_items where cafe_id=c and id=(x->>'id')::uuid and active and not stopped and price_minor=(x->>'price')::bigint) then raise exception 'ITEM_OR_PRICE_CHANGED';end if;
   lines:=lines||jsonb_build_array(jsonb_build_object('id',x->>'id','quantity',x->'quantity','note',x->>'note'));
  end loop;
  one:=rp_private.command(c,gen_random_uuid(),'order_create',jsonb_build_object('table',label,'check',ck->>'label','lang',g.body->>'lang','items',lines,'send',true));
  update public.rp_orders set created_at=g.created_at where cafe_id=c and id=(one->>'order_id')::uuid;
  insert into public.rp_order_events(cafe_id,order_id,actor_id,event_type,payload,request_id) values(c,(one->>'order_id')::uuid,auth.uid(),'accept',jsonb_build_object('submission_id',g.id),gen_random_uuid());ids:=ids||jsonb_build_array(one->>'order_id');
 end loop;
 update rp_private.guest_submissions set accepted_by=auth.uid(),accepted_at=clock_timestamp(),order_ids=ids where id=g.id;
 result:=jsonb_build_object('ok',true,'request_id',r,'order_ids',ids);
 insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'accept_guest',b,result);return result;
end $$;
commit;

