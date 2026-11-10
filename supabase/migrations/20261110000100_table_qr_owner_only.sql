-- Only the cafe owner may create or reissue guest table QR codes.
create or replace function rp_private.guest_staff(c uuid,r uuid,a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;secret text;t uuid;v rp_private.guest_visits;g rp_private.guest_submissions;rec rp_private.receipts;result jsonb;
begin
 perform 1 from public.rp_cafes where id=c for update;m:=rp_private.require_member(c);
 if a='pending' and m.role in ('owner','manager','waiter') then return coalesce((select jsonb_agg(jsonb_build_object('id',gs.id,'created_at',gs.created_at,'table',gt.label,'lang',gs.body->>'lang','checks',gs.items_snapshot)) from rp_private.guest_submissions gs join rp_private.guest_visits gv on gv.id=gs.visit_id join public.rp_tables gt on gt.id=gv.table_id and gt.cafe_id=gs.cafe_id where gs.cafe_id=c and gs.accepted_at is null and gs.rejected_at is null and gv.closed_at is null and gv.expires_at>now() and exists(select 1 from public.rp_bills where id=gv.bill_id and cafe_id=c and status='open')),'[]');end if;
 if a='reject' and m.role in ('owner','manager','waiter') then
  if r is null then raise exception 'REQUEST_ID_REQUIRED';end if;
  select * into rec from rp_private.receipts where cafe_id=c and request_id=r;if found then if rec.actor_id<>auth.uid() or rec.action<>'guest:reject' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return rec.result;end if;
  select * into g from rp_private.guest_submissions where cafe_id=c and id=(b->>'submission_id')::uuid for update;
  if not found or g.accepted_at is not null then raise exception 'SUBMISSION_UNAVAILABLE';end if;
  update rp_private.guest_submissions set rejected_at=coalesce(rejected_at,clock_timestamp()) where id=g.id;
  result:=jsonb_build_object('ok',true,'request_id',r);insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'guest:reject',b,result);return result;
 end if;
 if a='accept' then
  select s.* into g from rp_private.guest_submissions s where s.id=(b->>'submission_id')::uuid and s.cafe_id=c;
  select * into v from rp_private.guest_visits where id=g.visit_id;
  if not exists(select 1 from public.rp_bills where id=v.bill_id and cafe_id=c and status='open') then
   -- A previously acknowledged acceptance may still be retried after payment.
   if not exists(select 1 from rp_private.receipts where cafe_id=c and request_id=r and actor_id=auth.uid() and action='accept_guest' and body=b) then raise exception 'VISIT_CLOSED';end if;
  end if;
  return rp_private.accept_guest(c,r,b);
 end if;
 if a='table_link' and m.role='owner' then
  if r is null then raise exception 'REQUEST_ID_REQUIRED';end if;
  select * into rec from rp_private.receipts where cafe_id=c and request_id=r;if found then if rec.actor_id<>auth.uid() or rec.action<>'guest:table_link' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return rec.result;end if;
  t:=(b->>'table_id')::uuid;if not exists(select 1 from public.rp_tables where cafe_id=c and id=t and active) then raise exception 'TABLE_NOT_FOUND';end if;
  if exists(select 1 from rp_private.guest_table_links where table_id=t) and coalesce((b->>'replace')::boolean,false)=false then raise exception 'LINK_EXISTS_CONFIRM_REISSUE';end if;
  secret:=replace(gen_random_uuid()::text,'-','')||replace(gen_random_uuid()::text,'-','');
  insert into rp_private.guest_table_links(cafe_id,table_id,token_hash) values(c,t,encode(sha256(convert_to(secret,'UTF8')),'hex')) on conflict(table_id) do update set token_hash=excluded.token_hash,created_at=now();
  update rp_private.guest_visits set closed_at=now() where cafe_id=c and table_id=t and closed_at is null;
  result:=jsonb_build_object('table_token',secret,'table',(select label from public.rp_tables where id=t));
  insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'guest:table_link',b,(result-'table_token')||'{"reissue_required":true}');return result;
 end if;
 raise exception 'ROLE_DENIED' using errcode='42501';
end $$;
