-- One independent Sun&Sea test QR. It identifies the cafe, never a table.
-- The guest supplies an existing table number when placing an order.
-- Apply in SQL Editor after 20261113000000_chez_test_table_entry.sql.
begin;

alter table rp_private.guest_test_entry
  add column if not exists entry_token_hash text;
create unique index if not exists guest_test_entry_token_hash_unique
  on rp_private.guest_test_entry(entry_token_hash)
  where entry_token_hash is not null;

create or replace function rp_private.guest_test_open(b jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  c uuid;
  t public.rp_tables;
  v rp_private.guest_visits;
  secret text;
  h text;
  bid uuid;
  table_number text;
  entry_token text;
begin
  if b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>512 then
    raise exception 'INVALID_REQUEST';
  end if;
  secret:=b->>'visit_secret';
  table_number:=b->>'table_number';
  entry_token:=b->>'entry_token';
  if secret is null or secret!~'^[a-f0-9]{64}$' or
     table_number is null or table_number!~'^[1-9][0-9]{0,2}$' or
     (entry_token is not null and entry_token!~'^[a-f0-9]{64}$') then
    raise exception 'INVALID_REQUEST';
  end if;

  if entry_token is null then
    -- Preserve the existing Chez Oanh test-number entry unchanged.
    select cafes.id into c
      from public.rp_cafes cafes
      join rp_private.guest_test_entry config on config.cafe_id=cafes.id
      where cafes.slug='chez-oanh-test' and cafes.active and config.enabled
      for update of cafes;
  else
    select cafes.id into c
      from public.rp_cafes cafes
      join rp_private.guest_test_entry config on config.cafe_id=cafes.id
      where cafes.slug='sun-sea' and cafes.active and config.enabled
        and config.entry_token_hash=encode(sha256(convert_to(entry_token,'UTF8')),'hex')
      for update of cafes;
  end if;
  if c is null then raise exception 'TEST_ENTRY_DISABLED';end if;

  select * into t from public.rp_tables
    where cafe_id=c and label=table_number and active;
  if not found then raise exception 'TEST_TABLE_UNAVAILABLE';end if;
  h:=encode(sha256(convert_to(secret,'UTF8')),'hex');
  select * into v from rp_private.guest_visits where token_hash=h;
  if found then
    if v.cafe_id<>c or v.table_id<>t.id then raise exception 'VISIT_UNAVAILABLE';end if;
  else
    if (select count(*) from rp_private.guest_visits
        where table_id=t.id and expires_at>now() and closed_at is null)>=100 then
      raise exception 'RATE_LIMIT';
    end if;
    select id into bid from public.rp_bills
      where cafe_id=c and table_id=t.id and status='open';
    insert into rp_private.guest_visits(cafe_id,table_id,token_hash,bill_id)
      values(c,t.id,h,bid) returning * into v;
  end if;
  if v.closed_at is not null or v.expires_at<=now() or
     (v.bill_id is not null and not exists(
       select 1 from public.rp_bills
       where id=v.bill_id and cafe_id=c and status='open')) then
    raise exception 'VISIT_CLOSED';
  end if;
  return jsonb_build_object(
    'cafe_id',v.cafe_id,'visit_id',v.id,'table',t.label,'expires_at',v.expires_at);
end $$;

commit;
