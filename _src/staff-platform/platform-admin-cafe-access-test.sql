-- Safe live smoke test: all test writes are rolled back.
begin;
do $test$
declare admin_id uuid; owner_id uuid; target_id uuid; m public.rp_memberships; cafes jsonb; data jsonb;
begin
 select id into strict admin_id from auth.users where lower(email)='dell.viktoria.pro@gmail.com';
 select id into strict owner_id from auth.users where lower(email)='golikova_viktori@mail.ru';
 select id into strict target_id from public.rp_cafes where slug='sun-sea' and active and archived_at is null;
 perform set_config('request.jwt.claim.sub',admin_id::text,true);
 cafes:=rp_private.my_cafes();
 if not exists(select 1 from jsonb_array_elements(cafes) c where (c->>'id')::uuid=target_id and c->>'role'='owner' and (c->>'platform_admin')::boolean) then
  raise exception 'admin cannot see Sun&Sea';
 end if;
 m:=rp_private.require_member(target_id);
 if m.role<>'owner' or not m.active then raise exception 'admin role not promoted';end if;
 if not exists(select 1 from public.rp_memberships where cafe_id=target_id and user_id=admin_id and not active and role='manager') then
  raise exception 'FK anchor not inactive manager';
 end if;
 data:=rp_private.operational_snapshot(target_id);
 if data->'me'->>'role'<>'owner' then raise exception 'operational snapshot denied';end if;
 data:=rp_private.staff_gateway('snapshot',jsonb_build_object('actor_id',admin_id,'cafe_id',target_id));
 if data->>'role'<>'owner' then raise exception 'staff gateway denied';end if;
 if exists(select 1 from jsonb_array_elements(data->'members') x where (x->>'id')::uuid=admin_id) then
  raise exception 'shadow membership visible in team';
 end if;
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 cafes:=rp_private.my_cafes();
 if exists(select 1 from jsonb_array_elements(cafes) c where (c->>'id')::uuid=target_id) then
  raise exception 'other cafe leaked to owner';
 end if;
 begin
  perform rp_private.require_member(target_id);
  raise exception 'owner entered other cafe';
 exception when insufficient_privilege then null;
 end;
 raise notice 'PASS: platform admin full cafe access; ordinary owner isolated';
end $test$;
rollback;
