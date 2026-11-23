-- Keep the administrator's existing Auth account and password. The phone is
-- only a private login identifier resolved by the Edge Function.
begin;
create table if not exists rp_private.admin_login_phones (
 phone text primary key check (phone ~ '^[+][1-9][0-9]{7,14}$'),
 user_id uuid not null unique references auth.users(id)
);
alter table rp_private.admin_login_phones enable row level security;
revoke all on rp_private.admin_login_phones from public, anon, authenticated;
do $$
declare admin_id uuid;
begin
 select p.user_id into admin_id from rp_private.platform_admins p
 join auth.users u on u.id=p.user_id
 where p.active and lower(u.email)=lower('dell.viktoria.pro@gmail.com')
   and u.email_confirmed_at is not null and u.deleted_at is null;
 if admin_id is null then raise exception 'ADMIN_ACCOUNT_NOT_FOUND'; end if;
 insert into rp_private.admin_login_phones(phone,user_id)
 values('+79377377734',admin_id)
 on conflict(user_id) do update set phone=excluded.phone;
end $$;
create or replace function rp_private.phone_login_alias(p text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare n text; alias text;
begin
 n:=rp_private.normalized_phone(p);
 select lower(u.email) into alias from rp_private.admin_login_phones l
 join rp_private.platform_admins a on a.user_id=l.user_id and a.active
 join auth.users u on u.id=l.user_id and u.email_confirmed_at is not null and u.deleted_at is null
 where l.phone=n;
 if alias is null then
  select l.alias_email into alias from rp_private.login_phones l
  join auth.users u on u.id=l.user_id and u.deleted_at is null
  where l.phone=n and exists(select 1 from public.rp_memberships m
   join public.rp_cafes c on c.id=m.cafe_id
   where m.user_id=l.user_id and m.active and c.active and c.archived_at is null);
 end if;
 if alias is null then alias:='staff.'||substr(md5(n),1,8)||'-'||substr(md5(n),9,4)||'-4'||substr(md5(n),14,3)||'-8'||substr(md5(n),18,3)||'-'||substr(md5(n),21,12)||'@accounts.invalid'; end if;
 return jsonb_build_object('alias',alias);
end $$;
commit;
