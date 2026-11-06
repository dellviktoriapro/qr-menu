begin;
create function pg_temp.assert_ok(ok boolean,msg text) returns void language plpgsql as $$begin if ok is distinct from true then raise exception 'TEST_FAILED: %',msg; end if; end$$;
insert into auth.users(id) values('00000000-0000-4000-8000-000000000001'),('00000000-0000-4000-8000-000000000002'),('00000000-0000-4000-8000-000000000003'),('00000000-0000-4000-8000-000000000004');
insert into public.rp_cafes(id,slug,name) values('10000000-0000-4000-8000-000000000001','command-fixture-a','Fixture A'),('10000000-0000-4000-8000-000000000002','command-fixture-b','Fixture B');
insert into public.rp_memberships(cafe_id,user_id,role,display_name) values
('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001','owner','Owner A'),
('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000002','waiter','Waiter A'),
('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000003','bar','Bar A'),
('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000004','kitchen','Kitchen A');
insert into public.rp_tables(cafe_id,label,seats) values('10000000-0000-4000-8000-000000000001','5',4);
insert into public.rp_menu_items(id,cafe_id,external_key,names,station,price_minor) values
('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','fish','{"vi":"Cá","ru":"Рыба"}','kitchen',160000),
('20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001','coffee','{"vi":"Cà phê","ru":"Кофе"}','bar',30000);
-- Transaction-only grants to test actual Data API caller role.
grant usage on schema rp_private to authenticated;
grant execute on function rp_private.my_cafes(),rp_private.snapshot(uuid),rp_private.command(uuid,uuid,text,jsonb) to authenticated;
grant execute on function public.rp_my_cafes(),public.rp_snapshot(uuid),public.rp_command(uuid,uuid,text,jsonb) to authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000002',true);
set local role authenticated;
select pg_temp.assert_ok(jsonb_array_length(public.rp_my_cafes())=1,'only own membership');
select public.rp_command('10000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001','order_create','{"table":"5","send":true,"items":[{"id":"20000000-0000-4000-8000-000000000001","quantity":1},{"id":"20000000-0000-4000-8000-000000000002","quantity":2}]}');
select public.rp_command('10000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001','order_create','{"table":"5","send":true,"items":[{"id":"20000000-0000-4000-8000-000000000001","quantity":1},{"id":"20000000-0000-4000-8000-000000000002","quantity":2}]}');
select pg_temp.assert_ok(jsonb_array_length(public.rp_snapshot('10000000-0000-4000-8000-000000000001')->'orders')=1,'duplicate retry does not duplicate order');
do $$begin
 begin perform public.rp_snapshot('10000000-0000-4000-8000-000000000002'); raise exception 'Tenant leak'; exception when insufficient_privilege then null; end;
 begin perform public.rp_command('10000000-0000-4000-8000-000000000001',gen_random_uuid(),'menu_put','{"key":"x","names":{"vi":"X"},"station":"bar","price":1}'); raise exception 'Waiter edited menu'; exception when insufficient_privilege then null; end;
end$$;
reset role;
-- Keep IDs in transaction-local settings for role-switched tests.
select set_config('rp.test_order',(select id::text from public.rp_orders where cafe_id='10000000-0000-4000-8000-000000000001'),true);
select set_config('rp.test_bill',(select id::text from public.rp_bills where cafe_id='10000000-0000-4000-8000-000000000001'),true);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000003',true);
set local role authenticated;
do $$begin
 begin perform public.rp_command('10000000-0000-4000-8000-000000000001',gen_random_uuid(),'station_ready',jsonb_build_object('order_id',current_setting('rp.test_order'),'version',1,'station','kitchen')); raise exception 'Bar completed kitchen'; exception when insufficient_privilege then null; end;
end$$;
select public.rp_command('10000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000003','station_ready',jsonb_build_object('order_id',current_setting('rp.test_order'),'version',1,'station','bar'));
select pg_temp.assert_ok(public.rp_snapshot('10000000-0000-4000-8000-000000000001')->'orders'->0->>'status'='cooking','bar does not complete whole order');
reset role;
update public.rp_menu_items set price_minor=999999 where id='20000000-0000-4000-8000-000000000001';
select pg_temp.assert_ok((select unit_price_minor=160000 from public.rp_order_items where menu_item_id='20000000-0000-4000-8000-000000000001'),'historical price stays fixed');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000004',true);
set local role authenticated;
do $$begin
 begin perform public.rp_command('10000000-0000-4000-8000-000000000001',gen_random_uuid(),'station_ready',jsonb_build_object('order_id',current_setting('rp.test_order'),'version',1,'station','kitchen')); raise exception 'Stale version accepted'; exception when serialization_failure then null; end;
end$$;
select public.rp_command('10000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000004','station_ready',jsonb_build_object('order_id',current_setting('rp.test_order'),'version',2,'station','kitchen'));
select pg_temp.assert_ok(public.rp_snapshot('10000000-0000-4000-8000-000000000001')->'orders'->0->>'status'='ready','both stations finish order');
reset role;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000002',true);
set local role authenticated;
select public.rp_command('10000000-0000-4000-8000-000000000001',gen_random_uuid(),'serve',jsonb_build_object('order_id',current_setting('rp.test_order'),'version',3));
reset role;
select set_config('rp.test_check',(select id::text from public.rp_checks where cafe_id='10000000-0000-4000-8000-000000000001'),true);
set local role authenticated;
select public.rp_command('10000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000005','bill_close',jsonb_build_object('bill_id',current_setting('rp.test_bill'),'version',0,'payments',jsonb_build_object(current_setting('rp.test_check'),'cash')));
select public.rp_command('10000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000005','bill_close',jsonb_build_object('bill_id',current_setting('rp.test_bill'),'version',0,'payments',jsonb_build_object(current_setting('rp.test_check'),'cash')));
reset role;
select pg_temp.assert_ok((select count(*)=1 and sum(amount_minor)=220000 from public.rp_payments where cafe_id='10000000-0000-4000-8000-000000000001'),'single exact payment after retry and price change');
update public.rp_memberships set active=false where user_id='00000000-0000-4000-8000-000000000002';
set local role authenticated;
do $$begin
 begin perform public.rp_snapshot('10000000-0000-4000-8000-000000000001'); raise exception 'Blocked staff still reads'; exception when insufficient_privilege then null; end;
end$$;
reset role;
rollback;
select 'PASS: authenticated RPC roles; tenant isolation; retry idempotency; separate stations; stale versions; immutable prices; exact close/payment; revoked membership; all fixtures/grants rolled back' as result;
