-- Link-only employee onboarding: no email delivery; owner code approval remains mandatory.
begin;
create or replace function rp_private.staff_link_gateway(a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare i rp_private.staff_invites;m public.rp_memberships;alias text;
begin
 if a='describe' then
  if coalesce(b->>'token','')!~'^[a-f0-9]{64}$' then raise exception 'INVITE_UNAVAILABLE';end if;
  select * into i from rp_private.staff_invites where token_hash=encode(sha256(convert_to(b->>'token','UTF8')),'hex') and revoked_at is null and expires_at>now();
  if not found or not exists(select 1 from public.rp_cafes where id=i.cafe_id and active) then raise exception 'INVITE_UNAVAILABLE';end if;
  if i.email!~'^staff\.[a-f0-9-]{36}@accounts\.invalid$' then return '{"mode":"email"}';end if;
  return jsonb_build_object('mode','link','name',i.name,'login_id',substring(i.email from 7 for 36),'alias',i.email,'expires_at',i.expires_at);
 end if;
 if a='invite_create' and b->>'mode'='link' then
  perform 1 from public.rp_cafes where id=(b->>'cafe_id')::uuid and active for update;
  select * into m from public.rp_memberships where cafe_id=(b->>'cafe_id')::uuid and user_id=(b->>'actor_id')::uuid and active for update;
  if not found or m.role<>'owner' then raise exception 'OWNER_REQUIRED' using errcode='42501';end if;
  if b->>'request_id' is null then raise exception 'INVALID_REQUEST';end if;
  alias:='staff.'||(b->>'request_id')::uuid::text||'@accounts.invalid';
  if b->>'replace_id' is not null then update rp_private.staff_invites set revoked_at=coalesce(revoked_at,now()) where cafe_id=m.cafe_id and id=(b->>'replace_id')::uuid and accepted_at is null;end if;
  return rp_private.staff_gateway(a,b||jsonb_build_object('email',alias));
 end if;
 return rp_private.staff_gateway(a,b);
end $$;
revoke all on function rp_private.staff_link_gateway(text,jsonb) from public,anon,authenticated;
commit;
