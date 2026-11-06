begin;
create function pg_temp.assert_admin(ok boolean,msg text) returns void language plpgsql as $$begin if ok is distinct from true then raise exception 'TEST_FAILED: %',msg; end if;end$$;
insert into auth.users(id,email,email_confirmed_at) values
('90000000-0000-4000-8000-000000000001','admin@example.test',now()),
('90000000-0000-4000-8000-000000000002','owner@example.test',now()),
('90000000-0000-4000-8000-000000000003','other@example.test',now()),
('90000000-0000-4000-8000-000000000004','unconfirmed@example.test',null);
insert into rp_private.platform_admins values('90000000-0000-4000-8000-000000000001',true);
grant usage on schema rp_private to authenticated;
grant execute on function rp_private.admin_overview(timestamptz,timestamptz),rp_private.admin_command(uuid,text,jsonb),rp_private.accept_owner_invite(text) to authenticated;
grant execute on function public.rp_admin_overview(timestamptz,timestamptz),public.rp_admin_command(uuid,text,jsonb),public.rp_accept_owner_invite(text) to authenticated;
select set_config('request.jwt.claim.sub','90000000-0000-4000-8000-000000000003',true);
set local role authenticated;
do $$begin begin perform public.rp_admin_overview(now()-interval '1 day',now());raise exception 'ordinary user has admin';exception when insufficient_privilege then null;end;end$$;
reset role;
select set_config('request.jwt.claim.sub','90000000-0000-4000-8000-000000000001',true);
set local role authenticated;
select public.rp_admin_command('91000000-0000-4000-8000-000000000001','create','{"name":"Admin fixture","slug":"admin-fixture"}');
select public.rp_admin_command('91000000-0000-4000-8000-000000000001','create','{"name":"Admin fixture","slug":"admin-fixture"}');
select public.rp_admin_command('92000000-0000-4000-8000-000000000001','invite',jsonb_build_object('cafe_id','91000000-0000-4000-8000-000000000001','email','owner@example.test','token',repeat('a',64)));
select public.rp_admin_command('92000000-0000-4000-8000-000000000001','invite',jsonb_build_object('cafe_id','91000000-0000-4000-8000-000000000001','email','owner@example.test','token',repeat('a',64)));
reset role;
select set_config('request.jwt.claim.sub','90000000-0000-4000-8000-000000000003',true);
set local role authenticated;
do $$begin begin perform public.rp_accept_owner_invite(repeat('a',64));raise exception 'wrong email accepted';exception when insufficient_privilege then null;end;end$$;
reset role;
select set_config('request.jwt.claim.sub','90000000-0000-4000-8000-000000000004',true);
set local role authenticated;
do $$begin begin perform public.rp_accept_owner_invite(repeat('a',64));raise exception 'unconfirmed email accepted';exception when insufficient_privilege then null;end;end$$;
reset role;
select set_config('request.jwt.claim.sub','90000000-0000-4000-8000-000000000002',true);
set local role authenticated;
select public.rp_accept_owner_invite(repeat('a',64));
do $$begin begin perform public.rp_accept_owner_invite(repeat('a',64));raise exception 'reused token accepted';exception when raise_exception then if sqlerrm<>'INVITE_UNAVAILABLE' then raise;end if;end;end$$;
reset role;
select pg_temp.assert_admin((select count(*)=1 from public.rp_memberships where cafe_id='91000000-0000-4000-8000-000000000001' and role='owner'),'one owner');
select pg_temp.assert_admin(not exists(select 1 from rp_private.receipts where body::text like '%aaaaaaaaaaaaaaaa%'),'token absent from receipts');
select set_config('request.jwt.claim.sub','90000000-0000-4000-8000-000000000001',true);
set local role authenticated;
select public.rp_admin_command('92000000-0000-4000-8000-000000000002','archive','{"cafe_id":"91000000-0000-4000-8000-000000000001"}');
select pg_temp.assert_admin(exists(select 1 from jsonb_array_elements(public.rp_admin_overview(now()-interval '1 day',now())->'cafes') v where v->>'id'='91000000-0000-4000-8000-000000000001' and v->>'active'='false' and not(v?'orders')),'archive visible, no order list');
reset role;
rollback;
select 'PASS: admin isolation; create/invite retries; verified matching email; one use; token hashing; archive; aggregate response; fixtures rolled back' as result;
