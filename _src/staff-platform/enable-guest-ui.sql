-- Apply only AFTER staff-access Edge deployment is reviewed and enabled.
-- The existing scoped snapshot gains staff status; no new grants and no secret QR tokens.
begin;
create or replace function rp_private.operational_snapshot(c uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;m public.rp_memberships;
begin
 m:=rp_private.require_member(c);result:=rp_private.snapshot(c);
 return jsonb_set(result,'{cafe}',(result->'cafe')||jsonb_build_object('design',(select design from public.rp_cafes where id=c)))||jsonb_build_object('staff_enabled',true,'guest_enabled',true,
 'pending_staff_count',case when m.role='owner' then (select count(*) from rp_private.staff_invites i join rp_private.staff_requests r on r.invite_id=i.id where i.cafe_id=c and i.accepted_at is null and i.revoked_at is null and i.expires_at>now() and r.state in ('pending','approving')) else 0 end,
 'shifts',coalesce((select jsonb_object_agg(p.user_id::text,p.on_shift) from rp_private.member_profiles p join public.rp_memberships x on x.cafe_id=p.cafe_id and x.user_id=p.user_id and x.active where p.cafe_id=c),'{}'),
 'settings',coalesce((select jsonb_build_object('notify',s.notify,'reviews',s.reviews) from rp_private.cafe_settings s where cafe_id=c),'{"notify":"esc","reviews":{}}'));
end $$;
commit;
