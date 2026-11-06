-- Server-only bridge for manual account provisioning. Client roles receive no privileges.
begin;
alter table rp_private.owner_invites add column mode text not null default 'email' check(mode in ('email','manual'));
create table rp_private.manual_accounts(user_id uuid primary key references auth.users(id),created_at timestamptz not null default now());
alter table rp_private.manual_accounts enable row level security;
create table rp_private.manual_requests(
 id uuid primary key,invite_id uuid not null unique references rp_private.owner_invites(id),
 user_id uuid unique references auth.users(id),
 state text not null default 'reserved' check(state in ('reserved','pending','approving','approved','failed')),
 code text not null default upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),
 approved_by uuid references auth.users(id),created_at timestamptz not null default now()
);
alter table rp_private.manual_requests enable row level security;
create function rp_private.manual_gateway(a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare inv rp_private.owner_invites; q rp_private.manual_requests; actor uuid; em text;
begin
 if b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>8192 then raise exception 'INVALID_REQUEST';end if;
 perform pg_advisory_xact_lock(617324910);
 if a in ('reserve','status') then
  if b->>'token' is null or b->>'token' !~ '^[a-f0-9]{64}$' then raise exception 'INVITE_UNAVAILABLE';end if;
  select * into inv from rp_private.owner_invites where token_hash=encode(sha256(convert_to(b->>'token','UTF8')),'hex') for update;
  if not found or inv.mode<>'manual' or inv.revoked_at is not null or inv.expires_at<=now() then raise exception 'INVITE_UNAVAILABLE';end if;
  if not exists(select 1 from public.rp_cafes where id=inv.cafe_id and active and archived_at is null) then raise exception 'CAFE_UNAVAILABLE';end if;
  if a='reserve' then
   if inv.accepted_at is not null or lower(trim(b->>'email')) is distinct from inv.email or b->>'request_id' is null then raise exception 'INVITE_UNAVAILABLE';end if;
   -- One reservation per invitation. Failed attempts require the admin to issue a new link.
   insert into rp_private.manual_requests(id,invite_id) values((b->>'request_id')::uuid,inv.id);
   return jsonb_build_object('invite_id',inv.id,'email',inv.email);
  end if;
  select * into q from rp_private.manual_requests where invite_id=inv.id and id=(b->>'request_id')::uuid;
  if not found then raise exception 'REQUEST_UNAVAILABLE';end if;
  return jsonb_build_object('state',q.state,'code',q.code);
 elsif a='registered' then
  select * into q from rp_private.manual_requests where id=(b->>'request_id')::uuid for update;
  if not found or q.state<>'reserved' then raise exception 'REQUEST_UNAVAILABLE';end if;
  select * into inv from rp_private.owner_invites where id=q.invite_id;
  if inv.revoked_at is not null or inv.expires_at<=now() then raise exception 'INVITE_UNAVAILABLE';end if;
  select lower(email) into em from auth.users where id=(b->>'user_id')::uuid and email_confirmed_at is null;
  if em is distinct from inv.email then raise exception 'USER_MISMATCH';end if;
  insert into rp_private.manual_accounts(user_id) values((b->>'user_id')::uuid);
  update rp_private.manual_requests set user_id=(b->>'user_id')::uuid,state='pending' where id=q.id returning * into q;
  return jsonb_build_object('state',q.state,'code',q.code);
 elsif a='failed' then
  update rp_private.manual_requests set state='failed' where id=(b->>'request_id')::uuid and state='reserved';
  return jsonb_build_object('ok',true);
 elsif a in ('prepare_approval','finish_approval') then
  actor:=(b->>'actor_id')::uuid;
  if not exists(select 1 from rp_private.platform_admins p join auth.users u on u.id=p.user_id where p.user_id=actor and p.active and u.email_confirmed_at is not null and u.deleted_at is null) then raise exception 'ADMIN_REQUIRED' using errcode='42501';end if;
  select * into q from rp_private.manual_requests where id=(b->>'request_id')::uuid for update;
  if not found or q.user_id is null or q.code is distinct from upper(b->>'code') then raise exception 'REQUEST_UNAVAILABLE';end if;
  select * into inv from rp_private.owner_invites where id=q.invite_id for update;
  if q.state='approved' and inv.accepted_by=q.user_id then return jsonb_build_object('ok',true,'user_id',q.user_id,'state','approved');end if;
  if q.state not in ('pending','approving') or inv.revoked_at is not null or inv.accepted_at is not null or inv.expires_at<=now() then raise exception 'INVITE_UNAVAILABLE';end if;
  if not exists(select 1 from public.rp_cafes where id=inv.cafe_id and active and archived_at is null) then raise exception 'CAFE_UNAVAILABLE';end if;
  if exists(select 1 from public.rp_memberships where cafe_id=inv.cafe_id and role='owner' and active) then raise exception 'OWNER_ALREADY_ACTIVE';end if;
  if a='prepare_approval' then
   update rp_private.manual_requests set state='approving',approved_by=actor where id=q.id;
   return jsonb_build_object('user_id',q.user_id,'state','approving');
  end if;
  if q.state<>'approving' or not exists(select 1 from auth.users where id=q.user_id and lower(email)=inv.email and email_confirmed_at is not null and deleted_at is null) then raise exception 'ACCOUNT_NOT_READY';end if;
  insert into public.rp_memberships(cafe_id,user_id,role,display_name) values(inv.cafe_id,q.user_id,'owner',split_part(inv.email,'@',1));
  update rp_private.manual_requests set state='approved',approved_by=actor where id=q.id;
  update rp_private.owner_invites set accepted_at=now(),accepted_by=q.user_id where id=inv.id;
  insert into rp_private.admin_events(actor_id,action,cafe_id,details) values(actor,'manual_owner_approved',inv.cafe_id,jsonb_build_object('request_id',q.id,'user_id',q.user_id));
  return jsonb_build_object('ok',true,'state','approved','user_id',q.user_id);
 end if;
 raise exception 'UNKNOWN_ACTION';
end$$;
create function public.rp_manual_gateway(a text,b jsonb) returns jsonb language sql security invoker set search_path='' as $$select rp_private.manual_gateway(a,b)$$;
revoke all on table rp_private.manual_accounts,rp_private.manual_requests from public,anon,authenticated;
revoke all on function rp_private.manual_gateway(text,jsonb),public.rp_manual_gateway(text,jsonb) from public,anon,authenticated;
-- service_role is held only inside the Edge Function environment, never in the website.
grant usage on schema rp_private to service_role;
grant execute on function rp_private.manual_gateway(text,jsonb),public.rp_manual_gateway(text,jsonb) to service_role;
commit;
