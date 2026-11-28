-- Multiple independently approved phone owners; existing owners remain untouched.
begin;
alter table rp_private.owner_invites add column if not exists name text not null default '';
do $patch$
declare ddl text;old text;
begin
 ddl:=pg_get_functiondef('rp_private.admin_invite_phone(uuid,uuid,text,text)'::regprocedure);
 old:=$old$if exists(select 1 from public.rp_memberships where cafe_id=c and role='owner' and active) then raise exception 'OWNER_ALREADY_ACTIVE';end if;$old$;
 if position(old in ddl)=0 then raise exception 'PHONE_INVITE_CHANGED';end if;
 ddl:=replace(ddl,old,'');
 old:='where cafe_id=c and accepted_at is null and revoked_at is null';
 if position(old in ddl)=0 then raise exception 'INVITE_REVOKE_CHANGED';end if;
 ddl:=replace(ddl,old,'where cafe_id=c and phone=n and accepted_at is null and revoked_at is null');
 execute ddl;
 ddl:=pg_get_functiondef('rp_private.manual_gateway(text,jsonb)'::regprocedure);
 old:=$old$if exists(select 1 from public.rp_memberships where cafe_id=inv.cafe_id and role='owner' and active) then raise exception 'OWNER_ALREADY_ACTIVE';end if;$old$;
 if position(old in ddl)=0 then raise exception 'OWNER_APPROVAL_CHANGED';end if;
 ddl:=replace(ddl,old,$new$if inv.phone is null and exists(select 1 from public.rp_memberships where cafe_id=inv.cafe_id and role='owner' and active) then raise exception 'OWNER_ALREADY_ACTIVE';end if;$new$);
 old:=$old$values(inv.cafe_id,q.user_id,'owner',split_part(inv.email,'@',1))$old$;
 if position(old in ddl)=0 then raise exception 'OWNER_NAME_CHANGED';end if;
 ddl:=replace(ddl,old,$new$values(inv.cafe_id,q.user_id,'owner',coalesce(nullif(inv.name,''),split_part(inv.email,'@',1)))$new$);
 execute ddl;
end $patch$;
create function public.rp_admin_invite_owner(r uuid,c uuid,p text,token text,n text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb; clean text:=trim(coalesce(n,''));
begin
 perform rp_private.require_admin();
 if length(clean) not between 1 and 100 then raise exception 'INVALID_NAME';end if;
 result:=rp_private.admin_invite_phone(r,c,p,token);
 update rp_private.owner_invites set name=clean where id=(result->>'invite_id')::uuid and accepted_at is null;
 return result;
end $$;
revoke all on function public.rp_admin_invite_owner(uuid,uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.rp_admin_invite_owner(uuid,uuid,text,text,text) to authenticated;
commit;
