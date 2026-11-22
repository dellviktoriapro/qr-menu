-- Phone is the public login identifier. Auth keeps private synthetic email aliases;
-- invitation approval, rather than an unconfigured SMS service, proves identity.
begin;

create or replace function rp_private.normalized_phone(p text) returns text
language plpgsql immutable set search_path='' as $$
declare n text;
begin
 n:=regexp_replace(coalesce(p,''),'[ ()-]','','g');
 if n !~ '^\+[1-9][0-9]{7,14}$' then raise exception 'INVALID_PHONE'; end if;
 return n;
end $$;

alter table rp_private.owner_invites add column if not exists phone text;
create table if not exists rp_private.login_phones(
 phone text primary key,
 user_id uuid not null unique references auth.users(id),
 alias_email text not null unique,
 created_at timestamptz not null default now(),
 constraint login_phone_e164 check(phone ~ '^\+[1-9][0-9]{7,14}$'),
 constraint login_alias_private check(alias_email ~ '^(staff|owner)\.[a-f0-9-]{36}@accounts\.invalid$')
);
alter table rp_private.login_phones enable row level security;
revoke all on rp_private.login_phones from public,anon,authenticated;

create or replace function rp_private.phone_login_alias(p text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare n text; alias text;
begin
 n:=rp_private.normalized_phone(p);
 select l.alias_email into alias from rp_private.login_phones l
 join auth.users u on u.id=l.user_id and u.deleted_at is null
 where l.phone=n and exists(select 1 from public.rp_memberships m
   join public.rp_cafes c on c.id=m.cafe_id
   where m.user_id=l.user_id and m.active and c.active and c.archived_at is null);
 -- Same response shape for a number without an account. Auth rejects its password.
 if alias is null then alias:='staff.'||substr(md5(n),1,8)||'-'||substr(md5(n),9,4)||'-4'||substr(md5(n),14,3)||'-8'||substr(md5(n),18,3)||'-'||substr(md5(n),21,12)||'@accounts.invalid'; end if;
 return jsonb_build_object('alias',alias);
end $$;
create or replace function public.rp_phone_login_alias(p text) returns jsonb
language sql security invoker set search_path='' as $$select rp_private.phone_login_alias(p)$$;
revoke all on function rp_private.phone_login_alias(text),public.rp_phone_login_alias(text) from public,anon,authenticated;
grant execute on function rp_private.phone_login_alias(text),public.rp_phone_login_alias(text) to service_role;

create or replace function rp_private.bind_approved_phone() returns trigger
language plpgsql security definer set search_path='' as $$
declare p text; em text;
begin
 if new.state<>'approved' or old.state='approved' then return new; end if;
 if tg_table_name='staff_requests' then p:=new.phone;
 else select phone into p from rp_private.owner_invites where id=new.invite_id; end if;
 if p is null or p='' then return new; end if; -- Historical email-only invitations.
 p:=rp_private.normalized_phone(p);
 select lower(email) into em from auth.users where id=new.user_id and deleted_at is null;
 if em !~ '^(staff|owner)\.[a-f0-9-]{36}@accounts\.invalid$' then raise exception 'PHONE_LOGIN_ALIAS_REQUIRED'; end if;
 insert into rp_private.login_phones(phone,user_id,alias_email) values(p,new.user_id,em)
 on conflict(user_id) do update set phone=excluded.phone,alias_email=excluded.alias_email;
 return new;
end $$;
drop trigger if exists rp_staff_phone_approved on rp_private.staff_requests;
create trigger rp_staff_phone_approved after update of state on rp_private.staff_requests
for each row execute function rp_private.bind_approved_phone();
drop trigger if exists rp_owner_phone_approved on rp_private.manual_requests;
create trigger rp_owner_phone_approved after update of state on rp_private.manual_requests
for each row execute function rp_private.bind_approved_phone();

create or replace function rp_private.admin_invite_phone(r uuid,c uuid,p text,token text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare n text; alias text; inv rp_private.owner_invites;
begin
 perform rp_private.require_admin();
 if r is null or c is null or token !~ '^[a-f0-9]{64}$' then raise exception 'INVALID_INVITE'; end if;
 n:=rp_private.normalized_phone(p);
 alias:='owner.'||r::text||'@accounts.invalid';
 perform pg_advisory_xact_lock(617324910);
 select * into inv from rp_private.owner_invites where email=alias for update;
 if found then
  if inv.cafe_id<>c or inv.phone<>n or inv.token_hash<>encode(sha256(convert_to(token,'UTF8')),'hex') then raise exception 'REQUEST_ID_REUSED';end if;
  return jsonb_build_object('ok',true,'cafe_id',c,'invite_id',inv.id);
 end if;
 perform 1 from public.rp_cafes where id=c and active and archived_at is null for update;
 if not found then raise exception 'CAFE_UNAVAILABLE';end if;
 if exists(select 1 from public.rp_memberships where cafe_id=c and role='owner' and active) then raise exception 'OWNER_ALREADY_ACTIVE';end if;
 if exists(select 1 from rp_private.login_phones where phone=n) then raise exception 'PHONE_ALREADY_REGISTERED';end if;
 if (select count(*) from rp_private.owner_invites where cafe_id=c and created_at>now()-interval '1 hour')>=10 then raise exception 'RATE_LIMIT';end if;
 update rp_private.owner_invites set revoked_at=now() where cafe_id=c and accepted_at is null and revoked_at is null;
 insert into rp_private.owner_invites(cafe_id,email,phone,token_hash,created_by,mode)
 values(c,alias,n,encode(sha256(convert_to(token,'UTF8')),'hex'),auth.uid(),'manual') returning * into inv;
 insert into rp_private.admin_events(actor_id,action,cafe_id,details) values(auth.uid(),'invite_phone',c,jsonb_build_object('invite_id',inv.id));
 return jsonb_build_object('ok',true,'cafe_id',c,'invite_id',inv.id);
end $$;
create or replace function public.rp_admin_invite_phone(r uuid,c uuid,p text,token text) returns jsonb
language sql security invoker set search_path='' as $$select rp_private.admin_invite_phone(r,c,p,token)$$;
revoke all on function rp_private.admin_invite_phone(uuid,uuid,text,text),public.rp_admin_invite_phone(uuid,uuid,text,text) from public,anon,authenticated;
grant usage on schema rp_private to authenticated;
grant execute on function rp_private.admin_invite_phone(uuid,uuid,text,text),public.rp_admin_invite_phone(uuid,uuid,text,text) to authenticated;

-- Keep existing statistics and enrich the private admin response with phone labels.
do $patch$
declare ddl text;
begin
 ddl:=pg_get_functiondef('rp_private.admin_overview(timestamptz,timestamptz)'::regprocedure);
 if position('''email'',i.email,''mode''' in ddl)=0 then raise exception 'ADMIN_OVERVIEW_CHANGED';end if;
 ddl:=replace(ddl,'''email'',i.email,''mode''','''email'',i.email,''phone'',i.phone,''mode''');
 if position('''email'',u.email,''active''' in ddl)=0 then raise exception 'ADMIN_OWNERS_CHANGED';end if;
 ddl:=replace(ddl,'''email'',u.email,''active''','''email'',u.email,''phone'',(select l.phone from rp_private.login_phones l where l.user_id=m.user_id),''active''');
 execute ddl;
end $patch$;

-- Existing manual invite registration stays available for historical email links.
-- New owner links bind the entered E.164 phone to the administrator's invitation.
do $patch$
declare ddl text;
begin
 ddl:=pg_get_functiondef('rp_private.manual_gateway(text,jsonb)'::regprocedure);
 if position('lower(trim(b->>''email'')) is distinct from inv.email' in ddl)=0 then raise exception 'MANUAL_GATEWAY_CHANGED';end if;
 ddl:=replace(ddl,
  'lower(trim(b->>''email'')) is distinct from inv.email',
  '(case when inv.phone is not null then rp_private.normalized_phone(b->>''phone'') is distinct from inv.phone else lower(trim(b->>''email'')) is distinct from inv.email end)');
 execute ddl;
end $patch$;

commit;
