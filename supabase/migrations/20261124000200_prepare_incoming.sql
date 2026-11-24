begin;
-- Preserve guest quotes; staff may annotate lines when accepting, never set prices.
create function public.rp_prepare_incoming(c uuid,r uuid,b jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;w rp_private.web_orders;g rp_private.guest_submissions;
 rec rp_private.receipts;checks jsonb;edited jsonb;ck jsonb;line jsonb;lines jsonb;
 result jsonb;one jsonb;ids jsonb:='[]';ci integer;ii integer;n text;note text;prefix text;comment text;wishes jsonb;
begin
 perform 1 from public.rp_cafes where id=c for update;m:=rp_private.require_member(c);
 if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 if r is null or b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>65000 then raise exception 'INVALID_COMMAND';end if;
 select * into rec from rp_private.receipts where cafe_id=c and request_id=r;
 if found then
  if rec.actor_id<>auth.uid() or rec.action<>'prepare_incoming' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return rec.result;
 end if;
 comment:=coalesce(b->>'comment','');wishes:=coalesce(b->'wishes','[]');
 if length(comment)>800 or jsonb_typeof(wishes)<>'array' or jsonb_array_length(wishes)>12 or exists(select 1 from jsonb_array_elements_text(wishes) x where x not in ('noice','nosugar','nospicy','nocil','together','kid','spicy')) then raise exception 'INVALID_NOTES';end if;
 select * into w from rp_private.web_orders where cafe_id=c and id=(b->>'submission_id')::uuid for update;
 if found then
  if w.accepted_at is not null or w.rejected_at is not null then raise exception 'SUBMISSION_UNAVAILABLE';end if;
  checks:=coalesce(w.items->'checks',jsonb_build_array(jsonb_build_object('label','Общий счёт','items',w.items->'quote')));
 else
  select * into g from rp_private.guest_submissions where cafe_id=c and id=(b->>'submission_id')::uuid for update;
  if not found or g.accepted_at is not null or g.rejected_at is not null then raise exception 'SUBMISSION_UNAVAILABLE';end if;
  checks:=g.items_snapshot;
 end if;
 edited:=checks;
 if jsonb_typeof(b->'checks') is distinct from 'array' or jsonb_array_length(b->'checks')<>jsonb_array_length(checks) then raise exception 'INVALID_CHECKS';end if;
 for ci in 0..jsonb_array_length(checks)-1 loop
  if jsonb_typeof(b->'checks'->ci->'items') is distinct from 'array' or jsonb_array_length(b->'checks'->ci->'items')<>jsonb_array_length(checks->ci->'items') then raise exception 'INVALID_ITEMS';end if;
  for ii in 0..jsonb_array_length(checks->ci->'items')-1 loop
   note:=coalesce(b->'checks'->ci->'items'->ii->>'note','');
   if length(note)>300 then raise exception 'INVALID_NOTES';end if;
   edited:=jsonb_set(edited,array[ci::text,'items',ii::text,'note'],to_jsonb(note));
  end loop;
 end loop;
 if w.id is not null then
  n:=b->>'table';if not exists(select 1 from public.rp_tables where cafe_id=c and label=n and active) then raise exception 'TABLE_NOT_FOUND';end if;
  prefix:=case when w.channel='online' then 'ОНЛАЙН ЗАКАЗ' else 'ЗАКАЗ ПО QR' end||case when w.phone is not null then ' · '||w.phone else '' end;
  for ck in select value from jsonb_array_elements(edited) loop
   lines:='[]';for line in select value from jsonb_array_elements(ck->'items') loop
    if not exists(select 1 from public.rp_menu_items where cafe_id=c and id=(line->>'id')::uuid and active and not stopped and price_minor=(line->>'price')::bigint) then raise exception 'ITEM_OR_PRICE_CHANGED';end if;
    lines:=lines||jsonb_build_array(jsonb_build_object('id',line->>'id','quantity',line->'quantity','note',line->>'note'));
   end loop;
   one:=rp_private.command(c,gen_random_uuid(),'order_create',jsonb_build_object('table',n,'check',ck->>'label','lang',coalesce(w.items->>'lang','ru'),'items',lines,'send',true,'comment',prefix||case when comment<>'' then chr(10)||comment else '' end,'wishes',wishes));
   ids:=ids||jsonb_build_array(one->>'order_id');
  end loop;
  update rp_private.web_orders set accepted_at=clock_timestamp(),accepted_by=auth.uid(),order_id=(ids->>0)::uuid,items=items||jsonb_build_object('staff_checks',edited,'staff_comment',comment,'staff_wishes',wishes) where id=w.id;
 else
  update rp_private.guest_submissions set items_snapshot=edited where id=g.id;
  one:=rp_private.accept_guest(c,gen_random_uuid(),jsonb_build_object('submission_id',g.id));ids:=one->'order_ids';
  update public.rp_orders set comment=coalesce(b->>'comment',''),wishes=coalesce(b->'wishes','[]') where cafe_id=c and id in (select x::uuid from jsonb_array_elements_text(ids) x);
 end if;
 result:=jsonb_build_object('ok',true,'order_ids',ids,'request_id',r);
 insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'prepare_incoming',b,result);
 return result;
end $$;
revoke all on function public.rp_prepare_incoming(uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.rp_prepare_incoming(uuid,uuid,jsonb) to authenticated;
commit;
