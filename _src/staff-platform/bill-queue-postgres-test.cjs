const assert=require('node:assert/strict'),fs=require('node:fs');
const {PGlite}=require(process.env.PGLITE_MODULE||'@electric-sql/pglite');
(async()=>{const db=new PGlite();
await db.exec(`create role anon;create role authenticated;create schema auth;create schema rp_private;
create table auth.users(id uuid primary key,email_confirmed_at timestamptz,deleted_at timestamptz);
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
create table rp_private.platform_admins(user_id uuid,active boolean);
create table public.rp_memberships(cafe_id uuid,user_id uuid,active boolean,role text);
create table public.rp_bills(id uuid primary key,cafe_id uuid,status text,reviewed_at timestamptz,reviewed_by uuid,amount int);
create function rp_private.require_member(c uuid) returns void language plpgsql as $$begin
if not exists(select 1 from public.rp_memberships where cafe_id=c and user_id=auth.uid() and active)
and not exists(select 1 from rp_private.platform_admins where user_id=auth.uid() and active) then raise exception 'NOT_MEMBER';end if;end$$;
create function rp_private.snapshot(c uuid) returns jsonb language sql as $$select jsonb_build_object('can_review_bills',exists(select 1 from public.rp_memberships own where own.cafe_id=c and own.user_id=auth.uid() and own.active and own.role='owner'))$$;`);
await db.exec(fs.readFileSync('supabase/migrations/20261124045602_closed_bill_review_actions.sql','utf8'));
const id=n=>'00000000-0000-4000-8000-'+String(n).padStart(12,'0'),c=id(10),other=id(11),b1=id(20),b2=id(21),open=id(22),foreign=id(23);
for(let n=1;n<=7;n++){await db.query('insert into auth.users values($1,now(),null)',[id(n)]);await db.query('insert into public.rp_memberships values($1,$2,true,$3)',[c,id(n),['owner','manager','waiter','bar','kitchen','waiter','owner'][n-1]])}
await db.query('insert into rp_private.platform_admins values($1,true)',[id(6)]);
await db.query('update public.rp_memberships set active=false where user_id=$1',[id(7)]);
for(const [id,cafe,status]of[[b1,c,'closed'],[b2,c,'closed'],[open,c,'open'],[foreign,other,'closed']])await db.query('insert into public.rp_bills values($1,$2,$3,null,null,100)',[id,cafe,status]);
const actor=n=>db.query("select set_config('request.jwt.claim.sub',$1,false)",[id(n)]);
const act=(ids,a='review')=>db.query('select public.rp_bill_queue_action($1,$2,$3)',[c,ids,a]);
for(const n of[2,3,4,5,7]){await actor(n);for(const a of['review','delete','restore'])await assert.rejects(()=>act([b1],a));assert.equal((await db.query('select rp_private.can_review_bills($1) ok',[c])).rows[0].ok,false)}
await actor(1);await assert.rejects(()=>act([b1,open]));assert.equal((await db.query('select reviewed_at from public.rp_bills where id=$1',[b1])).rows[0].reviewed_at,null);await assert.rejects(()=>act([b1,foreign]));
await act([b1,b2]);await act([b1,b2]);assert.equal((await db.query('select count(*)::int n from public.rp_bills where reviewed_at is not null')).rows[0].n,2);
await actor(6);assert.equal((await db.query('select rp_private.snapshot($1) s',[c])).rows[0].s.can_review_bills,true);await act([b1],'delete');assert.ok((await db.query('select deleted_at from public.rp_bills where id=$1',[b1])).rows[0].deleted_at);await act([b1],'restore');assert.equal((await db.query('select deleted_at from public.rp_bills where id=$1',[b1])).rows[0].deleted_at,null);
assert.equal((await db.query('select sum(amount)::int total from public.rp_bills')).rows[0].total,400);
await db.query('update rp_private.platform_admins set active=false');await assert.rejects(()=>act([b1]));
console.log('PASS Postgres: owner/admin only, inactive/other roles denied, atomic bulk, tenant isolation, reversible deletion, unchanged financial totals');await db.close();})().catch(e=>{console.error(e);process.exitCode=1});
