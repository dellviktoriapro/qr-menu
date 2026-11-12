-- Platform administrators can enter every active cafe without becoming its owner.
-- The inactive membership is only an FK anchor for existing order/event tables.
begin;

create or replace function rp_private.is_platform_admin(u uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select u is not null and exists(
  select 1 from rp_private.platform_admins p
  join auth.users a on a.id=p.user_id
  where p.user_id=u and p.active and a.email_confirmed_at is not null and a.deleted_at is null
 )
$$;
revoke all on function rp_private.is_platform_admin(uuid) from public,anon,authenticated;
grant execute on function rp_private.is_platform_admin(uuid) to authenticated,service_role;

create or replace function rp_private.require_member(c uuid) returns public.rp_memberships
language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships; admin_access boolean;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED' using errcode='42501'; end if;
 if not exists(select 1 from public.rp_cafes where id=c and active and archived_at is null) then
  raise exception 'ACCESS_DENIED' using errcode='42501';
 end if;
 admin_access:=rp_private.is_platform_admin(auth.uid());
 if admin_access then
  insert into public.rp_memberships(cafe_id,user_id,role,display_name,active)
  values(c,auth.uid(),'manager','Администратор платформы',false)
  on conflict(cafe_id,user_id) do nothing;
  if found then
   insert into rp_private.admin_events(actor_id,action,cafe_id,details)
   values(auth.uid(),'cafe_access',c,'{"source":"platform_admin"}'::jsonb);
  end if;
  select * into m from public.rp_memberships where cafe_id=c and user_id=auth.uid();
  m.role:='owner'; m.active:=true; m.display_name:='Администратор платформы';
  return m;
 end if;
 select * into m from public.rp_memberships where cafe_id=c and user_id=auth.uid() and active for share;
 if not found then raise exception 'ACCESS_DENIED' using errcode='42501'; end if;
 return m;
end $$;

create or replace function rp_private.my_cafes() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED' using errcode='42501'; end if;
 if rp_private.is_platform_admin(auth.uid()) then
  return coalesce((select jsonb_agg(jsonb_build_object(
   'id',c.id,'name',c.name,'role','owner','display_name','Администратор платформы','platform_admin',true
  ) order by c.name) from public.rp_cafes c where c.active and c.archived_at is null),'[]'::jsonb);
 end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',c.id,'name',c.name,'role',m.role,'display_name',m.display_name))
 from public.rp_memberships m join public.rp_cafes c on c.id=m.cafe_id
 where m.user_id=auth.uid() and m.active and c.active and c.archived_at is null),'[]'::jsonb);
end $$;

-- The employee API runs under service_role and receives an actor_id already
-- validated against a Supabase Auth token by the Edge Function.
do $patch$
declare ddl text; old text; replacement text;
begin
 ddl:=pg_get_functiondef('rp_private.staff_gateway(text,jsonb)'::regprocedure);
 old:=$old$select * into m from public.rp_memberships where cafe_id=c and user_id=actor and active;
 if not found or not exists(select 1 from auth.users where id=actor and email_confirmed_at is not null and deleted_at is null) then raise exception 'ACCESS_DENIED' using errcode='42501';end if;$old$;
 replacement:=$new$select * into m from public.rp_memberships where cafe_id=c and user_id=actor and active;
 if rp_private.is_platform_admin(actor) then
  if not found then
   insert into public.rp_memberships(cafe_id,user_id,role,display_name,active)
   values(c,actor,'manager','Администратор платформы',false)
   on conflict(cafe_id,user_id) do nothing;
   select * into m from public.rp_memberships where cafe_id=c and user_id=actor;
  end if;
  m.role:='owner';m.active:=true;m.display_name:='Администратор платформы';
 elsif not found or not exists(select 1 from auth.users where id=actor and email_confirmed_at is not null and deleted_at is null) then
  raise exception 'ACCESS_DENIED' using errcode='42501';
 end if;$new$;
 if position(old in ddl)=0 then raise exception 'staff_gateway authorization changed; migration stopped';end if;
 ddl:=replace(ddl,old,replacement);
 old:=$old$where x.cafe_id=c),'[]')$old$;
 replacement:=$new$where x.cafe_id=c and not exists(select 1 from rp_private.platform_admins pa where pa.user_id=x.user_id)),'[]')$new$;
 if position(old in ddl)=0 then raise exception 'staff_gateway member list changed; migration stopped';end if;
 ddl:=replace(ddl,old,replacement);
 old:=$old$if target=actor$old$;
 replacement:=$new$if exists(select 1 from rp_private.platform_admins pa where pa.user_id=target) then raise exception 'ADMIN_IMMUTABLE' using errcode='42501';end if; if target=actor$new$;
 if position(old in ddl)=0 then raise exception 'staff_gateway member update changed; migration stopped';end if;
 execute replace(ddl,old,replacement);

 ddl:=pg_get_functiondef('rp_private.staff_link_gateway(text,jsonb)'::regprocedure);
 old:=$old$select * into m from public.rp_memberships where cafe_id=(b->>'cafe_id')::uuid and user_id=(b->>'actor_id')::uuid and active for update;
  if not found or m.role<>'owner' then raise exception 'OWNER_REQUIRED' using errcode='42501';end if;$old$;
 replacement:=$new$select * into m from public.rp_memberships where cafe_id=(b->>'cafe_id')::uuid and user_id=(b->>'actor_id')::uuid and active for update;
  if rp_private.is_platform_admin((b->>'actor_id')::uuid) then
   if not found then
    insert into public.rp_memberships(cafe_id,user_id,role,display_name,active)
    values((b->>'cafe_id')::uuid,(b->>'actor_id')::uuid,'manager','Администратор платформы',false)
    on conflict(cafe_id,user_id) do nothing;
    select * into m from public.rp_memberships where cafe_id=(b->>'cafe_id')::uuid and user_id=(b->>'actor_id')::uuid;
   end if;
   m.role:='owner';
  elsif not found or m.role<>'owner' then raise exception 'OWNER_REQUIRED' using errcode='42501';end if;$new$;
 if position(old in ddl)=0 then raise exception 'staff_link_gateway authorization changed; migration stopped';end if;
 execute replace(ddl,old,replacement);
end $patch$;
commit;
