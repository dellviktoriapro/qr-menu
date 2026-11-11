-- Prepared only. Do not apply until a print worker and its failure UI are ready.
-- Transactional outbox: a sent order and its station tickets commit together.
begin;

create table rp_private.print_jobs (
 id uuid primary key default gen_random_uuid(),
 cafe_id uuid not null references public.rp_cafes(id),
 order_id uuid not null,
 station text not null check (station in ('kitchen','bar')),
 payload jsonb not null check (jsonb_typeof(payload) = 'object'),
 state text not null default 'pending' check (state in ('pending','printing','printed','failed')),
 attempts integer not null default 0 check (attempts >= 0),
 lease_until timestamptz,
 printed_at timestamptz,
 last_error text,
 created_at timestamptz not null default now(),
 unique (cafe_id, order_id, station),
 foreign key (cafe_id, order_id) references public.rp_orders(cafe_id, id)
);
create index print_jobs_work on rp_private.print_jobs(state, lease_until, created_at)
 where state in ('pending','printing','failed');
alter table rp_private.print_jobs enable row level security;
revoke all on rp_private.print_jobs from public, anon, authenticated;

create function rp_private.enqueue_print_jobs() returns trigger
language plpgsql security definer set search_path = '' as $$
declare current_order public.rp_orders; station_name text; ticket jsonb;
begin
 -- Deferred trigger sees the final items, including order_edit(send=true).
 select * into current_order from public.rp_orders
 where cafe_id = new.cafe_id and id = new.id;
 if current_order.status <> 'cooking' or current_order.sent_at is null then
  return null;
 end if;
 for station_name in
  select distinct station from public.rp_order_items
  where cafe_id = new.cafe_id and order_id = new.id and cancelled_at is null
 loop
  select jsonb_build_object(
   'order_id', current_order.id,
   'order_number', current_order.number,
   'table', t.label,
   'station', station_name,
   'sent_at', current_order.sent_at,
   'waiter', current_order.waiter_name_snapshot,
   'comment', current_order.comment,
   'wishes', current_order.wishes,
   'items', (select coalesce(jsonb_agg(jsonb_build_object(
      'line_id', i.id, 'name', i.name_snapshot, 'variant', i.variant_snapshot,
      'quantity', i.quantity, 'note', i.note) order by i.id), '[]'::jsonb)
    from public.rp_order_items i
    where i.cafe_id = new.cafe_id and i.order_id = new.id
      and i.station = station_name and i.cancelled_at is null)
  ) into ticket
  from public.rp_bills b
  join public.rp_tables t on t.cafe_id = b.cafe_id and t.id = b.table_id
  where b.cafe_id = new.cafe_id and b.id = current_order.bill_id;
  insert into rp_private.print_jobs(cafe_id, order_id, station, payload)
  values (new.cafe_id, new.id, station_name, ticket)
  on conflict (cafe_id, order_id, station) do nothing;
 end loop;
 return null;
end $$;

create constraint trigger rp_print_after_insert
after insert on public.rp_orders deferrable initially deferred
for each row when (new.status = 'cooking')
execute function rp_private.enqueue_print_jobs();

create constraint trigger rp_print_after_send
after update of status on public.rp_orders deferrable initially deferred
for each row when (old.status is distinct from new.status and new.status = 'cooking')
execute function rp_private.enqueue_print_jobs();

revoke all on function rp_private.enqueue_print_jobs() from public, anon, authenticated;
commit;
