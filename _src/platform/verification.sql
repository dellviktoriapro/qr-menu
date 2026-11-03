-- Development only. All fixtures and temporary privileges roll back.
begin;
do $test$ declare n integer; t record; begin
  select count(*) into n from pg_tables where schemaname='public' and tablename like 'rp_%' and rowsecurity;
  if n<>10 then raise exception 'Expected 10 RLS-protected foundation tables, got %',n; end if;
  for t in select tablename from pg_tables where schemaname='public' and tablename like 'rp_%' loop
    if has_table_privilege('anon','public.'||t.tablename,'SELECT') or has_table_privilege('authenticated','public.'||t.tablename,'SELECT') or has_table_privilege('authenticated','public.'||t.tablename,'INSERT') then
      raise exception 'Unexpected permanent client privilege on %',t.tablename;
    end if;
  end loop;
end $test$;
insert into auth.users(id) values
('00000000-0000-4000-8000-000000000001'),
('00000000-0000-4000-8000-000000000002'),
('00000000-0000-4000-8000-000000000003');
insert into public.rp_cafes(id,slug,name) values
('10000000-0000-4000-8000-000000000001','foundation-test-a','Fixture A'),
('10000000-0000-4000-8000-000000000002','foundation-test-b','Fixture B');
insert into public.rp_memberships(cafe_id,user_id,role,display_name) values
('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001','owner','Owner A'),
('10000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000002','owner','Owner B'),
('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000003','waiter','Waiter A');
insert into public.rp_tables(id,cafe_id,label,seats) values
('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','1',4),
('20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','1',4);
insert into public.rp_bills(id,cafe_id,table_id,currency) values
('30000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','VND'),
('30000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','VND');
insert into public.rp_checks(id,cafe_id,bill_id,label) values
('40000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001','Common'),
('40000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','30000000-0000-4000-8000-000000000002','Common');
insert into public.rp_payments(cafe_id,bill_id,check_id,kind,method,amount_minor,recorded_by,request_id) values
('10000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','payment','cash',100000,'00000000-0000-4000-8000-000000000001',gen_random_uuid()),
('10000000-0000-4000-8000-000000000002','30000000-0000-4000-8000-000000000002','40000000-0000-4000-8000-000000000002','payment','cash',200000,'00000000-0000-4000-8000-000000000002',gen_random_uuid());
do $test$ begin
  begin
    insert into public.rp_bills(cafe_id,table_id,currency) values ('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000002','VND');
    raise exception 'Cross-cafe FK was accepted';
  exception when foreign_key_violation then null; end;
  begin
    insert into public.rp_bills(cafe_id,table_id,currency) values ('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','VND');
    raise exception 'Duplicate open visit was accepted';
  exception when unique_violation then null; end;
end $test$;
-- These grants are visible only inside this transaction and never persist.
grant select on public.rp_cafes,public.rp_memberships,public.rp_tables,public.rp_menu_items,public.rp_bills,public.rp_checks,public.rp_orders,public.rp_order_items,public.rp_payments,public.rp_order_events to authenticated,anon;
set local role anon;
do $test$ begin
  if (select count(*) from public.rp_cafes)<>0 then raise exception 'Anonymous cafe leak'; end if;
  if (select count(*) from public.rp_payments)<>0 then raise exception 'Anonymous finance leak'; end if;
end $test$;
reset role;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000001',true);
set local role authenticated;
do $test$ begin
  if (select count(*) from public.rp_cafes)<>1 or (select min(slug) from public.rp_cafes)<>'foundation-test-a' then raise exception 'Owner A tenant isolation failed'; end if;
  if (select sum(amount_minor) from public.rp_payments)<>100000 then raise exception 'Owner A financial isolation failed'; end if;
end $test$;
reset role;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000002',true);
set local role authenticated;
do $test$ begin
  if (select count(*) from public.rp_cafes)<>1 or (select min(slug) from public.rp_cafes)<>'foundation-test-b' then raise exception 'Owner B tenant isolation failed'; end if;
  if (select sum(amount_minor) from public.rp_payments)<>200000 then raise exception 'Owner B financial isolation failed'; end if;
end $test$;
reset role;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000003',true);
set local role authenticated;
do $test$ begin
  if (select count(*) from public.rp_bills)<>1 then raise exception 'Waiter operational isolation failed'; end if;
  if (select count(*) from public.rp_payments)<>0 then raise exception 'Waiter finance leak'; end if;
end $test$;
reset role;
update public.rp_memberships set active=false where user_id='00000000-0000-4000-8000-000000000003';
set local role authenticated;
do $test$ begin
  if (select count(*) from public.rp_cafes)<>0 or (select count(*) from public.rp_bills)<>0 then raise exception 'Revoked membership still has access'; end if;
end $test$;
reset role;
rollback;
select 'PASS: two-cafe RLS, owner finance, waiter restriction, anonymous denial, revoked membership, cross-cafe FK, duplicate visit; fixtures/grants rolled back' as result;
