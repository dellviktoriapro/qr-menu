insert into auth.users(id,email,email_confirmed_at) values
('94000000-0000-4000-8000-000000000001','manual-admin@example.test',now()),
('94000000-0000-4000-8000-000000000002','manual-owner@example.test',null),
('94000000-0000-4000-8000-000000000003','not-admin@example.test',now());
insert into rp_private.platform_admins values('94000000-0000-4000-8000-000000000001',true);
select set_config('request.jwt.claim.sub','94000000-0000-4000-8000-000000000001',true);
set local role authenticated;
select public.rp_admin_command('94000000-0000-4000-8000-000000000004','create','{"name":"Manual test","slug":"manual-test"}');
select public.rp_admin_command('94000000-0000-4000-8000-000000000005','invite',jsonb_build_object('cafe_id','94000000-0000-4000-8000-000000000004','email','manual-owner@example.test','token',repeat('d',64),'mode','manual'));
do $$begin begin perform public.rp_manual_gateway('reserve','{}');raise exception 'client calls privileged bridge';exception when insufficient_privilege then null;end;end$$;
reset role;
set local role service_role;
select public.rp_manual_gateway('reserve',jsonb_build_object('token',repeat('d',64),'email','manual-owner@example.test','request_id','94000000-0000-4000-8000-000000000006'));
select public.rp_manual_gateway('registered','{"request_id":"94000000-0000-4000-8000-000000000006","user_id":"94000000-0000-4000-8000-000000000002"}');
do $$begin begin perform public.rp_manual_gateway('prepare_approval','{"actor_id":"94000000-0000-4000-8000-000000000003","request_id":"94000000-0000-4000-8000-000000000006","code":"ABCDEF00"}');raise exception 'nonadmin approval';exception when insufficient_privilege then null;end;end$$;
reset role;
do $$begin if exists(select 1 from public.rp_memberships where user_id='94000000-0000-4000-8000-000000000002') then raise exception 'owner before approval';end if;end$$;
select set_config('manual.test_code',(select code from rp_private.manual_requests where id='94000000-0000-4000-8000-000000000006'),true);
set local role service_role;
select public.rp_manual_gateway('prepare_approval',jsonb_build_object('actor_id','94000000-0000-4000-8000-000000000001','request_id','94000000-0000-4000-8000-000000000006','code',current_setting('manual.test_code')));
reset role;
-- Simulate Auth Admin API success only inside this fixture transaction.
update auth.users set email_confirmed_at=now() where id='94000000-0000-4000-8000-000000000002';
select set_config('request.jwt.claim.sub','94000000-0000-4000-8000-000000000002',true);
set local role authenticated;
do $$begin begin perform public.rp_accept_owner_invite(repeat('d',64));raise exception 'manual account auto redemption';exception when insufficient_privilege then null;end;end$$;
reset role;
set local role service_role;
select public.rp_manual_gateway('finish_approval',jsonb_build_object('actor_id','94000000-0000-4000-8000-000000000001','request_id','94000000-0000-4000-8000-000000000006','code',current_setting('manual.test_code')));
select public.rp_manual_gateway('finish_approval',jsonb_build_object('actor_id','94000000-0000-4000-8000-000000000001','request_id','94000000-0000-4000-8000-000000000006','code',current_setting('manual.test_code')));
reset role;
do $$begin if (select count(*) from public.rp_memberships where user_id='94000000-0000-4000-8000-000000000002' and role='owner' and active)<>1 then raise exception 'incorrect manual ownership';end if;end$$;
rollback;
select 'PASS: manual pending has no access; client bridge denied; nonadmin denied; email bypass denied; approval exact and idempotent; all schema/fixtures rolled back' as result;
