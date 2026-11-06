-- One-shot foundation for empty development project. No client grants.
begin;
create table public.rp_cafes (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{1,62}$'),
  name text not null check (length(name) between 1 and 160),
  timezone text not null default 'Asia/Ho_Chi_Minh',
  currency text not null default 'VND' check (currency ~ '^[A-Z]{3}$'),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.rp_memberships (
  cafe_id uuid not null references public.rp_cafes(id),
  user_id uuid not null references auth.users(id),
  role text not null check (role in ('owner','manager','waiter','kitchen','bar')),
  display_name text not null check (length(display_name) between 1 and 100),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (cafe_id,user_id)
);
create index rp_memberships_user on public.rp_memberships(user_id,cafe_id) where active;
create table public.rp_tables (
  id uuid primary key default gen_random_uuid(),
  cafe_id uuid not null references public.rp_cafes(id),
  label text not null check (length(label) between 1 and 40),
  seats integer not null check (seats between 1 and 100),
  active boolean not null default true,
  unique (cafe_id,id), unique (cafe_id,label)
);
create table public.rp_menu_items (
  id uuid primary key default gen_random_uuid(),
  cafe_id uuid not null references public.rp_cafes(id),
  external_key text not null,
  names jsonb not null check (jsonb_typeof(names)='object'),
  station text not null check (station in ('kitchen','bar')),
  price_minor bigint check (price_minor between 0 and 100000000000),
  active boolean not null default true,
  stopped boolean not null default false,
  unique (cafe_id,id), unique (cafe_id,external_key)
);
create table public.rp_bills (
  id uuid primary key default gen_random_uuid(),
  cafe_id uuid not null references public.rp_cafes(id),
  table_id uuid not null,
  status text not null default 'open' check (status in ('open','closed','void')),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  version bigint not null default 0 check (version>=0),
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  unique (cafe_id,id),
  foreign key (cafe_id,table_id) references public.rp_tables(cafe_id,id),
  check ((status='open' and closed_at is null) or (status<>'open' and closed_at is not null))
);
create unique index rp_bills_one_open_table on public.rp_bills(cafe_id,table_id) where status='open';
create index rp_bills_history on public.rp_bills(cafe_id,opened_at desc);
create table public.rp_checks (
  id uuid primary key default gen_random_uuid(),
  cafe_id uuid not null,
  bill_id uuid not null,
  label text not null check (length(label) between 1 and 80),
  created_at timestamptz not null default now(),
  unique (cafe_id,id), unique (cafe_id,bill_id,id),
  foreign key (cafe_id,bill_id) references public.rp_bills(cafe_id,id)
);
create table public.rp_orders (
  id uuid primary key default gen_random_uuid(),
  cafe_id uuid not null,
  bill_id uuid not null,
  check_id uuid not null,
  waiter_id uuid not null,
  waiter_name_snapshot text not null,
  status text not null default 'accepted' check (status in ('accepted','cooking','ready','served','cancelled')),
  request_id uuid not null,
  version bigint not null default 0 check (version>=0),
  created_at timestamptz not null default now(),
  sent_at timestamptz, ready_at timestamptz, served_at timestamptz,
  unique (cafe_id,id), unique (cafe_id,request_id),
  foreign key (cafe_id,bill_id,check_id) references public.rp_checks(cafe_id,bill_id,id),
  foreign key (cafe_id,waiter_id) references public.rp_memberships(cafe_id,user_id)
);
create index rp_orders_active on public.rp_orders(cafe_id,status,created_at);
create index rp_orders_bill on public.rp_orders(cafe_id,bill_id,check_id);
create table public.rp_order_items (
  id uuid primary key default gen_random_uuid(),
  cafe_id uuid not null,
  order_id uuid not null,
  menu_item_id uuid,
  name_snapshot jsonb not null check (jsonb_typeof(name_snapshot)='object'),
  variant_snapshot text not null default '',
  station text not null check (station in ('kitchen','bar')),
  quantity integer not null check (quantity between 1 and 999),
  unit_price_minor bigint check (unit_price_minor between 0 and 100000000000),
  note text not null default '' check (length(note)<=300),
  ready_at timestamptz,
  cancelled_at timestamptz,
  unique (cafe_id,id),
  foreign key (cafe_id,order_id) references public.rp_orders(cafe_id,id),
  foreign key (cafe_id,menu_item_id) references public.rp_menu_items(cafe_id,id)
);
create index rp_order_items_order on public.rp_order_items(cafe_id,order_id);
create table public.rp_payments (
  id uuid primary key default gen_random_uuid(),
  cafe_id uuid not null,
  bill_id uuid not null,
  check_id uuid not null,
  kind text not null check (kind in ('payment','refund')),
  method text not null check (method in ('cash','card','qr_transfer')),
  amount_minor bigint not null check (amount_minor between 1 and 100000000000000),
  recorded_by uuid not null,
  recorded_at timestamptz not null default now(),
  request_id uuid not null,
  unique (cafe_id,id), unique (cafe_id,request_id),
  foreign key (cafe_id,bill_id,check_id) references public.rp_checks(cafe_id,bill_id,id),
  foreign key (cafe_id,recorded_by) references public.rp_memberships(cafe_id,user_id)
);
create index rp_payments_history on public.rp_payments(cafe_id,recorded_at desc);
create index rp_payments_bill on public.rp_payments(cafe_id,bill_id,check_id);
create table public.rp_order_events (
  id uuid primary key default gen_random_uuid(),
  cafe_id uuid not null,
  order_id uuid not null,
  actor_id uuid not null,
  event_type text not null check (length(event_type) between 1 and 64),
  payload jsonb not null default '{}'::jsonb check (jsonb_typeof(payload)='object'),
  occurred_at timestamptz not null default now(),
  request_id uuid not null,
  unique (cafe_id,id), unique (cafe_id,request_id),
  foreign key (cafe_id,order_id) references public.rp_orders(cafe_id,id),
  foreign key (cafe_id,actor_id) references public.rp_memberships(cafe_id,user_id)
);
create index rp_order_events_order on public.rp_order_events(cafe_id,order_id,occurred_at);

-- No definer helpers, views, grants or client write policies in foundation.
alter table public.rp_memberships enable row level security;
create policy rp_self_membership on public.rp_memberships for select to authenticated
  using (user_id=(select auth.uid()) and active);
do $foundation$
declare table_name text;
begin
  foreach table_name in array array['rp_cafes','rp_tables','rp_menu_items','rp_bills','rp_checks','rp_orders','rp_order_items','rp_payments','rp_order_events'] loop
    execute format('alter table public.%I enable row level security',table_name);
    if table_name in ('rp_payments','rp_order_events') then
      execute format('create policy rp_tenant_read on public.%I for select to authenticated using (exists (select 1 from public.rp_memberships m where m.cafe_id=%I.cafe_id and m.user_id=(select auth.uid()) and m.active and m.role in (''owner'',''manager'')))',table_name,table_name);
    else
      execute format('create policy rp_tenant_read on public.%I for select to authenticated using (exists (select 1 from public.rp_memberships m where m.cafe_id=%I.%I and m.user_id=(select auth.uid()) and m.active))',table_name,table_name,case when table_name='rp_cafes' then 'id' else 'cafe_id' end);
    end if;
  end loop;
  foreach table_name in array array['rp_cafes','rp_memberships','rp_tables','rp_menu_items','rp_bills','rp_checks','rp_orders','rp_order_items','rp_payments','rp_order_events'] loop
    execute format('revoke all on table public.%I from public, anon, authenticated',table_name);
  end loop;
end $foundation$;
comment on table public.rp_payments is 'Staff-recorded tender/refunds; not bank-verified payment confirmations. Append through audited commands only.';
comment on table public.rp_order_items is 'Historical name, station and price snapshots; menu edits must not rewrite order history.';
commit;
select 'FOUNDATION_CREATED_CLOSED' as result, count(*) as protected_tables
from pg_tables where schemaname='public' and tablename like 'rp_%' and rowsecurity;
