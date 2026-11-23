-- Connection settings only. Enabling real dispatch requires the printer's API
-- specification and an installed adapter; an endpoint alone is not proof of printing.
begin;
create table rp_private.printer_settings(
 cafe_id uuid primary key references public.rp_cafes(id),
 endpoint text not null default '',api_key text not null default '',
 auto_kitchen boolean not null default false,paper_width integer not null default 80 check(paper_width in (58,80)),
 adapter_ready boolean not null default false,updated_at timestamptz not null default now()
);
alter table rp_private.printer_settings enable row level security;
revoke all on rp_private.printer_settings from public,anon,authenticated;
create function public.rp_printer_settings(c uuid,b jsonb default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;p rp_private.printer_settings;
begin
 m:=rp_private.require_member(c);
 if m.role<>'owner' then raise exception 'OWNER_REQUIRED' using errcode='42501';end if;
 if b is not null then
  if jsonb_typeof(b)<>'object' or octet_length(b::text)>8192 or coalesce(b->>'endpoint','') !~ '^https://[^[:space:]/]+(/[^[:space:]]*)?$' or coalesce((b->>'paper_width')::integer,0) not in (58,80) then raise exception 'INVALID_PRINTER_SETTINGS';end if;
  insert into rp_private.printer_settings(cafe_id,endpoint,api_key,auto_kitchen,paper_width)
  values(c,b->>'endpoint',coalesce(b->>'api_key',''),coalesce((b->>'auto_kitchen')::boolean,false),(b->>'paper_width')::integer)
  on conflict(cafe_id) do update set endpoint=excluded.endpoint,
   api_key=case when coalesce(b->>'api_key','')='' then printer_settings.api_key else excluded.api_key end,
   auto_kitchen=excluded.auto_kitchen,paper_width=excluded.paper_width,
   adapter_ready=case when printer_settings.endpoint=excluded.endpoint and coalesce(b->>'api_key','')='' then printer_settings.adapter_ready else false end,updated_at=clock_timestamp();
 end if;
 select * into p from rp_private.printer_settings where cafe_id=c;
 return jsonb_build_object('endpoint',coalesce(p.endpoint,''),'has_key',coalesce(p.api_key<>'',false),'paper_width',coalesce(p.paper_width,80),'auto_kitchen',coalesce(p.auto_kitchen,false),'adapter_ready',coalesce(p.adapter_ready,false));
end $$;
revoke all on function public.rp_printer_settings(uuid,jsonb) from public,anon,authenticated;
grant execute on function public.rp_printer_settings(uuid,jsonb) to authenticated;
commit;
