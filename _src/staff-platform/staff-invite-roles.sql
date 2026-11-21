-- Apply once to the existing Supabase project before publishing the role selector.
-- Existing invitations keep their current approval-time role selection.
begin;
alter table rp_private.staff_invites
  add column if not exists assigned_role text
  check (assigned_role in ('manager','waiter','kitchen','bar'));

do $patch$
declare ddl text; old text; replacement text;
begin
 ddl:=pg_get_functiondef('rp_private.staff_gateway(text,jsonb)'::regprocedure);

 old:=$old$'name',i.name,'expires_at'$old$;
 replacement:=$new$'name',i.name,'assigned_role',i.assigned_role,'expires_at'$new$;
 if position(old in ddl)=0 then raise exception 'staff snapshot changed; role migration stopped';end if;
 ddl:=replace(ddl,old,replacement);

 old:=$old$rr:=b->>'role';
  if rr is null$old$;
 replacement:=$new$rr:=b->>'role';
  if inv.assigned_role is not null and rr is distinct from inv.assigned_role then raise exception 'INVITE_ROLE_MISMATCH';end if;
  if rr is null$new$;
 if position(old in ddl)=0 then raise exception 'staff approval changed; role migration stopped';end if;
 ddl:=replace(ddl,old,replacement);

 old:=$old$em:=lower(trim(b->>'email'));
  if em is null$old$;
 replacement:=$new$em:=lower(trim(b->>'email'));
  if b ? 'role' and b->>'role' not in ('manager','waiter','kitchen','bar') then raise exception 'ROLE_DENIED';end if;
  if em is null$new$;
 if position(old in ddl)=0 then raise exception 'staff invite validation changed; role migration stopped';end if;
 ddl:=replace(ddl,old,replacement);

 old:=$old$insert into rp_private.staff_invites(cafe_id,email,name,token_hash,created_by) values(c,em,trim(b->>'name'),encode(sha256(convert_to(token,'UTF8')),'hex'),actor)$old$;
 replacement:=$new$insert into rp_private.staff_invites(cafe_id,email,name,assigned_role,token_hash,created_by) values(c,em,trim(b->>'name'),b->>'role',encode(sha256(convert_to(token,'UTF8')),'hex'),actor)$new$;
 if position(old in ddl)=0 then raise exception 'staff invite insert changed; role migration stopped';end if;
 ddl:=replace(ddl,old,replacement);
 execute ddl;
end $patch$;
commit;
