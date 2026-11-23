-- Additional roles never imply owner or manager access. A staff member switches
-- only between roles assigned by the cafe owner; existing RPC checks stay active.
begin;
alter table public.rp_memberships add column if not exists roles text[];
update public.rp_memberships set roles=array[role] where roles is null;
alter table public.rp_memberships alter column roles set not null;
create function rp_private.membership_role_defaults() returns trigger
language plpgsql set search_path='' as $$begin
 if new.roles is null then new.roles:=array[new.role];
 elsif not new.role=any(new.roles) then new.roles:=array_append(new.roles,new.role);end if;
 return new;
end $$;
create trigger membership_role_defaults before insert or update on public.rp_memberships
 for each row execute function rp_private.membership_role_defaults();
alter table rp_private.staff_invites add column if not exists assigned_roles text[];

create or replace function rp_private.valid_staff_roles(v jsonb,primary_role text) returns text[]
language plpgsql immutable set search_path='' as $$
declare result text[];
begin
 if v is null then return array[primary_role];end if;
 if jsonb_typeof(v)<>'array' or jsonb_array_length(v) not between 1 and 4 then raise exception 'INVALID_ROLES';end if;
 select array_agg(distinct x) into result from jsonb_array_elements_text(v) x;
 if not result <@ array['manager','waiter','kitchen','bar']::text[] or not primary_role=any(result) then raise exception 'INVALID_ROLES';end if;
 return result;
end $$;

alter function rp_private.staff_gateway(text,jsonb) rename to staff_gateway_single_role;
create function rp_private.staff_gateway(a text,b jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb; selected text[]; target uuid; c uuid;
begin
 c:=(b->>'cafe_id')::uuid;
 if a in ('member_set','invite_create') and exists(select 1 from rp_private.receipts where cafe_id=c and request_id=(b->>'request_id')::uuid) then
  return rp_private.staff_gateway_single_role(a,b);
 end if;
 if a in ('member_set','invite_create') then
  selected:=rp_private.valid_staff_roles(b->'roles',b->>'role');
  if a='member_set' and not b ? 'roles' then
   select array(select distinct x from unnest(coalesce(roles,array[role])||array[b->>'role']) x) into selected from public.rp_memberships where cafe_id=c and user_id=(b->>'user_id')::uuid;
  end if;
 end if;
 -- The existing gateway checks the actor, tenant, owner approval and request ID.
 result:=rp_private.staff_gateway_single_role(a,b);
 if a='member_set' then
  update public.rp_memberships set roles=selected where cafe_id=c and user_id=(b->>'user_id')::uuid and role<>'owner';
 elsif a='invite_create' then
  update rp_private.staff_invites set assigned_roles=selected where cafe_id=c and id=(result->>'id')::uuid;
 elsif a='finish_approval' and result->>'state'='approved' then
  select q.user_id,i.assigned_roles into target,selected from rp_private.staff_requests q join rp_private.staff_invites i on i.id=q.invite_id where q.id=(b->>'request_id')::uuid and i.cafe_id=c;
  update public.rp_memberships set roles=coalesce(selected,array[role]) where cafe_id=c and user_id=target and role<>'owner';
 elsif a='snapshot' then
  result:=jsonb_set(result,'{members}',coalesce((select jsonb_agg(x||jsonb_build_object('roles',m.roles)) from jsonb_array_elements(result->'members') x join public.rp_memberships m on m.cafe_id=c and m.user_id=(x->>'id')::uuid),'[]'));
 end if;
 return result;
end $$;
revoke all on function rp_private.staff_gateway(text,jsonb),rp_private.staff_gateway_single_role(text,jsonb),rp_private.valid_staff_roles(jsonb,text) from public,anon,authenticated;
grant execute on function rp_private.staff_gateway(text,jsonb) to service_role;

create function public.rp_switch_role(c uuid,selected_role text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;
begin
 m:=rp_private.require_member(c);
 if m.role='owner' or selected_role not in ('manager','waiter','kitchen','bar') or not selected_role=any(m.roles) then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 update public.rp_memberships set role=selected_role where cafe_id=c and user_id=auth.uid() and active;
 return jsonb_build_object('ok',true,'role',selected_role);
end $$;
revoke all on function public.rp_switch_role(uuid,text) from public,anon,authenticated;
grant execute on function public.rp_switch_role(uuid,text) to authenticated;
commit;
