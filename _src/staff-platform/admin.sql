-- Closed until an explicit, reviewed grant enables these entry points.
begin;
create table rp_private.platform_admins(user_id uuid primary key references auth.users(id),active boolean not null default true);
alter table rp_private.platform_admins enable row level security;
create table rp_private.owner_invites(
 id uuid primary key default gen_random_uuid(),cafe_id uuid not null references public.rp_cafes(id),
 email text not null check(email=lower(trim(email)) and length(email)<=254),
 token_hash text not null unique,created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(),expires_at timestamptz not null default now()+interval '48 hours',
 accepted_at timestamptz,accepted_by uuid references auth.users(id),revoked_at timestamptz
);
alter table rp_private.owner_invites enable row level security;
create index rp_invites_cafe on rp_private.owner_invites(cafe_id,created_at);
create table rp_private.admin_events(id bigint generated always as identity primary key,actor_id uuid not null references auth.users(id),action text not null,cafe_id uuid references public.rp_cafes(id),occurred_at timestamptz not null default now(),details jsonb not null default '{}');
alter table rp_private.admin_events enable row level security;
alter table public.rp_cafes add column archived_at timestamptz;

create function rp_private.require_admin() returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not exists(select 1 from rp_private.platform_admins p join auth.users u on u.id=p.user_id where p.user_id=auth.uid() and p.active and u.email_confirmed_at is not null and u.deleted_at is null) then raise exception 'ADMIN_REQUIRED' using errcode='42501'; end if;
end$$;

create function rp_private.admin_overview(f timestamptz,t timestamptz) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 perform rp_private.require_admin();
 if f is null or t is null or t<=f or t-f>interval '367 days' then raise exception 'INVALID_PERIOD'; end if;
 select jsonb_build_object('cafes',coalesce(jsonb_agg(jsonb_build_object(
 'id',c.id,'name',c.name,'slug',c.slug,'active',c.active,'archived_at',c.archived_at,'currency',c.currency,'created_at',c.created_at,
 'owners',coalesce((select jsonb_agg(jsonb_build_object('id',m.user_id,'email',u.email,'active',m.active)) from public.rp_memberships m join auth.users u on u.id=m.user_id where m.cafe_id=c.id and m.role='owner'),'[]'),
 'invites',coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'email',i.email,'expires_at',i.expires_at,'accepted_at',i.accepted_at,'revoked_at',i.revoked_at) order by i.created_at desc) from rp_private.owner_invites i where i.cafe_id=c.id),'[]'),
 'stats',jsonb_build_object('orders',(select count(*) from public.rp_orders o where o.cafe_id=c.id and o.created_at>=f and o.created_at<t and o.status<>'cancelled'),
 'order_amount',coalesce((select sum(ii.quantity*ii.unit_price_minor) from public.rp_order_items ii join public.rp_orders o on o.id=ii.order_id and o.cafe_id=ii.cafe_id where o.cafe_id=c.id and o.created_at>=f and o.created_at<t and o.status<>'cancelled' and ii.cancelled_at is null),0),
 'recorded_payments',coalesce((select sum(case when p.kind='refund' then -p.amount_minor else p.amount_minor end) from public.rp_payments p where p.cafe_id=c.id and p.recorded_at>=f and p.recorded_at<t),0))
 ) order by c.created_at desc),'[]'),'from',f,'to',t) into result from public.rp_cafes c;
 return result;
end$$;

create function rp_private.admin_command(r uuid,a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare c uuid; i uuid; u uuid; em text; rec rp_private.receipts; result jsonb; token text;
begin
 perform rp_private.require_admin();
 if r is null or b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>8192 then raise exception 'INVALID_COMMAND'; end if;
 -- Admin lock serializes cafe creation, invitation replacement and retries.
 perform pg_advisory_xact_lock(617324910);
 token:=b->>'token';
 if a='invite' then b:=b-'token'||jsonb_build_object('token_hash',encode(sha256(convert_to(token,'UTF8')),'hex')); end if;
 c:=(b->>'cafe_id')::uuid;
 if a='create' then
  c:=r;
  if exists(select 1 from public.rp_cafes where id=c) then
   select * into rec from rp_private.receipts where cafe_id=c and request_id=r;
   if rec.actor_id=auth.uid() and rec.action='admin_create' and rec.body=b then return rec.result; end if;
   raise exception 'REQUEST_ID_REUSED';
  end if;
  insert into public.rp_cafes(id,name,slug) values(c,trim(b->>'name'),b->>'slug');
 else
  perform 1 from public.rp_cafes where id=c for update;
  if not found then raise exception 'CAFE_NOT_FOUND'; end if;
  select * into rec from rp_private.receipts where cafe_id=c and request_id=r;
  if found then
   if rec.actor_id<>auth.uid() or rec.action<>'admin_'||a or rec.body<>b then raise exception 'REQUEST_ID_REUSED'; end if;
   return rec.result;
  end if;
  if a='rename' then update public.rp_cafes set name=trim(b->>'name') where id=c;
  elsif a in ('pause','activate','archive','restore') then
   update public.rp_cafes set active=(a in ('activate','restore')),archived_at=case when a='archive' then now() when a='restore' then null else archived_at end where id=c;
   if a='archive' then update rp_private.owner_invites set revoked_at=now() where cafe_id=c and accepted_at is null and revoked_at is null; end if;
  elsif a='invite' then
   if exists(select 1 from public.rp_cafes where id=c and archived_at is not null) then raise exception 'CAFE_ARCHIVED'; end if;
   em:=lower(trim(b->>'email'));
   if em is null or em !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' or token is null or token !~ '^[a-f0-9]{64}$' then raise exception 'INVALID_INVITE'; end if;
   if exists(select 1 from public.rp_memberships where cafe_id=c and role='owner' and active) then raise exception 'OWNER_ALREADY_ACTIVE'; end if;
   update rp_private.owner_invites set revoked_at=now() where cafe_id=c and accepted_at is null and revoked_at is null;
   insert into rp_private.owner_invites(cafe_id,email,token_hash,created_by) values(c,em,encode(sha256(convert_to(token,'UTF8')),'hex'),auth.uid()) returning id into i;
  elsif a='invite_revoke' then
   update rp_private.owner_invites set revoked_at=now() where cafe_id=c and id=(b->>'invite_id')::uuid and accepted_at is null and revoked_at is null;
   if not found then raise exception 'INVITE_NOT_PENDING'; end if;
  elsif a='owner_revoke' then
   u:=(b->>'user_id')::uuid;
   update public.rp_memberships set active=false where cafe_id=c and user_id=u and role='owner';
   if not found then raise exception 'OWNER_NOT_FOUND'; end if;
  else raise exception 'UNKNOWN_COMMAND'; end if;
 end if;
 result:=jsonb_build_object('ok',true,'cafe_id',c,'invite_id',i);
 -- Never retain raw invitation token in receipt/audit. Compare hashed body on retry.
 insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'admin_'||a,b,result);
 insert into rp_private.admin_events(actor_id,action,cafe_id,details) values(auth.uid(),a,c,jsonb_build_object('invite_id',i,'target_user',u));
 return result;
end$$;

create function rp_private.accept_owner_invite(token text) returns uuid language plpgsql security definer set search_path='' as $$
declare inv rp_private.owner_invites; em text;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED' using errcode='42501'; end if;
 select lower(email) into em from auth.users where id=auth.uid() and email_confirmed_at is not null and deleted_at is null;
 if em is null then raise exception 'CONFIRM_EMAIL' using errcode='42501'; end if;
 if token is null or token !~ '^[a-f0-9]{64}$' then raise exception 'INVITE_UNAVAILABLE'; end if;
 -- Same global lock order as admin commands avoids revoke/redeem races.
 perform pg_advisory_xact_lock(617324910);
 select * into inv from rp_private.owner_invites where token_hash=encode(sha256(convert_to(token,'UTF8')),'hex') for update;
 if not found or inv.revoked_at is not null or inv.accepted_at is not null or inv.expires_at<=now() then raise exception 'INVITE_UNAVAILABLE'; end if;
 if em<>inv.email then raise exception 'INVITE_EMAIL_MISMATCH' using errcode='42501'; end if;
 perform 1 from public.rp_cafes where id=inv.cafe_id and active and archived_at is null for update;
 if not found then raise exception 'CAFE_UNAVAILABLE'; end if;
 if exists(select 1 from public.rp_memberships where cafe_id=inv.cafe_id and role='owner' and active) then raise exception 'OWNER_ALREADY_ACTIVE'; end if;
 insert into public.rp_memberships(cafe_id,user_id,role,display_name,active) values(inv.cafe_id,auth.uid(),'owner',split_part(em,'@',1),true)
 on conflict(cafe_id,user_id) do update set role='owner',active=true;
 update rp_private.owner_invites set accepted_at=now(),accepted_by=auth.uid() where id=inv.id;
 insert into rp_private.admin_events(actor_id,action,cafe_id) values(auth.uid(),'invite_accepted',inv.cafe_id);
 return inv.cafe_id;
end$$;
create function public.rp_admin_overview(f timestamptz,t timestamptz) returns jsonb language sql security invoker set search_path='' as $$select rp_private.admin_overview(f,t)$$;
create function public.rp_admin_command(r uuid,a text,b jsonb) returns jsonb language sql security invoker set search_path='' as $$select rp_private.admin_command(r,a,b)$$;
create function public.rp_accept_owner_invite(token text) returns uuid language sql security invoker set search_path='' as $$select rp_private.accept_owner_invite(token)$$;
revoke all on all tables in schema rp_private from public,anon,authenticated;
revoke all on all functions in schema rp_private from public,anon,authenticated;
revoke all on function public.rp_admin_overview(timestamptz,timestamptz),public.rp_admin_command(uuid,text,jsonb),public.rp_accept_owner_invite(text) from public,anon,authenticated;
commit;
select 'ADMIN_INSTALLED_CLOSED' as result;
