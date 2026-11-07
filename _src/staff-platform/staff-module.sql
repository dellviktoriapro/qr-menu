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
commit;
