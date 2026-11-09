begin;
-- Link-only employee onboarding: no email delivery; owner code approval remains mandatory.

create function rp_private.staff_link_gateway(a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
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


create function rp_private.edit_recorded_order(c uuid,r uuid,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;o public.rp_orders;rec rp_private.receipts;previous jsonb;x jsonb;oldline jsonb;item public.rp_menu_items;line uuid;result jsonb;ver bigint;used uuid[]:='{}';
begin
 if r is null or b is null or jsonb_typeof(b)<>'object' or octet_length(b::text)>65000 then raise exception 'INVALID_COMMAND';end if;
 perform 1 from public.rp_cafes where id=c for update;m:=rp_private.require_member(c);
 if m.role not in ('owner','manager','waiter') then raise exception 'ROLE_DENIED' using errcode='42501';end if;
 select * into rec from rp_private.receipts where cafe_id=c and request_id=r;if found then if rec.actor_id<>auth.uid() or rec.action<>'order_edit' or rec.body<>b then raise exception 'REQUEST_ID_REUSED';end if;return rec.result;end if;
 select * into o from public.rp_orders where cafe_id=c and id=(b->>'order_id')::uuid for update;if not found then raise exception 'ORDER_NOT_FOUND';end if;
 if m.role='waiter' and o.waiter_id<>auth.uid() then raise exception 'ORDER_NOT_ASSIGNED' using errcode='42501';end if;
 if o.status<>'accepted' then raise exception 'ORDER_ALREADY_SENT';end if;
 if not exists(select 1 from public.rp_bills where cafe_id=c and id=o.bill_id and status='open') then raise exception 'BILL_CLOSED';end if;
 if b->>'version' is null or o.version<>(b->>'version')::bigint then raise exception 'VERSION_CONFLICT' using errcode='40001';end if;
 if jsonb_typeof(b->'items') is distinct from 'array' or jsonb_array_length(b->'items') not between 1 and 100 then raise exception 'INVALID_ITEMS';end if;
 select jsonb_agg(to_jsonb(i)) into previous from public.rp_order_items i where i.cafe_id=c and i.order_id=o.id and i.cancelled_at is null;
 delete from public.rp_order_items where cafe_id=c and order_id=o.id;
 for x in select value from jsonb_array_elements(b->'items') loop
  oldline:=null;if x->>'line_id' is not null then
   select value into oldline from jsonb_array_elements(coalesce(previous,'[]')) where value->>'id'=x->>'line_id';
   if oldline is null or oldline->>'menu_item_id'<>x->>'id' or (x->>'line_id')::uuid=any(used) then raise exception 'INVALID_LINE';end if;used:=array_append(used,(x->>'line_id')::uuid);
  end if;
  if oldline is not null then
   insert into public.rp_order_items(id,cafe_id,order_id,menu_item_id,name_snapshot,station,quantity,unit_price_minor,note) values((oldline->>'id')::uuid,c,o.id,(oldline->>'menu_item_id')::uuid,oldline->'name_snapshot',oldline->>'station',(x->>'quantity')::integer,(oldline->>'unit_price_minor')::bigint,coalesce(x->>'note',''));
  else
   select * into item from public.rp_menu_items where cafe_id=c and id=(x->>'id')::uuid and active and not stopped;if not found or item.price_minor is null then raise exception 'ITEM_UNAVAILABLE';end if;
   insert into public.rp_order_items(cafe_id,order_id,menu_item_id,name_snapshot,station,quantity,unit_price_minor,note) values(c,o.id,item.id,item.names,item.station,(x->>'quantity')::integer,item.price_minor,coalesce(x->>'note',''));
  end if;
 end loop;
 update public.rp_orders set comment=coalesce(b->>'comment',''),wishes=coalesce(b->'wishes','[]'),version=version+1,status=case when coalesce((b->>'send')::boolean,false) then 'cooking' else 'accepted' end,sent_at=case when coalesce((b->>'send')::boolean,false) then now() else null end where id=o.id and cafe_id=c returning version into ver;
 insert into public.rp_order_events(cafe_id,order_id,actor_id,event_type,payload,request_id) values(c,o.id,auth.uid(),'order_edit',b,r);
 result:=jsonb_build_object('ok',true,'request_id',r,'order_id',o.id,'version',ver);insert into rp_private.receipts(cafe_id,request_id,actor_id,action,body,result) values(c,r,auth.uid(),'order_edit',b,result);return result;
end $$;
revoke all on function rp_private.edit_recorded_order(uuid,uuid,jsonb) from public,anon,authenticated;
create or replace function rp_private.operational_command(c uuid,r uuid,a text,b jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.rp_memberships;begin
 perform 1 from public.rp_cafes where id=c for update;m:=rp_private.require_member(c);
 if a='order_edit' then return rp_private.edit_recorded_order(c,r,b);end if;
 if a='design' then return rp_private.set_cafe_design(c,r,b);end if;
 if a='serve' then return rp_private.serve_station(c,r,b);end if;
 if a not in ('order_create','send','station_ready','item_ready','bill_close','stop') or a is null then raise exception 'UNKNOWN_COMMAND';end if;
 if a='item_ready' and coalesce((b->>'ready')::boolean,true)=false and exists(select 1 from public.rp_order_items where cafe_id=c and order_id=(b->>'order_id')::uuid and id=(b->>'item_id')::uuid and served_at is not null) then raise exception 'ITEM_ALREADY_SERVED';end if;
 return rp_private.command(c,r,a,b);
end $$;


create function pg_temp.launch_assert(ok boolean,msg text) returns void language plpgsql as $$begin if ok is distinct from true then raise exception 'TEST: %',msg;end if;end$$;
insert into auth.users(id,email,email_confirmed_at) values('00000000-0000-4000-8000-000000000091','launch-fixture@example.invalid',now());
insert into public.rp_cafes(id,slug,name) values('10000000-0000-4000-8000-000000000091','launch-security-fixture','Launch security fixture');
insert into public.rp_memberships(cafe_id,user_id,role,display_name) values('10000000-0000-4000-8000-000000000091','00000000-0000-4000-8000-000000000091','owner','Fixture owner');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000091',true);
do $$declare c uuid:='10000000-0000-4000-8000-000000000091';owner uuid:='00000000-0000-4000-8000-000000000091';employee uuid:='00000000-0000-4000-8000-000000000092';req uuid:='90000000-0000-4000-8000-000000000091';joinid uuid:='90000000-0000-4000-8000-000000000092';invite jsonb;info jsonb;reserved jsonb;v jsonb;code text;payload jsonb;
begin
 payload:=jsonb_build_object('cafe_id',c,'actor_id',owner,'request_id',req,'mode','link','name','Test waiter');
 invite:=rp_private.staff_link_gateway('invite_create',payload);
 perform pg_temp.launch_assert(length(invite->>'token')=64,'personal high entropy link');
 info:=rp_private.staff_link_gateway('describe',jsonb_build_object('token',invite->>'token'));
 perform pg_temp.launch_assert(info->>'mode'='link' and info->>'login_id'=req::text and info->>'alias'='staff.'||req::text||'@accounts.invalid','no real email needed');
 v:=rp_private.staff_link_gateway('invite_create',payload);perform pg_temp.launch_assert(v->>'reissue_required'='true' and not v?'token','retry does not expose saved plaintext capability');
 reserved:=rp_private.staff_link_gateway('reserve',jsonb_build_object('token',invite->>'token','request_id',joinid,'email',info->>'alias','phone',''));
 perform pg_temp.launch_assert(reserved->>'email'=info->>'alias','link binds private Auth account');
 insert into auth.users(id,email,raw_app_meta_data) values(employee,info->>'alias',jsonb_build_object('staff_request_id',joinid));
 v:=rp_private.staff_link_gateway('registered',jsonb_build_object('request_id',joinid,'user_id',employee));code:=v->>'code';
 perform pg_temp.launch_assert(v->>'state'='pending' and not exists(select 1 from public.rp_memberships where cafe_id=c and user_id=employee),'request never grants access before owner approval');
 begin perform rp_private.staff_link_gateway('prepare_approval',jsonb_build_object('cafe_id',c,'actor_id',owner,'request_id',joinid,'code','BADCODE','role','waiter'));raise exception 'BAD_CODE_ALLOWED';exception when others then if sqlerrm<>'CODE_MISMATCH' then raise;end if;end;
 perform rp_private.staff_link_gateway('prepare_approval',jsonb_build_object('cafe_id',c,'actor_id',owner,'request_id',joinid,'code',code,'role','waiter'));
 update auth.users set email_confirmed_at=now() where id=employee;
 perform rp_private.staff_link_gateway('finish_approval',jsonb_build_object('cafe_id',c,'actor_id',owner,'request_id',joinid,'code',code,'role','waiter'));
 perform pg_temp.launch_assert(exists(select 1 from public.rp_memberships where cafe_id=c and user_id=employee and active and role='waiter'),'owner approval binds exact account and role');
 begin perform rp_private.staff_link_gateway('reserve',jsonb_build_object('token',invite->>'token','request_id',gen_random_uuid(),'email',info->>'alias'));raise exception 'USED_LINK_ALLOWED';exception when others then if sqlerrm<>'INVITE_UNAVAILABLE' then raise;end if;end;
 begin perform rp_private.staff_link_gateway('invite_create',jsonb_build_object('cafe_id',c,'actor_id',employee,'request_id',gen_random_uuid(),'mode','link','name','Forged'));raise exception 'WAITER_INVITE_ALLOWED';exception when insufficient_privilege then null;end;
 perform rp_private.staff_link_gateway('member_set',jsonb_build_object('cafe_id',c,'actor_id',owner,'request_id',gen_random_uuid(),'user_id',employee,'role','waiter','active',false));
 perform set_config('request.jwt.claim.sub',employee::text,true);begin perform rp_private.require_member(c);raise exception 'BLOCKED_STAFF_ALLOWED';exception when insufficient_privilege then null;end;
 perform set_config('request.jwt.claim.sub',owner::text,true);
end $$;
insert into public.rp_tables(id,cafe_id,label,seats) values('20000000-0000-4000-8000-000000000091','10000000-0000-4000-8000-000000000091','3',4);
insert into public.rp_menu_items(id,cafe_id,external_key,names,station,price_minor) values('30000000-0000-4000-8000-000000000091','10000000-0000-4000-8000-000000000091','chez|coffee|0','{"ru":"Original coffee"}','bar',40000);
do $$declare c uuid:='10000000-0000-4000-8000-000000000091';o uuid;line uuid;r uuid:=gen_random_uuid();b jsonb;v jsonb;begin
 v:=rp_private.operational_command(c,gen_random_uuid(),'order_create','{"table":"3","check":"Anna","items":[{"id":"30000000-0000-4000-8000-000000000091","quantity":1}]}');
 o:=(v->>'order_id')::uuid;select id into line from public.rp_order_items where order_id=o;
 update public.rp_menu_items set price_minor=90000,names='{"ru":"Changed coffee"}' where cafe_id=c;
 b:=jsonb_build_object('order_id',o,'version',(select version from public.rp_orders where id=o),'items',jsonb_build_array(jsonb_build_object('id','30000000-0000-4000-8000-000000000091','line_id',line,'quantity',2,'note','No ice')),'comment','Test note','wishes','[]'::jsonb,'send',false);
 v:=rp_private.operational_command(c,r,'order_edit',b);perform pg_temp.launch_assert(v=rp_private.operational_command(c,r,'order_edit',b),'edit retry exact receipt');
 perform pg_temp.launch_assert((select unit_price_minor=40000 and name_snapshot->>'ru'='Original coffee' and quantity=2 and note='No ice' from public.rp_order_items where id=line),'edit preserves recorded price and name while changing quantity and note');
 begin perform rp_private.operational_command(c,gen_random_uuid(),'order_edit',b);raise exception 'STALE_VERSION_ALLOWED';exception when serialization_failure then null;end;
 b:=jsonb_set(b,'{version}',to_jsonb((select version from public.rp_orders where id=o)));b:=jsonb_set(b,'{items,0,line_id}',to_jsonb(gen_random_uuid()));
 begin perform rp_private.operational_command(c,gen_random_uuid(),'order_edit',b);raise exception 'FORGED_LINE_ALLOWED';exception when others then if sqlerrm<>'INVALID_LINE' then raise;end if;end;
 perform pg_temp.launch_assert((select count(*) from public.rp_order_items where order_id=o)=1,'failed edit rolls back deleted draft lines');
end $$;
rollback;
select 'PASS link-only staff: exact account, owner code approval, one-use, role denial, immediate block; editor: historic prices, retry, stale version, line identity and atomic rollback' as result;
