-- Public ordering has no table authority. A staff member assigns an active table.
begin;
create table rp_private.web_orders(
 id uuid primary key,cafe_id uuid not null references public.rp_cafes(id),
 channel text not null check(channel in ('online','table')),
 phone text,items jsonb not null,created_at timestamptz not null default now(),
 accepted_at timestamptz,rejected_at timestamptz,order_id uuid,accepted_by uuid
);
alter table rp_private.web_orders enable row level security;
revoke all on rp_private.web_orders from public,anon,authenticated;

create function public.rp_web_menu(slug text) returns jsonb
language sql stable security definer set search_path='' as $$
 select jsonb_build_object('name',c.name,'slug',c.slug,'items',coalesce((select jsonb_agg(jsonb_build_object('id',m.id,'key',m.external_key,'names',m.names,'price',m.price_minor,'station',m.station) order by m.external_key) from public.rp_menu_items m where m.cafe_id=c.id and m.active and not m.stopped and m.price_minor is not null),'[]'))
 from public.rp_cafes c where c.slug=$1 and c.slug='sun-sea' and c.active and c.archived_at is null
$$;

create function public.rp_web_submit(slug text,r uuid,channel text,phone text,items jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare c uuid;normalized text;quote jsonb;line jsonb;item public.rp_menu_items;old rp_private.web_orders;
begin
 if r is null or channel is null or channel not in ('online','table') or jsonb_typeof(items) is distinct from 'array' or jsonb_array_length(items) not between 1 and 100 or octet_length(items::text)>50000 then raise exception 'INVALID_ORDER';end if;
 normalized:=rp_private.normalized_phone(phone);
 select id into c from public.rp_cafes where rp_cafes.slug=rp_web_submit.slug and rp_cafes.slug='sun-sea' and active and archived_at is null for update;
 if not found then raise exception 'CAFE_NOT_FOUND';end if;
 select * into old from rp_private.web_orders where id=r;
 if found then
  if old.cafe_id<>c or old.phone<>normalized or old.channel<>channel or old.items->'request'<>items then raise exception 'REQUEST_ID_REUSED';end if;
  return jsonb_build_object('ok',true,'id',r);
 end if;
 if (select count(*) from rp_private.web_orders w where w.cafe_id=c and w.phone=normalized and w.created_at>now()-interval '15 minutes')>=5 or (select count(*) from rp_private.web_orders w where w.cafe_id=c and w.created_at>now()-interval '1 hour')>=300 then raise exception 'RATE_LIMIT';end if;
 quote:='[]';
 for line in select value from jsonb_array_elements(items) loop
  if coalesce((line->>'quantity')::integer,0) not between 1 and 50 or length(coalesce(line->>'note',''))>300 then raise exception 'INVALID_LINE';end if;
  select * into item from public.rp_menu_items where cafe_id=c and id=(line->>'id')::uuid and active and not stopped and price_minor is not null;
  if not found or item.price_minor is distinct from (line->>'price')::bigint then raise exception 'ITEM_OR_PRICE_CHANGED';end if;
  quote:=quote||jsonb_build_array(jsonb_build_object('id',item.id,'names',item.names,'price',item.price_minor,'quantity',(line->>'quantity')::integer,'note',coalesce(line->>'note','')));
 end loop;
 insert into rp_private.web_orders(id,cafe_id,channel,phone,items) values(r,c,channel,normalized,jsonb_build_object('request',items,'quote',quote));
 return jsonb_build_object('ok',true,'id',r);
end $$;

create function public.rp_web_pending(c uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;
begin
 m:=rp_private.require_member(c);if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',w.id,'created_at',w.created_at,'table','—','channel',w.channel,'phone',w.phone,'lang','ru','checks',jsonb_build_array(jsonb_build_object('id',w.id,'label','Общий счёт','items',w.items->'quote')))) from rp_private.web_orders w where w.cafe_id=c and w.accepted_at is null and w.rejected_at is null),'[]');
end $$;

create function public.rp_web_accept(c uuid,r uuid,table_label text,reject boolean default false) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;w rp_private.web_orders;result jsonb;lines jsonb;
begin
 perform 1 from public.rp_cafes where id=c for update;
 m:=rp_private.require_member(c);if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 select * into w from rp_private.web_orders where cafe_id=c and id=r for update;
 if not found then raise exception 'ORDER_NOT_FOUND';end if;
 if w.accepted_at is not null then
  if w.accepted_by<>auth.uid() then raise exception 'ORDER_ALREADY_ACCEPTED';end if;
  return jsonb_build_object('ok',true,'order_id',w.order_id);
 end if;
 if w.rejected_at is not null then raise exception 'ORDER_REJECTED';end if;
 if reject then update rp_private.web_orders set rejected_at=clock_timestamp(),accepted_by=auth.uid() where id=r;return jsonb_build_object('ok',true);end if;
 if not exists(select 1 from public.rp_tables where cafe_id=c and label=table_label and active) then raise exception 'TABLE_NOT_FOUND';end if;
 if exists(select 1 from jsonb_array_elements(w.items->'quote') x left join public.rp_menu_items i on i.id=(x->>'id')::uuid and i.cafe_id=c where i.id is null or not i.active or i.stopped or i.price_minor is distinct from (x->>'price')::bigint) then raise exception 'ITEM_OR_PRICE_CHANGED';end if;
 select jsonb_agg(jsonb_build_object('id',x->>'id','quantity',x->'quantity','note',x->>'note')) into lines from jsonb_array_elements(w.items->'quote') x;
 result:=rp_private.command(c,r,'order_create',jsonb_build_object('table',table_label,'check','Общий счёт','lang','ru','items',lines,'send',true));
 update public.rp_orders set comment=(case when w.channel='online' then 'ОНЛАЙН ЗАКАЗ' else 'ЗАКАЗ ПО QR' end)||' · '||w.phone where cafe_id=c and id=(result->>'order_id')::uuid;
 update rp_private.web_orders set accepted_at=clock_timestamp(),accepted_by=auth.uid(),order_id=(result->>'order_id')::uuid where id=r;
 return result;
end $$;
revoke all on function public.rp_web_menu(text),public.rp_web_submit(text,uuid,text,text,jsonb),public.rp_web_pending(uuid),public.rp_web_accept(uuid,uuid,text,boolean) from public,anon,authenticated;
grant execute on function public.rp_web_menu(text),public.rp_web_submit(text,uuid,text,text,jsonb) to anon,authenticated;
grant execute on function public.rp_web_pending(uuid),public.rp_web_accept(uuid,uuid,text,boolean) to authenticated;
commit;
