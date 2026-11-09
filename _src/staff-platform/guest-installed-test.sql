begin;
create function pg_temp.guest_assert(ok boolean,msg text) returns void language plpgsql as $$begin if ok is distinct from true then raise exception 'TEST: %',msg;end if;end$$;
insert into auth.users(id) values('00000000-0000-4000-8000-000000000051');
insert into public.rp_cafes(id,slug,name) values('10000000-0000-4000-8000-000000000051','guest-fixture','Guest fixture');
insert into public.rp_memberships(cafe_id,user_id,role,display_name) values('10000000-0000-4000-8000-000000000051','00000000-0000-4000-8000-000000000051','owner','Owner fixture');
insert into public.rp_tables(id,cafe_id,label,seats) values('20000000-0000-4000-8000-000000000051','10000000-0000-4000-8000-000000000051','5',4);
insert into public.rp_menu_items(id,cafe_id,external_key,names,station,price_minor) values('30000000-0000-4000-8000-000000000051','10000000-0000-4000-8000-000000000051','fish|0|0','{"ru":"Fish fixture","vi":"Ca"}','kitchen',160000);
insert into rp_private.guest_visits(id,cafe_id,table_id,token_hash) values('40000000-0000-4000-8000-000000000051','10000000-0000-4000-8000-000000000051','20000000-0000-4000-8000-000000000051',encode(sha256(convert_to(repeat('a',64),'UTF8')),'hex'));
insert into public.rp_menu_items(id,cafe_id,external_key,names,station,price_minor) values('30000000-0000-4000-8000-000000000052','10000000-0000-4000-8000-000000000051','coffee|0|0','{"ru":"Coffee fixture","vi":"Ca phe"}','bar',30000);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000051',true);
do $$declare b jsonb:='{"lang":"ru","checks":[{"label":"Anna","items":[{"key":"fish|0|0","quantity":2,"note":"No spice","price":1},{"key":"coffee|0|0","quantity":1,"note":"No ice"}]},{"label":"Ivan","items":[{"key":"fish|0|0","quantity":1,"note":""}]}]}';v jsonb;g uuid;payload jsonb;begin
 v:=rp_private.guest_submit(repeat('a',64),'50000000-0000-4000-8000-000000000051',b);
 perform pg_temp.guest_assert(jsonb_array_length(v->'order_ids')=2,'separate checks recorded');
 perform pg_temp.guest_assert(v=rp_private.guest_submit(repeat('a',64),'50000000-0000-4000-8000-000000000051',b),'submit retry exact receipt');
 perform pg_temp.guest_assert((select count(*) from rp_private.guest_submissions)=1,'one submission after retry');
 perform pg_temp.guest_assert((select items_snapshot->0->'items'->0->>'price' from rp_private.guest_submissions)='160000','forged client price ignored');
 begin perform rp_private.guest_submit(repeat('b',64),gen_random_uuid(),b);raise exception 'INVALID_TOKEN_ALLOWED';exception when others then if sqlerrm<>'VISIT_UNAVAILABLE' then raise;end if;end;
 begin perform rp_private.guest_submit(repeat('a',64),'50000000-0000-4000-8000-000000000051',b||'{"lang":"en"}');raise exception 'REQUEST_OVERWRITTEN';exception when others then if sqlerrm<>'REQUEST_ID_REUSED' then raise;end if;end;
 select id into g from rp_private.guest_submissions;payload:=jsonb_build_object('submission_id',g);
 update public.rp_menu_items set price_minor=170000 where id='30000000-0000-4000-8000-000000000051';
 begin perform rp_private.accept_guest('10000000-0000-4000-8000-000000000051',gen_random_uuid(),payload);raise exception 'PRICE_CHANGE_IGNORED';exception when others then if sqlerrm<>'ITEM_OR_PRICE_CHANGED' then raise;end if;end;
 perform pg_temp.guest_assert((select count(*) from public.rp_orders where cafe_id='10000000-0000-4000-8000-000000000051')=0,'failed acceptance atomic');
 update public.rp_menu_items set price_minor=160000 where id='30000000-0000-4000-8000-000000000051';
 v:=rp_private.accept_guest('10000000-0000-4000-8000-000000000051','60000000-0000-4000-8000-000000000051',payload);
 perform pg_temp.guest_assert(v=rp_private.accept_guest('10000000-0000-4000-8000-000000000051','60000000-0000-4000-8000-000000000051',payload),'acceptance retry exact receipt');
 perform pg_temp.guest_assert((select count(*) from public.rp_orders where cafe_id='10000000-0000-4000-8000-000000000051')=2,'one order per named check');
 perform pg_temp.guest_assert((select sum(i.quantity*i.unit_price_minor) from public.rp_order_items i where cafe_id='10000000-0000-4000-8000-000000000051')=510000,'server prices and quantities');
 -- Full existing station/service/payment commands, using accepted orders only.
 perform pg_temp.guest_assert((select count(*) from public.rp_orders where cafe_id='10000000-0000-4000-8000-000000000051' and status='accepted')=2,'accepted drafts not sent before waiter');
 for g in select id from public.rp_orders where cafe_id='10000000-0000-4000-8000-000000000051' loop
  perform rp_private.operational_command('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'send',jsonb_build_object('order_id',g,'version',(select version from public.rp_orders where id=g)));
 end loop;
 select order_id into g from public.rp_order_items where cafe_id='10000000-0000-4000-8000-000000000051' and station='bar';
 perform rp_private.operational_command('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'station_ready',jsonb_build_object('order_id',g,'station','bar','version',(select version from public.rp_orders where id=g)));
 perform pg_temp.guest_assert((select status from public.rp_orders where id=g)='cooking','bar ready does not finish kitchen');
 perform rp_private.operational_command('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'serve',jsonb_build_object('order_id',g,'station','bar','version',(select version from public.rp_orders where id=g)));
 perform pg_temp.guest_assert(not exists(select 1 from public.rp_order_items where order_id=g and station='kitchen' and served_at is not null),'bar service does not serve food');
 for g in select id from public.rp_orders where cafe_id='10000000-0000-4000-8000-000000000051' loop
  perform rp_private.operational_command('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'station_ready',jsonb_build_object('order_id',g,'station','kitchen','version',(select version from public.rp_orders where id=g)));
  perform rp_private.operational_command('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'serve',jsonb_build_object('order_id',g,'station','kitchen','version',(select version from public.rp_orders where id=g)));
 end loop;
 select id into g from public.rp_bills where cafe_id='10000000-0000-4000-8000-000000000051';
 payload:=jsonb_build_object('bill_id',g,'version',(select version from public.rp_bills where id=g),'payments',(select jsonb_object_agg(id::text,'cash') from public.rp_checks where bill_id=g));
 perform rp_private.operational_command('10000000-0000-4000-8000-000000000051','70000000-0000-4000-8000-000000000051','bill_close',payload);
 perform rp_private.operational_command('10000000-0000-4000-8000-000000000051','70000000-0000-4000-8000-000000000051','bill_close',payload);
 perform pg_temp.guest_assert((select sum(amount_minor) from public.rp_payments where cafe_id='10000000-0000-4000-8000-000000000051')=510000,'recorded payments exact, close retry no duplicate');
 perform pg_temp.guest_assert(not has_function_privilege('anon','rp_private.guest_submit(text,uuid,jsonb)','execute'),'closed until Edge review');
end$$;

do $$declare c uuid:='10000000-0000-4000-8000-000000000051';t uuid:='20000000-0000-4000-8000-000000000051';link jsonb;v jsonb;v2 jsonb;r jsonb;g uuid;bill uuid;body jsonb:='{"lang":"ru","checks":[{"label":"Guest","items":[{"key":"coffee|0|0","quantity":1,"note":"No ice"}]}]}';begin
 link:=rp_private.guest_staff(c,'80000000-0000-4000-8000-000000000051','table_link',jsonb_build_object('table_id',t));
 perform pg_temp.guest_assert(length(link->>'table_token')=64,'high entropy table link');
 v:=rp_private.guest_staff(c,'80000000-0000-4000-8000-000000000051','table_link',jsonb_build_object('table_id',t));perform pg_temp.guest_assert(v->>'reissue_required'='true' and not v?'table_token','no plaintext table secret in receipt');
 v:=rp_private.guest_transport('open',jsonb_build_object('table_token',link->>'table_token','visit_secret',repeat('c',64)));
 v2:=rp_private.guest_transport('open',jsonb_build_object('table_token',link->>'table_token','visit_secret',repeat('d',64)));
 perform pg_temp.guest_assert((select count(distinct bill_id) from rp_private.guest_visits where closed_at is null)=1,'two guests share one bill');
 r:=rp_private.guest_transport('submit',jsonb_build_object('visit_secret',repeat('c',64),'request_id','90000000-0000-4000-8000-000000000051','order',body));
 v:=rp_private.guest_staff(c,null,'pending','{}');perform pg_temp.guest_assert(jsonb_array_length(v)=1,'waiter incoming queue');g:=(v->0->>'id')::uuid;
 select bill_id into bill from rp_private.guest_visits where token_hash=encode(sha256(convert_to(repeat('c',64),'UTF8')),'hex');
 begin update public.rp_bills set status='closed',closed_at=now() where id=bill;raise exception 'UNREAD_ORDER_CLOSED';exception when others then if sqlerrm<>'GUEST_ORDERS_PENDING' then raise;end if;end;
 v:=rp_private.guest_transport('status',jsonb_build_object('visit_secret',repeat('c',64),'request_id','90000000-0000-4000-8000-000000000051'));perform pg_temp.guest_assert(v->>'accepted'='false','guest sees pending');
 v:=rp_private.guest_staff(c,'a0000000-0000-4000-8000-000000000051','accept',jsonb_build_object('submission_id',g));
 v:=rp_private.guest_transport('status',jsonb_build_object('visit_secret',repeat('c',64),'request_id','90000000-0000-4000-8000-000000000051'));perform pg_temp.guest_assert(v->>'accepted'='true','guest sees actual acceptance');perform pg_temp.guest_assert(jsonb_array_length(v->'checks')=1 and v->'states'->0->>'number' is not null,'guest receives server quote and order number');
 begin perform rp_private.guest_transport('status',jsonb_build_object('visit_secret',repeat('d',64),'request_id','90000000-0000-4000-8000-000000000051'));raise exception 'OTHER_GUEST_READ_ORDER';exception when others then if sqlerrm<>'REQUEST_UNAVAILABLE' then raise;end if;end;
 -- Explicitly close the fixture bill to test visit invalidation; operational payment guards are covered above.
 update public.rp_bills set status='void',closed_at=now() where id=bill;
 begin perform rp_private.guest_transport('submit',jsonb_build_object('visit_secret',repeat('c',64),'request_id',gen_random_uuid(),'order',body));raise exception 'OLD_VISIT_WROTE';exception when others then if sqlerrm<>'VISIT_CLOSED' then raise;end if;end;
 perform pg_temp.guest_assert(r=rp_private.guest_transport('submit',jsonb_build_object('visit_secret',repeat('c',64),'request_id','90000000-0000-4000-8000-000000000051','order',body)),'receipt retry after visit closure');
 perform pg_temp.guest_assert(not has_function_privilege('anon','public.rp_guest_transport(text,jsonb)','execute') and not has_function_privilege('authenticated','public.rp_guest_transport(text,jsonb)','execute'),'new endpoints remain closed');
end$$;


do $$declare c uuid:='10000000-0000-4000-8000-000000000051';link jsonb;v jsonb;g uuid;payload jsonb;body jsonb:='{"lang":"ru","checks":[{"label":"Declined fixture","items":[{"key":"coffee|0|0","quantity":1,"note":""}]}]}';begin
 link:=rp_private.guest_staff(c,gen_random_uuid(),'table_link','{"table_id":"20000000-0000-4000-8000-000000000051","replace":true}');
 perform rp_private.guest_transport('open',jsonb_build_object('table_token',link->>'table_token','visit_secret',repeat('e',64)));
 perform rp_private.guest_transport('submit',jsonb_build_object('visit_secret',repeat('e',64),'request_id','90000000-0000-4000-8000-000000000052','order',body));
 select id into g from rp_private.guest_submissions where request_id='90000000-0000-4000-8000-000000000052';payload:=jsonb_build_object('submission_id',g);
 v:=rp_private.guest_staff(c,'b0000000-0000-4000-8000-000000000051','reject',payload);
 perform pg_temp.guest_assert(v=rp_private.guest_staff(c,'b0000000-0000-4000-8000-000000000051','reject',payload),'reject retry idempotent');
 v:=rp_private.guest_transport('status',jsonb_build_object('visit_secret',repeat('e',64),'request_id','90000000-0000-4000-8000-000000000052'));perform pg_temp.guest_assert(v->>'rejected'='true','guest sees rejection');
 perform pg_temp.guest_assert(jsonb_array_length(rp_private.guest_staff(c,null,'pending','{}'))=0,'declined leaves incoming queue');
 begin perform rp_private.guest_staff(c,gen_random_uuid(),'accept',payload);raise exception 'DECLINED_ACCEPTED';exception when others then if sqlerrm<>'SUBMISSION_UNAVAILABLE' then raise;end if;end;
 update public.rp_bills set status='void',closed_at=now() where cafe_id=c and status='open';
end$$;
insert into auth.users(id) values('00000000-0000-4000-8000-000000000052'),('00000000-0000-4000-8000-000000000053');
insert into public.rp_memberships(cafe_id,user_id,role,display_name) values('10000000-0000-4000-8000-000000000051','00000000-0000-4000-8000-000000000052','waiter','Waiter fixture'),('10000000-0000-4000-8000-000000000051','00000000-0000-4000-8000-000000000053','bar','Bar fixture');
grant execute on function public.rp_guest_staff(uuid,uuid,text,jsonb),rp_private.guest_staff(uuid,uuid,text,jsonb) to authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000052',true);
set local role authenticated;
do $$begin
 perform public.rp_guest_staff('10000000-0000-4000-8000-000000000051',null,'pending','{}');
 begin perform public.rp_guest_staff('10000000-0000-4000-8000-000000000051',gen_random_uuid(),'table_link','{"table_id":"20000000-0000-4000-8000-000000000051"}');raise exception 'WAITER_ISSUED_TABLE_CAP';exception when insufficient_privilege then null;end;
 begin perform public.rp_guest_staff('10000000-0000-4000-8000-000000000099',null,'pending','{}');raise exception 'CROSS_CAFE_QUEUE';exception when insufficient_privilege then null;end;
end$$;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000053',true);
do $$begin
 begin perform public.rp_guest_staff('10000000-0000-4000-8000-000000000051',null,'pending','{}');raise exception 'BAR_READ_GUEST_QUEUE';exception when insufficient_privilege then null;end;
end$$;
reset role;

rollback;
select 'PASS guest transport: QR issuance/retry, two visitors/one bill, incoming queue, status isolation, close guard, stale-visit rejection + intake: receipt retry, separate checks, server prices, atomic acceptance, price-change rejection, independent bar/kitchen service, exact payment retry; fixture rolled back' as result;
