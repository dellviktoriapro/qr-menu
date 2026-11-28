-- Generic lock-screen notifications. No guest phone, dish or financial data in payloads.
begin;
create table rp_private.push_config(id boolean primary key default true check(id),public_key text not null,private_key text not null,dispatch_token text not null,enabled boolean not null default false,started_at timestamptz not null default now());
create table rp_private.push_subscriptions(id uuid primary key default gen_random_uuid(),cafe_id uuid not null references public.rp_cafes(id),user_id uuid not null references auth.users(id),endpoint text not null,keys jsonb not null,created_at timestamptz not null default now(),unique(cafe_id,endpoint));
create table rp_private.push_events(id uuid primary key default gen_random_uuid(),cafe_id uuid not null references public.rp_cafes(id),source text not null check(source in ('web','guest','test')),source_id uuid not null,kind text not null check(kind in ('new','online','overdue','test')),created_at timestamptz not null default now(),unique(source,source_id,kind));
create table rp_private.push_deliveries(id uuid primary key default gen_random_uuid(),event_id uuid not null references rp_private.push_events(id) on delete cascade,subscription_id uuid not null references rp_private.push_subscriptions(id) on delete cascade,state text not null default 'pending' check(state in ('pending','leased','sent','failed','cancelled')),attempts integer not null default 0,lease uuid,lease_until timestamptz,last_error text,unique(event_id,subscription_id));
create index rp_push_work on rp_private.push_deliveries(state,lease_until);
alter table rp_private.push_config enable row level security;
alter table rp_private.push_subscriptions enable row level security;
alter table rp_private.push_events enable row level security;
alter table rp_private.push_deliveries enable row level security;
revoke all on rp_private.push_config,rp_private.push_subscriptions,rp_private.push_events,rp_private.push_deliveries from public,anon,authenticated;
create function rp_private.push_recipient(c uuid,u uuid) returns boolean language sql stable security definer set search_path='' as $$
select exists(select 1 from public.rp_cafes c1 where c1.id=c and c1.active and c1.archived_at is null) and exists(select 1 from auth.users a where a.id=u and a.deleted_at is null) and (
 exists(select 1 from public.rp_memberships m where m.cafe_id=c and m.user_id=u and m.active and (m.role in ('owner','manager') or (m.role='waiter' and exists(select 1 from rp_private.member_profiles p where p.cafe_id=c and p.user_id=u and p.on_shift))))
 or exists(select 1 from rp_private.platform_admins a where a.user_id=u and a.active));
$$;
create function public.rp_push_config(c uuid) returns jsonb language plpgsql security definer set search_path='' as $$
begin perform rp_private.require_member(c);return (select jsonb_build_object('enabled',enabled,'public_key',public_key,'reminder_seconds',180) from rp_private.push_config where id);end $$;
create function public.rp_push_subscribe(c uuid,s jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare sub_id uuid;ep text:=s->>'endpoint';m public.rp_memberships;
begin
 m:=rp_private.require_member(c);if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED';end if;
 if not exists(select 1 from rp_private.push_config where enabled) then raise exception 'PUSH_NOT_ENABLED';end if;
 if s is null or octet_length(s::text)>8192 or ep !~ '^https://(fcm.googleapis.com|updates.push.services.mozilla.com|web.push.apple.com|[a-z0-9.-]+\.notify.windows.com)/[^[:space:]]+$' or coalesce(s#>>'{keys,p256dh}','') !~ '^[A-Za-z0-9_-]{87}=?$' or coalesce(s#>>'{keys,auth}','') !~ '^[A-Za-z0-9_-]{22}==?$' and coalesce(s#>>'{keys,auth}','') !~ '^[A-Za-z0-9_-]{22}$' then raise exception 'INVALID_PUSH_SUBSCRIPTION';end if;
 insert into rp_private.push_subscriptions(cafe_id,user_id,endpoint,keys) values(c,auth.uid(),ep,s->'keys') on conflict(cafe_id,endpoint) do update set user_id=excluded.user_id,keys=excluded.keys,created_at=clock_timestamp() returning id into sub_id;
 return jsonb_build_object('ok',true,'id',sub_id);
end $$;
create function public.rp_push_unsubscribe(ep text) returns void language plpgsql security definer set search_path='' as $$
begin if auth.uid() is null then raise exception 'AUTH_REQUIRED';end if;delete from rp_private.push_subscriptions where user_id=auth.uid() and endpoint=ep;end $$;
create function rp_private.push_pending(src text,i uuid) returns boolean language sql stable security definer set search_path='' as $$
select case when src='test' then true when src='web' then exists(select 1 from rp_private.web_orders where id=i and accepted_at is null and rejected_at is null) else exists(select 1 from rp_private.guest_submissions where id=i and accepted_at is null and rejected_at is null) end;
$$;
create function rp_private.push_enqueue(c uuid,src text,i uuid,k text) returns void language plpgsql security definer set search_path='' as $$
declare eid uuid;
begin
 if not exists(select 1 from rp_private.push_config where enabled) then return;end if;
 insert into rp_private.push_events(cafe_id,source,source_id,kind) values(c,src,i,k) on conflict do nothing returning id into eid;
 if eid is null then return;end if;
 insert into rp_private.push_deliveries(event_id,subscription_id) select eid,s.id from rp_private.push_subscriptions s where s.cafe_id=c and rp_private.push_recipient(c,s.user_id);
end $$;
create function rp_private.push_wake() returns void language plpgsql security definer set search_path='' as $$
declare secret text;
begin
 select dispatch_token into secret from rp_private.push_config where enabled;
 if secret is null or not exists(select 1 from rp_private.push_deliveries where state in ('pending','leased') and (lease_until is null or lease_until<now())) then return;end if;
 perform net.http_post(url:='https://vppgtrbewgqigfinknex.supabase.co/functions/v1/order-push',headers:=jsonb_build_object('Content-Type','application/json','X-Worker-Key',secret),body:='{}'::jsonb,timeout_milliseconds:=10000);
exception when others then return;
end $$;
create function rp_private.push_new_order() returns trigger language plpgsql security definer set search_path='' as $$
begin
 perform rp_private.push_enqueue(new.cafe_id,case when tg_table_name='web_orders' then 'web' else 'guest' end,new.id,case when tg_table_name='web_orders' and to_jsonb(new)->>'channel'='online' then 'online' else 'new' end);
 perform rp_private.push_wake();return new;
end $$;
create trigger rp_push_web after insert on rp_private.web_orders for each row execute function rp_private.push_new_order();
create trigger rp_push_guest after insert on rp_private.guest_submissions for each row execute function rp_private.push_new_order();
create function rp_private.push_tick() returns void language plpgsql security definer set search_path='' as $$
declare o record;started timestamptz;
begin
 select started_at into started from rp_private.push_config where enabled;if started is null then return;end if;
 for o in select cafe_id,id,'web' src from rp_private.web_orders where accepted_at is null and rejected_at is null and created_at>=greatest(started,now()-interval '1 hour') and created_at<=now()-interval '3 minutes'
 union all select cafe_id,id,'guest' from rp_private.guest_submissions where accepted_at is null and rejected_at is null and created_at>=greatest(started,now()-interval '1 hour') and created_at<=now()-interval '3 minutes' loop
 perform rp_private.push_enqueue(o.cafe_id,o.src,o.id,'overdue');end loop;
 perform rp_private.push_wake();
 delete from rp_private.push_events where created_at<now()-interval '7 days';
end $$;
create function public.rp_push_test(c uuid,ep text) returns void language plpgsql security definer set search_path='' as $$
declare sid uuid;eid uuid;
begin
 perform rp_private.require_member(c);
 select id into sid from rp_private.push_subscriptions where cafe_id=c and user_id=auth.uid() and endpoint=ep;
 if sid is null then raise exception 'PUSH_NOT_CONNECTED';end if;
 if (select count(*) from rp_private.push_events where cafe_id=c and source='test' and created_at>now()-interval '1 minute')>=5 then raise exception 'RATE_LIMIT';end if;
 insert into rp_private.push_events(cafe_id,source,source_id,kind) values(c,'test',gen_random_uuid(),'test') returning id into eid;
 insert into rp_private.push_deliveries(event_id,subscription_id) values(eid,sid);perform rp_private.push_wake();
end $$;
revoke all on function public.rp_push_test(uuid,text) from public,anon,authenticated;
grant execute on function public.rp_push_test(uuid,text) to authenticated;
-- Only service-role worker can read subscription endpoints/encryption and signing keys.
create function public.rp_push_initialize(actor uuid,pub text,priv text,secret text) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from rp_private.platform_admins a join auth.users u on u.id=a.user_id where a.user_id=actor and a.active and u.email_confirmed_at is not null and u.deleted_at is null) then raise exception 'ADMIN_REQUIRED';end if;
 if pub !~ '^[A-Za-z0-9_-]{87}$' or priv !~ '^[A-Za-z0-9_-]{43}$' or secret !~ '^[a-f0-9]{64}$' then raise exception 'INVALID_PUSH_KEYS';end if;
 insert into rp_private.push_config(public_key,private_key,dispatch_token,enabled) values(pub,priv,secret,true) on conflict(id) do update set enabled=true;
 return jsonb_build_object('enabled',true);
end $$;
revoke all on function public.rp_push_initialize(uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.rp_push_initialize(uuid,text,text,text) to service_role;
create function public.rp_push_worker_config() returns jsonb language sql security definer set search_path='' as $$select to_jsonb(c) from rp_private.push_config c where id and enabled$$;
create function public.rp_push_claim() returns jsonb language plpgsql security definer set search_path='' as $$
declare lease_id uuid:=gen_random_uuid();result jsonb;
begin
 update rp_private.push_deliveries d set state='cancelled' from rp_private.push_events e,rp_private.push_subscriptions s where d.event_id=e.id and d.subscription_id=s.id and d.state in ('pending','leased') and (e.created_at<now()-interval '15 minutes' or not rp_private.push_pending(e.source,e.source_id) or not rp_private.push_recipient(e.cafe_id,s.user_id));
 with work as(select id from rp_private.push_deliveries where (state='pending' and (lease_until is null or lease_until<now()) or state='leased' and lease_until<now()) and attempts<4 order by id for update skip locked limit 60)
 update rp_private.push_deliveries d set state='leased',attempts=attempts+1,lease=lease_id,lease_until=now()+interval '90 seconds' from work where d.id=work.id;
 select coalesce(jsonb_agg(jsonb_build_object('id',d.id,'lease',d.lease,'endpoint',s.endpoint,'keys',s.keys,'cafe_id',e.cafe_id,'kind',e.kind,'event_id',e.id)),'[]') into result from rp_private.push_deliveries d join rp_private.push_events e on e.id=d.event_id join rp_private.push_subscriptions s on s.id=d.subscription_id where d.lease=lease_id;
 return result;
end $$;
create function public.rp_push_ack(i uuid,l uuid,status integer) returns void language plpgsql security definer set search_path='' as $$
declare sid uuid;
begin
 update rp_private.push_deliveries set state=case when status between 200 and 299 then 'sent' when status in (404,410) or attempts>=4 then 'failed' else 'pending' end,lease_until=case when status between 200 and 299 then null else now()+interval '1 minute' end,last_error=case when status between 200 and 299 then null else status::text end where id=i and lease=l and state='leased' returning subscription_id into sid;
 if status in (404,410) and sid is not null then delete from rp_private.push_subscriptions where id=sid;end if;
end $$;
revoke all on function rp_private.push_recipient(uuid,uuid),rp_private.push_pending(text,uuid),rp_private.push_enqueue(uuid,text,uuid,text),rp_private.push_wake(),rp_private.push_new_order(),rp_private.push_tick() from public,anon,authenticated;
revoke all on function public.rp_push_config(uuid),public.rp_push_subscribe(uuid,jsonb),public.rp_push_unsubscribe(text),public.rp_push_worker_config(),public.rp_push_claim(),public.rp_push_ack(uuid,uuid,integer) from public,anon,authenticated;
grant execute on function public.rp_push_config(uuid),public.rp_push_subscribe(uuid,jsonb),public.rp_push_unsubscribe(text) to authenticated;
grant execute on function public.rp_push_worker_config(),public.rp_push_claim(),public.rp_push_ack(uuid,uuid,integer) to service_role;
commit;
