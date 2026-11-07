-- Staff/QR commands are server-only. No anonymous/authenticated table or gateway grants.
begin;
create table rp_private.staff_invites(id uuid primary key default gen_random_uuid(),cafe_id uuid not null references public.rp_cafes(id),email text not null,name text not null,token_hash text not null unique,created_by uuid not null references auth.users(id),created_at timestamptz not null default now(),expires_at timestamptz not null default now()+interval '48 hours',revoked_at timestamptz,accepted_at timestamptz);
create index staff_invites_cafe on rp_private.staff_invites(cafe_id,created_at desc);
create table rp_private.staff_requests(id uuid primary key,invite_id uuid not null unique references rp_private.staff_invites(id),user_id uuid references auth.users(id),state text not null default 'reserved' check(state in ('reserved','pending','approving','approved','failed','rejected')),code text not null default upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),phone text not null default '',reused_account boolean not null default false,approved_by uuid references auth.users(id),approved_role text check(approved_role in ('manager','waiter','kitchen','bar')),created_at timestamptz not null default now());
create table rp_private.member_profiles(cafe_id uuid not null,user_id uuid not null,phone text not null default '',tip_path text,on_shift boolean not null default false,deleted_at timestamptz,primary key(cafe_id,user_id),foreign key(cafe_id,user_id) references public.rp_memberships(cafe_id,user_id));
create table rp_private.cafe_settings(cafe_id uuid primary key references public.rp_cafes(id),notify text not null default 'esc' check(notify in ('all','taker','esc')),reviews jsonb not null default '{}',payment_path text);
create table rp_private.staff_events(id uuid primary key default gen_random_uuid(),cafe_id uuid not null references public.rp_cafes(id),actor_id uuid references auth.users(id),kind text not null,target_id uuid,details jsonb not null default '{}',created_at timestamptz not null default now());
create index staff_events_cafe on rp_private.staff_events(cafe_id,created_at desc);
create table rp_private.qr_uploads(id uuid primary key,cafe_id uuid not null references public.rp_cafes(id),actor_id uuid not null references auth.users(id),kind text not null check(kind in ('payment','tip')),content_hash text not null,path text not null unique,committed_at timestamptz,created_at timestamptz not null default now());
alter table rp_private.staff_invites enable row level security;
alter table rp_private.staff_requests enable row level security;
alter table rp_private.member_profiles enable row level security;
alter table rp_private.cafe_settings enable row level security;
alter table rp_private.staff_events enable row level security;
alter table rp_private.qr_uploads enable row level security;
revoke all on rp_private.staff_invites,rp_private.staff_requests,rp_private.member_profiles,rp_private.cafe_settings,rp_private.staff_events,rp_private.qr_uploads from public,anon,authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('restaurant-qr','restaurant-qr',false,262144,array['image/jpeg','image/png','image/webp']) on conflict(id) do nothing;

create function rp_private.staff_gateway(a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare c uuid;actor uuid;m public.rp_memberships;inv rp_private.staff_invites;q rp_private.staff_requests;up rp_private.qr_uploads;rec rp_private.receipts;result jsonb;token text;em text;target uuid;rr text;oldrole text;oldactive boolean;request uuid;
begin
 if b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>8192 then raise exception 'INVALID_REQUEST';end if;
 if a in ('reserve','status') then
  if b->>'token' is null or b->>'token'!~'^[a-f0-9]{64}$' then raise exception 'INVITE_UNAVAILABLE';end if;
  select * into inv from rp_private.staff_invites where token_hash=encode(sha256(convert_to(b->>'token','UTF8')),'hex') for update;
  if not found then raise exception 'INVITE_UNAVAILABLE';end if;
  if a='status' then
   select * into q from rp_private.staff_requests where invite_id=inv.id and id=(b->>'request_id')::uuid;
   if not found then raise exception 'REQUEST_UNAVAILABLE';end if;
   if q.state='reserved' and inv.revoked_at is null and inv.expires_at>now() then
    select id into target from auth.users where lower(email)=inv.email and email_confirmed_at is null and deleted_at is null and raw_app_meta_data->>'staff_request_id'=q.id::text;
    if target is not null then insert into rp_private.manual_accounts(user_id) values(target) on conflict do nothing;update rp_private.staff_requests set user_id=target,state='pending' where id=q.id returning * into q;end if;
   end if;
   return jsonb_build_object('existing_account',q.reused_account,'state',case when q.state='approved' then 'approved' when inv.revoked_at is not null then 'rejected' when inv.expires_at<=now() then 'expired' else q.state end,'code',q.code);
  end if;
  if inv.revoked_at is not null or inv.accepted_at is not null or inv.expires_at<=now() or lower(trim(b->>'email')) is distinct from inv.email or not exists(select 1 from public.rp_cafes where id=inv.cafe_id and active) then raise exception 'INVITE_UNAVAILABLE';end if;
  if length(coalesce(b->>'phone',''))>40 then raise exception 'INVALID_PHONE';end if;
  select * into q from rp_private.staff_requests where invite_id=inv.id for update;
  if found then
   if q.id<>(b->>'request_id')::uuid or q.state not in ('reserved','pending','approving') then raise exception 'REQUEST_UNAVAILABLE';end if;
   if q.user_id is not null then return jsonb_build_object('reuse_user_id',q.user_id,'code',q.code,'state',q.state);end if;
   select id into target from auth.users where lower(email)=inv.email and email_confirmed_at is null and deleted_at is null and raw_app_meta_data->>'staff_request_id'=q.id::text;
   if target is not null then insert into rp_private.manual_accounts(user_id) values(target) on conflict do nothing;update rp_private.staff_requests set user_id=target,state='pending' where id=q.id returning * into q;return jsonb_build_object('reuse_user_id',target,'code',q.code,'state','pending');end if;
   return jsonb_build_object('email',inv.email);
  end if;
  insert into rp_private.staff_requests(id,invite_id,phone) values((b->>'request_id')::uuid,inv.id,coalesce(b->>'phone',''));
  select u.id into target from auth.users u where lower(u.email)=inv.email and u.email_confirmed_at is null and u.deleted_at is null and exists(select 1 from rp_private.staff_requests oldq join rp_private.staff_invites oldi on oldi.id=oldq.invite_id where oldi.cafe_id=inv.cafe_id and u.raw_app_meta_data->>'staff_request_id'=oldq.id::text);
  if target is not null then insert into rp_private.manual_accounts(user_id) values(target) on conflict do nothing;update rp_private.staff_requests set user_id=target,state='pending',reused_account=true where id=(b->>'request_id')::uuid returning * into q;return jsonb_build_object('reuse_user_id',target,'code',q.code,'state','pending');end if;
  return jsonb_build_object('email',inv.email);
 elsif a in ('registered','failed') then
  select * into q from rp_private.staff_requests where id=(b->>'request_id')::uuid for update;
  if not found or q.state<>'reserved' then raise exception 'REQUEST_UNAVAILABLE';end if;
  if a='failed' then update rp_private.staff_requests set state='failed' where id=q.id;return jsonb_build_object('ok',true);end if;
  select * into inv from rp_private.staff_invites where id=q.invite_id;
  if inv.revoked_at is not null or inv.expires_at<=now() then raise exception 'INVITE_UNAVAILABLE';end if;
  select lower(email) into em from auth.users where id=(b->>'user_id')::uuid and email_confirmed_at is null and deleted_at is null;
  if em is distinct from inv.email then raise exception 'USER_MISMATCH';end if;
  insert into rp_private.manual_accounts(user_id) values((b->>'user_id')::uuid);
  update rp_private.staff_requests set user_id=(b->>'user_id')::uuid,state='pending' where id=q.id returning * into q;
  return jsonb_build_object('state',q.state,'code',q.code);
 end if;
 -- actor_id is injected only by the Edge Function after Auth getUser(jwt).
 actor:=(b->>'actor_id')::uuid;c:=(b->>'cafe_id')::uuid;
 if actor is null then raise exception 'AUTH_REQUIRED' using errcode='42501';end if;
 if a='join_existing' then
  select * into inv from rp_private.staff_invites where token_hash=encode(sha256(convert_to(b->>'token','UTF8')),'hex') for update;
  if not found or inv.revoked_at is not null or inv.accepted_at is not null or inv.expires_at<=now() then raise exception 'INVITE_UNAVAILABLE';end if;
  if not exists(select 1 from auth.users where id=actor and lower(email)=inv.email and email_confirmed_at is not null and deleted_at is null) then raise exception 'EMAIL_MISMATCH';end if;
  if not exists(select 1 from public.rp_cafes where id=inv.cafe_id and active) then raise exception 'CAFE_UNAVAILABLE';end if;
  insert into rp_private.staff_requests(id,invite_id,user_id,state,phone) values((b->>'request_id')::uuid,inv.id,actor,'pending',left(coalesce(b->>'phone',''),40)) returning * into q;
  return jsonb_build_object('state',q.state,'code',q.code);
 end if;
 perform 1 from public.rp_cafes where id=c and active for update;
 if not found then raise exception 'ACCESS_DENIED' using errcode='42501';end if;
 select * into m from public.rp_memberships where cafe_id=c and user_id=actor and active;
 if not found or not exists(select 1 from auth.users where id=actor and email_confirmed_at is not null and deleted_at is null) then raise exception 'ACCESS_DENIED' using errcode='42501';end if;
 if a='snapshot' then
  return jsonb_build_object('cafe_id',c,'role',m.role,'me',actor,
   'settings',coalesce((select to_jsonb(s)-'cafe_id' from rp_private.cafe_settings s where cafe_id=c),'{"notify":"esc","reviews":{}}'),
   'members',coalesce((select jsonb_agg(jsonb_build_object('id',x.user_id,'name',x.display_name,'role',x.role,'active',x.active,'phone',case when m.role in ('owner','manager') or x.user_id=actor then coalesce(p.phone,'') else '' end,'tip_path',case when m.role in ('owner','manager') or x.user_id=actor then p.tip_path end,'on_shift',coalesce(p.on_shift,false),'deleted_at',p.deleted_at)) from public.rp_memberships x left join rp_private.member_profiles p on p.cafe_id=x.cafe_id and p.user_id=x.user_id where x.cafe_id=c),'[]'),
   'invites',case when m.role='owner' then coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'email',i.email,'name',i.name,'expires_at',i.expires_at,'revoked_at',i.revoked_at,'accepted_at',i.accepted_at,'request_id',r.id,'request_at',r.created_at,'state',r.state,'phone',r.phone) order by i.created_at desc) from rp_private.staff_invites i left join rp_private.staff_requests r on r.invite_id=i.id where i.cafe_id=c and i.created_at>now()-interval '30 days'),'[]') else '[]'::jsonb end,
   'events',case when m.role='owner' then coalesce((select jsonb_agg(to_jsonb(e)) from (select * from rp_private.staff_events where cafe_id=c order by created_at desc limit 40) e),'[]') else '[]'::jsonb end);
 end if;
 if a in ('prepare_approval','finish_approval','reject') then
  if m.role<>'owner' then raise exception 'OWNER_REQUIRED' using errcode='42501';end if;
  select r.* into q from rp_private.staff_requests r join rp_private.staff_invites i on i.id=r.invite_id where r.id=(case when a='reject' then b->>'pending_id' else b->>'request_id' end)::uuid and i.cafe_id=c for update of r;
  if not found then raise exception 'REQUEST_UNAVAILABLE';end if;
  select * into inv from rp_private.staff_invites where id=q.invite_id for update;
  if a='reject' and q.state='rejected' then return jsonb_build_object('ok',true);end if;
  if a='reject' and q.state in ('reserved','pending','approving') then update rp_private.staff_requests set state='rejected' where id=q.id;update rp_private.staff_invites set revoked_at=now() where id=inv.id;return jsonb_build_object('ok',true);end if;
  if q.code is distinct from upper(b->>'code') or q.user_id is null then raise exception 'CODE_MISMATCH';end if;
  if q.state='approved' then return jsonb_build_object('state','approved','user_id',q.user_id);end if;
  rr:=b->>'role';
  if rr is null or rr not in ('manager','waiter','kitchen','bar') or q.state not in ('pending','approving') or inv.revoked_at is not null or inv.accepted_at is not null or inv.expires_at<=now() then raise exception 'INVITE_UNAVAILABLE';end if;
  if exists(select 1 from public.rp_memberships where cafe_id=c and user_id=q.user_id and role='owner') then raise exception 'OWNER_IMMUTABLE';end if;
  if a='prepare_approval' then
   if q.state='approving' and (q.approved_by<>actor or q.approved_role<>rr) then raise exception 'APPROVAL_IN_PROGRESS';end if;
   update rp_private.staff_requests set state='approving',approved_by=actor,approved_role=rr where id=q.id;
   return jsonb_build_object('state','approving','user_id',q.user_id);
  end if;
  if q.state<>'approving' or q.approved_by<>actor or q.approved_role<>rr or not exists(select 1 from auth.users where id=q.user_id and lower(email)=inv.email and email_confirmed_at is not null and deleted_at is null) then raise exception 'ACCOUNT_NOT_READY';end if;
  insert into public.rp_memberships(cafe_id,user_id,role,display_name) values(c,q.user_id,rr,inv.name) on conflict(cafe_id,user_id) do update set role=excluded.role,display_name=excluded.display_name,active=true where rp_memberships.role<>'owner';
  insert into rp_private.member_profiles(cafe_id,user_id,phone) values(c,q.user_id,q.phone) on conflict(cafe_id,user_id) do update set phone=excluded.phone,deleted_at=null;
  update rp_private.staff_requests set state='approved' where id=q.id;update rp_private.staff_invites set accepted_at=now() where id=inv.id;
  insert into rp_private.staff_events(cafe_id,actor_id,kind,target_id,details) values(c,actor,'ok',q.user_id,jsonb_build_object('role',rr));
  return jsonb_build_object('state','approved','user_id',q.user_id);
 end if;
 request:=(b->>'request_id')::uuid;if request is null then raise exception 'REQUEST_ID_REQUIRED';end if;
 select * into rec from rp_private.receipts where cafe_id=c and request_id=request;
 if found then if rec.actor_id<>actor or rec.action<>'staff:'||a or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return rec.result;end if;
 if a in ('invite_create','invite_revoke','member_set') and m.role<>'owner' then raise exception 'OWNER_REQUIRED' using errcode='42501';end if;
 if a='invite_create' then
  em:=lower(trim(b->>'email'));
  if em is null or length(em)>254 or em!~'^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' or length(trim(coalesce(b->>'name',''))) not between 1 and 100 then raise exception 'INVALID_INVITE';end if;
  if (select count(*) from rp_private.staff_invites where cafe_id=c and created_at>now()-interval '1 hour')>=30 then raise exception 'RATE_LIMIT';end if;
  update rp_private.staff_invites set revoked_at=now() where cafe_id=c and email=em and accepted_at is null and revoked_at is null;
  token:=replace(gen_random_uuid()::text,'-','')||replace(gen_random_uuid()::text,'-','');
  insert into rp_private.staff_invites(cafe_id,email,name,token_hash,created_by) values(c,em,trim(b->>'name'),encode(sha256(convert_to(token,'UTF8')),'hex'),actor) returning * into inv;
  result:=jsonb_build_object('id',inv.id,'token',token,'expires_at',inv.expires_at,'email',em);
 elsif a='invite_revoke' then
  update rp_private.staff_invites set revoked_at=now() where cafe_id=c and id=(b->>'invite_id')::uuid and accepted_at is null;
  if not found then raise exception 'INVITE_UNAVAILABLE';end if;result:=jsonb_build_object('ok',true);
 elsif a='member_set' then
  target:=(b->>'user_id')::uuid;rr:=b->>'role';
  if target=actor or rr is null or rr not in ('manager','waiter','kitchen','bar') then raise exception 'ROLE_DENIED';end if;
  select role,active into oldrole,oldactive from public.rp_memberships where cafe_id=c and user_id=target and role<>'owner' for update;if not found then raise exception 'MEMBER_NOT_FOUND';end if;
  update public.rp_memberships set role=rr,active=(b->>'active')::boolean where cafe_id=c and user_id=target and role<>'owner';if not found then raise exception 'MEMBER_NOT_FOUND';end if;
  insert into rp_private.member_profiles(cafe_id,user_id,deleted_at,on_shift) values(c,target,case when coalesce((b->>'deleted')::boolean,false) then now() end,false) on conflict(cafe_id,user_id) do update set deleted_at=excluded.deleted_at,on_shift=case when (b->>'active')::boolean then member_profiles.on_shift else false end;
  insert into rp_private.staff_events(cafe_id,actor_id,kind,target_id,details) values(c,actor,case when coalesce((b->>'deleted')::boolean,false) then 'del' when not (b->>'active')::boolean then 'block' when oldactive=false then 'unblock' else 'role' end,target,jsonb_build_object('role',rr));result:=jsonb_build_object('ok',true);
 elsif a in ('reviews','notification') then
  if m.role not in ('owner','manager') then raise exception 'ROLE_DENIED';end if;
  insert into rp_private.cafe_settings(cafe_id) values(c) on conflict do nothing;
  if a='notification' then update rp_private.cafe_settings set notify=b->>'notify' where cafe_id=c;
  else if length(coalesce(b->>'google',''))>2000 or length(coalesce(b->>'tripadvisor',''))>2000 or exists(select 1 from jsonb_each_text(jsonb_build_object('g',coalesce(b->>'google',''),'ta',coalesce(b->>'tripadvisor',''))) x where x.value<>'' and x.value!~'^https://[^[:space:]]+$') then raise exception 'INVALID_URL';end if;update rp_private.cafe_settings set reviews=jsonb_build_object('g',coalesce(b->>'google',''),'ta',coalesce(b->>'tripadvisor','')) where cafe_id=c;end if;
  result:=jsonb_build_object('ok',true);
 elsif a='shift' then
  insert into rp_private.member_profiles(cafe_id,user_id,on_shift) values(c,actor,(b->>'on_shift')::boolean) on conflict(cafe_id,user_id) do update set on_shift=excluded.on_shift;result:=jsonb_build_object('ok',true);
 elsif a='asset_prepare' then
  if (select count(*) from rp_private.qr_uploads where cafe_id=c and actor_id=actor and created_at>now()-interval '1 hour')>=40 or (select count(*) from rp_private.qr_uploads where cafe_id=c and created_at>now()-interval '1 day')>=200 then raise exception 'RATE_LIMIT';end if;
  if b->>'kind' not in ('payment','tip') or b->>'kind' is null or b->>'content_hash'!~'^[a-f0-9]{64}$' or b->>'content_hash' is null then raise exception 'INVALID_ASSET';end if;
  if b->>'kind'='payment' and m.role not in ('owner','manager') then raise exception 'ROLE_DENIED';end if;
  insert into rp_private.qr_uploads(id,cafe_id,actor_id,kind,content_hash,path) values(request,c,actor,b->>'kind',b->>'content_hash',c::text||'/'||(b->>'kind')||'/'||actor::text||'/'||request::text);
  result:=jsonb_build_object('path',c::text||'/'||(b->>'kind')||'/'||actor::text||'/'||request::text);

 elsif a='asset_commit' then
  select * into up from rp_private.qr_uploads where id=(b->>'upload_id')::uuid and cafe_id=c and actor_id=actor for update;
  if not found or up.created_at<now()-interval '1 day' then raise exception 'UPLOAD_UNAVAILABLE';end if;
  if up.kind='payment' and m.role not in ('owner','manager') then raise exception 'ROLE_DENIED';end if;
  if not exists(select 1 from storage.objects where bucket_id='restaurant-qr' and name=up.path) then raise exception 'UPLOAD_NOT_FOUND';end if;
  if up.kind='payment' then insert into rp_private.cafe_settings(cafe_id,payment_path) values(c,up.path) on conflict(cafe_id) do update set payment_path=excluded.payment_path;
  else insert into rp_private.member_profiles(cafe_id,user_id,tip_path) values(c,actor,up.path) on conflict(cafe_id,user_id) do update set tip_path=excluded.tip_path;end if;
  update rp_private.qr_uploads set committed_at=coalesce(committed_at,now()) where id=up.id;
  result:=jsonb_build_object('ok',true,'path',up.path);
 elsif a='asset_remove' then
  if b->>'kind'='payment' then
   if m.role not in ('owner','manager') then raise exception 'ROLE_DENIED';end if;
   update rp_private.cafe_settings set payment_path=null where cafe_id=c;
  elsif b->>'kind'='tip' then update rp_private.member_profiles set tip_path=null where cafe_id=c and user_id=actor;
  else raise exception 'INVALID_ASSET';end if;
  result:=jsonb_build_object('ok',true);
 else raise exception 'UNKNOWN_ACTION';end if;
 insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,request,actor,'staff:'||a,b,case when a='invite_create' then (result-'token')||jsonb_build_object('reissue_required',true) else result end);
 return result;
end $$;
create function public.rp_staff_gateway(a text,b jsonb) returns jsonb language sql security invoker set search_path='' as $$select rp_private.staff_gateway(a,b)$$;
revoke all on function public.rp_staff_gateway(text,jsonb),rp_private.staff_gateway(text,jsonb) from public,anon,authenticated;
grant execute on function public.rp_staff_gateway(text,jsonb),rp_private.staff_gateway(text,jsonb) to service_role;

create function pg_temp.staff_assert(ok boolean,msg text) returns void language plpgsql as $$begin if ok is distinct from true then raise exception 'STAFF_TEST_FAILED: %',msg;end if;end$$;
insert into auth.users(id,email,email_confirmed_at) values('00000000-0000-4000-8000-000000000021','owner21@example.test',now()),('00000000-0000-4000-8000-000000000022','waiter22@example.test',now()),('00000000-0000-4000-8000-000000000023','staff23@example.test',null);
insert into public.rp_cafes(id,slug,name) values('10000000-0000-4000-8000-000000000021','staff-fixture-a','Staff fixture'),('10000000-0000-4000-8000-000000000022','staff-fixture-b','Other staff cafe');
insert into public.rp_memberships(cafe_id,user_id,role,display_name) values('10000000-0000-4000-8000-000000000021','00000000-0000-4000-8000-000000000021','owner','Owner fixture'),('10000000-0000-4000-8000-000000000021','00000000-0000-4000-8000-000000000022','waiter','Waiter fixture');
do $$declare c uuid:='10000000-0000-4000-8000-000000000021';owner_id uuid:='00000000-0000-4000-8000-000000000021';waiter_id uuid:='00000000-0000-4000-8000-000000000022';staff_id uuid:='00000000-0000-4000-8000-000000000023';request_id uuid:='20000000-0000-4000-8000-000000000021';invite_request uuid:='30000000-0000-4000-8000-000000000021';v jsonb;inv jsonb;payload jsonb;code text;begin
 payload:=jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',invite_request,'name','Staff fixture','email','staff23@example.test');
 inv:=rp_private.staff_gateway('invite_create',payload);
 perform pg_temp.staff_assert(length(inv->>'token')=64,'high entropy token');
 v:=rp_private.staff_gateway('invite_create',payload);
 perform pg_temp.staff_assert(v->>'reissue_required'='true' and not v?'token','retry never stores plaintext capability');
 perform pg_temp.staff_assert((select count(*) from rp_private.staff_invites where cafe_id=c)=1,'retry no duplicate invite');
 begin perform rp_private.staff_gateway('reserve',jsonb_build_object('token',inv->>'token','email','wrong@example.test','request_id',request_id));raise exception 'WRONG_EMAIL_ACCEPTED';exception when others then if sqlerrm<>'INVITE_UNAVAILABLE' then raise;end if;end;
 perform rp_private.staff_gateway('reserve',jsonb_build_object('token',inv->>'token','email','staff23@example.test','request_id',request_id,'phone','+84 fixture'));
 v:=rp_private.staff_gateway('reserve',jsonb_build_object('token',inv->>'token','email','staff23@example.test','request_id',request_id,'phone','+84 fixture'));
 perform pg_temp.staff_assert(v->>'email'='staff23@example.test','reserved request resumes after interrupted Edge');
 v:=rp_private.staff_gateway('registered',jsonb_build_object('request_id',request_id,'user_id',staff_id));code:=v->>'code';
 perform pg_temp.staff_assert(v->>'state'='pending','awaits owner');
 perform pg_temp.staff_assert(not exists(select 1 from public.rp_memberships where cafe_id=c and user_id=staff_id),'no premature access');
 v:=rp_private.staff_gateway('snapshot',jsonb_build_object('actor_id',owner_id,'cafe_id',c));perform pg_temp.staff_assert(v->'invites'->0->>'state'='pending' and not (v->'invites'->0)?'code','pending visible, verification code not leaked to owner list');
 begin perform rp_private.staff_gateway('prepare_approval',jsonb_build_object('actor_id',waiter_id,'cafe_id',c,'request_id',request_id,'code',code,'role','waiter'));raise exception 'WAITER_APPROVED_STAFF';exception when insufficient_privilege then null;end;
 begin perform rp_private.staff_gateway('prepare_approval',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',request_id,'code','00000000','role','waiter'));raise exception 'WRONG_CODE_ACCEPTED';exception when others then if sqlerrm<>'CODE_MISMATCH' then raise;end if;end;
 perform rp_private.staff_gateway('prepare_approval',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',request_id,'code',code,'role','waiter'));
 begin perform rp_private.staff_gateway('finish_approval',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',request_id,'code',code,'role','waiter'));raise exception 'UNCONFIRMED_ACCOUNT_ALLOWED';exception when others then if sqlerrm<>'ACCOUNT_NOT_READY' then raise;end if;end;
 update auth.users set email_confirmed_at=now() where id=staff_id;
 perform rp_private.staff_gateway('finish_approval',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',request_id,'code',code,'role','waiter'));
 perform rp_private.staff_gateway('finish_approval',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',request_id,'code',code,'role','waiter'));
 perform pg_temp.staff_assert((select count(*) from public.rp_memberships where cafe_id=c and user_id=staff_id and active and role='waiter')=1,'approval idempotent and scoped');
 perform rp_private.staff_gateway('notification',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',gen_random_uuid(),'notify','all'));
 v:=rp_private.staff_gateway('snapshot',jsonb_build_object('actor_id',owner_id,'cafe_id',c));perform pg_temp.staff_assert(v->'settings'->>'notify'='all','settings persisted');
 begin perform rp_private.staff_gateway('reviews',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',gen_random_uuid(),'google','javascript:alert(1)'));raise exception 'BAD_URL_ALLOWED';exception when others then if sqlerrm<>'INVALID_URL' then raise;end if;end;
 insert into rp_private.member_profiles(cafe_id,user_id,tip_path) values(c,owner_id,c::text||'/tip/owner-fixture');
 v:=rp_private.staff_gateway('snapshot',jsonb_build_object('actor_id',staff_id,'cafe_id',c));
 perform pg_temp.staff_assert(not exists(select 1 from jsonb_array_elements(v->'members') x where x->>'id'=owner_id::text and x->>'tip_path' is not null),'personal QR hidden from other staff');
 begin perform rp_private.staff_gateway('asset_prepare',jsonb_build_object('actor_id',staff_id,'cafe_id',c,'request_id',gen_random_uuid(),'kind','payment','content_hash',repeat('a',64)));raise exception 'WAITER_REPLACED_PAYMENT_QR';exception when others then if sqlerrm<>'ROLE_DENIED' then raise;end if;end;
 v:=rp_private.staff_gateway('asset_prepare',jsonb_build_object('actor_id',staff_id,'cafe_id',c,'request_id','40000000-0000-4000-8000-000000000021','kind','tip','content_hash',repeat('a',64)));
 perform pg_temp.staff_assert(v->>'path' like c::text||'/tip/'||staff_id::text||'/%','own tip path only');
 begin perform rp_private.staff_gateway('snapshot',jsonb_build_object('actor_id',owner_id,'cafe_id','10000000-0000-4000-8000-000000000022'));raise exception 'CROSS_CAFE_LEAK';exception when insufficient_privilege then null;end;
 perform rp_private.staff_gateway('member_set',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',gen_random_uuid(),'user_id',staff_id,'role','bar','active',false));
 begin perform rp_private.staff_gateway('snapshot',jsonb_build_object('actor_id',staff_id,'cafe_id',c));raise exception 'REVOKED_STILL_ALLOWED';exception when insufficient_privilege then null;end;
 begin perform rp_private.staff_gateway('member_set',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',gen_random_uuid(),'user_id',owner_id,'role','bar','active',false));raise exception 'OWNER_CHANGED_SELF';exception when others then if sqlerrm<>'ROLE_DENIED' then raise;end if;end;

 -- Recover a registration if the response was lost after Auth created the account.
 insert into auth.users(id,email,raw_app_meta_data) values('00000000-0000-4000-8000-000000000024','recover24@example.test','{"staff_request_id":"20000000-0000-4000-8000-000000000024"}');
 inv:=rp_private.staff_gateway('invite_create',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',gen_random_uuid(),'name','Recovery fixture','email','recover24@example.test'));
 perform rp_private.staff_gateway('reserve',jsonb_build_object('token',inv->>'token','email','recover24@example.test','request_id','20000000-0000-4000-8000-000000000024'));
 v:=rp_private.staff_gateway('status',jsonb_build_object('token',inv->>'token','request_id','20000000-0000-4000-8000-000000000024'));
 perform pg_temp.staff_assert(v->>'state'='pending','registration response-loss recovery');
 inv:=rp_private.staff_gateway('invite_create',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',gen_random_uuid(),'name','Recovery fixture','email','recover24@example.test'));
 v:=rp_private.staff_gateway('reserve',jsonb_build_object('token',inv->>'token','email','recover24@example.test','request_id','20000000-0000-4000-8000-000000000025'));
 perform pg_temp.staff_assert(v->>'reuse_user_id'='00000000-0000-4000-8000-000000000024','reissue keeps existing unconfirmed account and password');
 perform rp_private.staff_gateway('reject',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',gen_random_uuid(),'pending_id','20000000-0000-4000-8000-000000000025'));
 perform rp_private.staff_gateway('reject',jsonb_build_object('actor_id',owner_id,'cafe_id',c,'request_id',gen_random_uuid(),'pending_id','20000000-0000-4000-8000-000000000025'));
 v:=rp_private.staff_gateway('status',jsonb_build_object('token',inv->>'token','request_id','20000000-0000-4000-8000-000000000025'));
 perform pg_temp.staff_assert(v->>'state'='rejected','rejection visible and repeat-safe');
 perform pg_temp.staff_assert(not (select public from storage.buckets where id='restaurant-qr'),'private QR bucket');
 perform pg_temp.staff_assert(not has_function_privilege('anon','public.rp_staff_gateway(text,jsonb)','execute') and not has_function_privilege('authenticated','public.rp_staff_gateway(text,jsonb)','execute'),'no client gateway execute');
end$$;
set local role service_role;
select pg_temp.staff_assert((public.rp_staff_gateway('snapshot','{"actor_id":"00000000-0000-4000-8000-000000000021","cafe_id":"10000000-0000-4000-8000-000000000021"}'::jsonb)->>'role')='owner','service gateway wrapper usable');
reset role;
rollback;
select 'PASS staff: exact email, one-use token, pending approval/code, role and tenant checks, idempotency, revocation, private QR, no client grants; fixtures rolled back' as result;
