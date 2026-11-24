begin;
create function public.rp_bill_issue(c uuid,r uuid,b jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships; bl public.rp_bills; rec rp_private.receipts; result jsonb;
begin
 perform 1 from public.rp_cafes where id=c for update;m:=rp_private.require_member(c);
 if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 if r is null or b is null or jsonb_typeof(b)<>'object' then raise exception 'INVALID_COMMAND';end if;
 select * into rec from rp_private.receipts where cafe_id=c and request_id=r;
 if found then if rec.actor_id<>auth.uid() or rec.action<>'bill_issue' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return rec.result;end if;
 select * into bl from public.rp_bills where cafe_id=c and id=(b->>'bill_id')::uuid for update;
 if not found or bl.status<>'open' then raise exception 'BILL_NOT_OPEN';end if;
 if b->>'version' is null or bl.version<>(b->>'version')::bigint then raise exception 'VERSION_CONFLICT' using errcode='40001';end if;
 if m.role='waiter' and exists(select 1 from public.rp_orders where cafe_id=c and bill_id=bl.id and waiter_id is distinct from auth.uid()) then raise exception 'BILL_NOT_ASSIGNED' using errcode='42501';end if;
 -- Issue/close is operational. It does not fabricate a payment or a served state.
 update public.rp_bills set status='closed',closed_at=clock_timestamp(),version=version+1 where cafe_id=c and id=bl.id;
 result:=jsonb_build_object('ok',true,'bill_id',bl.id,'request_id',r);
 insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'bill_issue',b,result);
 return result;
end $$;
revoke all on function public.rp_bill_issue(uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.rp_bill_issue(uuid,uuid,jsonb) to authenticated;
commit;
