-- Outbound-only LAN bridge: orders -> kitchen, final receipts -> bar.
-- Bridge token grants only print queue access for its own cafe, never order editing.
begin;
create table rp_private.lan_printers(cafe_id uuid not null references public.rp_cafes(id),purpose text not null check(purpose in ('kitchen','receipt')),label text not null,host text not null default '',port integer not null default 9100 check(port between 1 and 65535),paper_width integer not null default 80 check(paper_width in (58,80)),enabled boolean not null default false,primary key(cafe_id,purpose));
create table rp_private.print_bridges(cafe_id uuid primary key references public.rp_cafes(id),token_hash text not null unique,last_seen timestamptz,created_at timestamptz not null default now());
create table rp_private.lan_print_jobs(id uuid primary key default gen_random_uuid(),cafe_id uuid not null references public.rp_cafes(id),request_id uuid not null,purpose text not null check(purpose in ('kitchen','receipt')),is_test boolean not null default false,order_id uuid,bill_id uuid,payload jsonb not null,state text not null default 'pending' check(state in ('pending','leased','sent','failed','uncertain')),lease uuid,lease_until timestamptz,last_error text,created_at timestamptz not null default now(),sent_at timestamptz,unique(cafe_id,request_id,purpose));
create index rp_lan_print_work on rp_private.lan_print_jobs(cafe_id,state,created_at);
alter table rp_private.lan_printers enable row level security;
alter table rp_private.print_bridges enable row level security;
alter table rp_private.lan_print_jobs enable row level security;
revoke all on rp_private.lan_printers,rp_private.print_bridges,rp_private.lan_print_jobs from public,anon,authenticated;
create function rp_private.lan_host(h text) returns boolean language plpgsql immutable set search_path='' as $$
declare ip inet;
begin
 if coalesce(h,'') !~ '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' then return false;end if;
 ip:=h::inet;return ip<<'10.0.0.0/8'::inet or ip<<'172.16.0.0/12'::inet or ip<<'192.168.0.0/16'::inet;
exception when others then return false;
end $$;
create function public.rp_lan_printers(c uuid,b jsonb default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;x jsonb;
begin
 m:=rp_private.require_member(c);if m.role<>'owner' then raise exception 'OWNER_REQUIRED' using errcode='42501';end if;
 if b is not null then
  if jsonb_typeof(b)<>'array' or jsonb_array_length(b)<>2 or octet_length(b::text)>4096 then raise exception 'INVALID_PRINTER_SETTINGS';end if;
  if (select count(distinct v->>'purpose') from jsonb_array_elements(b) v where v->>'purpose' in ('kitchen','receipt'))<>2 then raise exception 'INVALID_PRINTER_PURPOSE';end if;
  for x in select * from jsonb_array_elements(b) loop
   if length(coalesce(x->>'label','')) not between 1 and 100 or coalesce((x->>'port')::integer,0) not between 1 and 65535 or coalesce((x->>'paper_width')::integer,0) not in (58,80) or ((x->>'enabled')::boolean and not rp_private.lan_host(x->>'host')) then raise exception 'INVALID_PRINTER_SETTINGS';end if;
  end loop;
  if b->0->>'host'=b->1->>'host' and b->0->>'port'=b->1->>'port' and (b->0->>'enabled')::boolean and (b->1->>'enabled')::boolean then raise exception 'SAME_PRINTER_TARGET';end if;
  for x in select * from jsonb_array_elements(b) loop
   insert into rp_private.lan_printers(cafe_id,purpose,label,host,port,paper_width,enabled) values(c,x->>'purpose',trim(x->>'label'),trim(coalesce(x->>'host','')),(x->>'port')::integer,(x->>'paper_width')::integer,coalesce((x->>'enabled')::boolean,false))
   on conflict(cafe_id,purpose) do update set label=excluded.label,host=excluded.host,port=excluded.port,paper_width=excluded.paper_width,enabled=excluded.enabled;
  end loop;
 end if;
 return jsonb_build_object('routes',coalesce((select jsonb_agg(to_jsonb(p)-'cafe_id' order by p.purpose) from rp_private.lan_printers p where cafe_id=c),'[]'),'paired',exists(select 1 from rp_private.print_bridges where cafe_id=c),'last_seen',(select last_seen from rp_private.print_bridges where cafe_id=c),'jobs',coalesce((select jsonb_agg(to_jsonb(j)) from (select id,purpose,is_test,state,last_error,created_at,sent_at from rp_private.lan_print_jobs where cafe_id=c order by created_at desc limit 12) j),'[]'));
end $$;
create function public.rp_print_bridge_pair(c uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;t text:=replace(gen_random_uuid()::text,'-','')||replace(gen_random_uuid()::text,'-','');
begin
 m:=rp_private.require_member(c);if m.role<>'owner' then raise exception 'OWNER_REQUIRED' using errcode='42501';end if;
 insert into rp_private.print_bridges(cafe_id,token_hash) values(c,encode(sha256(convert_to(t,'UTF8')),'hex')) on conflict(cafe_id) do update set token_hash=excluded.token_hash,last_seen=null,created_at=clock_timestamp();
 return jsonb_build_object('token',t);
end $$;
create function public.rp_print_test(c uuid,p text,r uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;j uuid;
begin
 m:=rp_private.require_member(c);if m.role<>'owner' then raise exception 'OWNER_REQUIRED' using errcode='42501';end if;
 if r is null or p not in ('kitchen','receipt') then raise exception 'INVALID_PRINT_TEST';end if;
 if not exists(select 1 from rp_private.lan_printers where cafe_id=c and purpose=p and enabled) or not exists(select 1 from rp_private.print_bridges where cafe_id=c) then raise exception 'PRINTER_NOT_CONNECTED';end if;
 insert into rp_private.lan_print_jobs(cafe_id,request_id,purpose,is_test,payload) values(c,r,p,true,jsonb_build_object('title','ТЕСТ ПЕЧАТИ — НЕ ЗАКАЗ','destination',case when p='kitchen' then 'КУХНЯ' else 'БАР' end,'lines',jsonb_build_array('ТЕСТ ПЕЧАТИ — НЕ ЗАКАЗ','Проверка подключения. Ничего готовить не нужно.'))) on conflict(cafe_id,request_id,purpose) do nothing;
 select id into j from rp_private.lan_print_jobs where cafe_id=c and request_id=r and purpose=p;
 return jsonb_build_object('ok',true,'job_id',j,'state','pending');
end $$;
create function public.rp_lan_print_receipt(c uuid,b uuid,r uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;bill public.rp_bills;payload jsonb;j uuid;
begin
 m:=rp_private.require_member(c);if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED';end if;
 select * into bill from public.rp_bills where cafe_id=c and id=b;
 if not found then raise exception 'BILL_NOT_FOUND';end if;
 if m.role='waiter' and exists(select 1 from public.rp_orders where cafe_id=c and bill_id=b and waiter_id<>auth.uid()) then raise exception 'BILL_NOT_ASSIGNED';end if;
 if not exists(select 1 from rp_private.lan_printers where cafe_id=c and purpose='receipt' and enabled) then return jsonb_build_object('mode','browser');end if;
 if not exists(select 1 from rp_private.print_bridges where cafe_id=c) then raise exception 'PRINTER_NOT_CONNECTED';end if;
 if r is null then raise exception 'REQUEST_REQUIRED';end if;
 if exists(select 1 from rp_private.lan_print_jobs where cafe_id=c and request_id=r and purpose='receipt' and (bill_id is distinct from b or is_test)) then raise exception 'REQUEST_ID_REUSED';end if;
 select jsonb_build_object('title','СЧЁТ / HOA DON','cafe',ca.name,'table',t.label,'currency',bill.currency,'items',coalesce((select jsonb_agg(jsonb_build_object('name',i.name_snapshot,'qty',i.quantity,'price',i.unit_price_minor,'note',i.note,'key',mi.external_key) order by o.created_at,i.id) from public.rp_orders o join public.rp_order_items i on i.order_id=o.id and i.cafe_id=o.cafe_id left join public.rp_menu_items mi on mi.cafe_id=i.cafe_id and mi.id=i.menu_item_id where o.cafe_id=c and o.bill_id=b and o.status<>'cancelled' and i.cancelled_at is null),'[]')) into payload from public.rp_cafes ca join public.rp_tables t on t.cafe_id=ca.id and t.id=bill.table_id where ca.id=c;
 insert into rp_private.lan_print_jobs(cafe_id,request_id,purpose,bill_id,payload) values(c,r,'receipt',b,payload) on conflict(cafe_id,request_id,purpose) do nothing;
 select id into j from rp_private.lan_print_jobs where cafe_id=c and request_id=r and purpose='receipt';
 return jsonb_build_object('mode','bridge','job_id',j,'state','pending');
end $$;
create function rp_private.lan_enqueue_kitchen() returns trigger language plpgsql security definer set search_path='' as $$
declare o public.rp_orders;payload jsonb;
begin
 select * into o from public.rp_orders where cafe_id=new.cafe_id and id=new.id;
 if o.sent_at is null or o.status not in ('cooking','ready','served') or not exists(select 1 from rp_private.lan_printers where cafe_id=o.cafe_id and purpose='kitchen' and enabled) then return null;end if;
 select jsonb_build_object('title','КУХНЯ / BEP','order_number',o.number,'table',t.label,'comment',o.comment,'wishes',o.wishes,'items',coalesce((select jsonb_agg(jsonb_build_object('name',i.name_snapshot,'qty',i.quantity,'note',i.note,'key',mi.external_key) order by i.id) from public.rp_order_items i left join public.rp_menu_items mi on mi.cafe_id=i.cafe_id and mi.id=i.menu_item_id where i.cafe_id=o.cafe_id and i.order_id=o.id and i.station='kitchen' and i.cancelled_at is null),'[]')) into payload from public.rp_bills b join public.rp_tables t on t.cafe_id=b.cafe_id and t.id=b.table_id where b.cafe_id=o.cafe_id and b.id=o.bill_id;
 if jsonb_array_length(payload->'items')=0 then return null;end if;
 insert into rp_private.lan_print_jobs(cafe_id,request_id,purpose,order_id,payload) values(o.cafe_id,o.id,'kitchen',o.id,payload) on conflict(cafe_id,request_id,purpose) do nothing;
 return null;
end $$;
create constraint trigger rp_lan_kitchen_insert after insert on public.rp_orders deferrable initially deferred for each row when(new.status='cooking') execute function rp_private.lan_enqueue_kitchen();
create constraint trigger rp_lan_kitchen_send after update of status on public.rp_orders deferrable initially deferred for each row when(old.status is distinct from new.status and new.status='cooking') execute function rp_private.lan_enqueue_kitchen();
create function public.rp_print_bridge_poll(t text) returns jsonb language plpgsql security definer set search_path='' as $$
declare c uuid;l uuid:=gen_random_uuid();result jsonb;
begin
 if t is null or t !~ '^[a-f0-9]{64}$' then raise exception 'BRIDGE_DENIED';end if;
 select b.cafe_id into c from rp_private.print_bridges b join public.rp_cafes ca on ca.id=b.cafe_id and ca.active and ca.archived_at is null where b.token_hash=encode(sha256(convert_to(t,'UTF8')),'hex');if c is null then raise exception 'BRIDGE_DENIED';end if;
 update rp_private.print_bridges set last_seen=clock_timestamp() where cafe_id=c;
 update rp_private.lan_print_jobs set state='uncertain',last_error='Соединение прервалось. Повтор не отправляется автоматически.' where cafe_id=c and state='leased' and lease_until<now();
 with work as(select j.id from rp_private.lan_print_jobs j join rp_private.lan_printers p on p.cafe_id=j.cafe_id and p.purpose=j.purpose and p.enabled where j.cafe_id=c and j.state='pending' order by j.created_at for update of j skip locked limit 2)
 update rp_private.lan_print_jobs j set state='leased',lease=l,lease_until=now()+interval '2 minutes' from work where j.id=work.id;
 select coalesce(jsonb_agg(jsonb_build_object('id',j.id,'lease',j.lease,'is_test',j.is_test,'purpose',j.purpose,'payload',j.payload,'printer',to_jsonb(p)-'cafe_id')),'[]') into result from rp_private.lan_print_jobs j join rp_private.lan_printers p on p.cafe_id=j.cafe_id and p.purpose=j.purpose where j.cafe_id=c and j.lease=l;
 return result;
end $$;
create function public.rp_print_bridge_ack(t text,i uuid,l uuid,s text) returns void language plpgsql security definer set search_path='' as $$
declare c uuid;
begin
 if t is null or t !~ '^[a-f0-9]{64}$' or s not in ('sent','failed','uncertain') then raise exception 'BRIDGE_DENIED';end if;
 select cafe_id into c from rp_private.print_bridges where token_hash=encode(sha256(convert_to(t,'UTF8')),'hex');if c is null then raise exception 'BRIDGE_DENIED';end if;
 update rp_private.lan_print_jobs set state=s,sent_at=case when s='sent' then clock_timestamp() else null end,last_error=case s when 'failed' then 'Не удалось передать данные принтеру.' when 'uncertain' then 'Нет подтверждения передачи. Проверьте принтер перед повторной печатью.' else null end where id=i and cafe_id=c and lease=l and state='leased';
end $$;
revoke all on function rp_private.lan_host(text),rp_private.lan_enqueue_kitchen() from public,anon,authenticated;
revoke all on function public.rp_lan_printers(uuid,jsonb),public.rp_print_bridge_pair(uuid),public.rp_print_test(uuid,text,uuid),public.rp_lan_print_receipt(uuid,uuid,uuid),public.rp_print_bridge_poll(text),public.rp_print_bridge_ack(text,uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.rp_lan_printers(uuid,jsonb),public.rp_print_bridge_pair(uuid),public.rp_print_test(uuid,text,uuid),public.rp_lan_print_receipt(uuid,uuid,uuid) to authenticated;
grant execute on function public.rp_print_bridge_poll(text),public.rp_print_bridge_ack(text,uuid,uuid,text) to anon,authenticated;
commit;
