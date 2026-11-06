import { createClient } from 'npm:@supabase/supabase-js@2.119.0';

const allowedOrigin = 'https://dellviktoriapro.github.io';
const headers = { 'Access-Control-Allow-Origin': allowedOrigin, 'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Cache-Control': 'no-store', 'Content-Type': 'application/json' };
const reply = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers });
const validToken = (s: unknown) => typeof s === 'string' && /^[a-f0-9]{64}$/.test(s);
const validId = (s: unknown) => typeof s === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(s);

Deno.serve(async req => {
 if (req.method === 'OPTIONS') return new Response(null, {status:204,headers});
 if (req.method !== 'POST') return reply({error:'METHOD_NOT_ALLOWED'},405);
 if (req.headers.get('origin') && req.headers.get('origin') !== allowedOrigin) return reply({error:'ORIGIN_DENIED'},403);
 // Read with a hard cap; no request bodies, passwords or tokens are logged.
 let size=0; const chunks:Uint8Array[]=[];
 for await (const chunk of req.body ?? []) {size+=chunk.length;if(size>8192)return reply({error:'REQUEST_TOO_LARGE'},413);chunks.push(chunk)}
 let b:any;try{const bytes=new Uint8Array(size);let at=0;for(const chunk of chunks){bytes.set(chunk,at);at+=chunk.length}b=JSON.parse(new TextDecoder().decode(bytes))}catch{return reply({error:'INVALID_JSON'},400)}
 const svc = createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
 const rpc=async(a:string,body:unknown)=>{const {data,error}=await svc.rpc('rp_manual_gateway',{a,b:body});if(error)throw Error(error.message);return data};
 try {
  if(b.action==='register'){
   if(!validToken(b.token)||!validId(b.request_id)||typeof b.email!=='string'||b.email.length>254||typeof b.password!=='string'||b.password.length<10||b.password.length>128)return reply({error:'INVALID_REQUEST'},400);
   const reserve=await rpc('reserve',{token:b.token,email:b.email,request_id:b.request_id});
   // Creates an unconfirmed account without sending email. It cannot sign in yet.
   const {data,error}=await svc.auth.admin.createUser({email:reserve.email,password:b.password,email_confirm:false});
   if(error||!data.user){await rpc('failed',{request_id:b.request_id});return reply({error:'ACCOUNT_CREATION_FAILED_USE_NEW_INVITE'},409)}
   const result=await rpc('registered',{request_id:b.request_id,user_id:data.user.id});
   return reply(result);
  }
  if(b.action==='status'){
   if(!validToken(b.token)||!validId(b.request_id))return reply({error:'INVALID_REQUEST'},400);
   return reply(await rpc('status',{token:b.token,request_id:b.request_id}));
  }
  if(b.action==='approve'){
   if(!validId(b.request_id)||typeof b.code!=='string'||!/^[0-9a-f]{8}$/i.test(b.code))return reply({error:'INVALID_REQUEST'},400);
   const jwt=(req.headers.get('Authorization')||'').replace(/^Bearer /,'');
   const {data,error}=await svc.auth.getUser(jwt);
   if(error||!data.user)return reply({error:'AUTH_REQUIRED'},401);
   const args={actor_id:data.user.id,request_id:b.request_id,code:b.code};
   const prepared=await rpc('prepare_approval',args);
   if(prepared.state!=='approved'){
    // Manual account is separately tagged in the private DB: this is admin identity
    // approval, NOT proof of mailbox ownership. Email-only invitations exclude it.
    const {error}=await svc.auth.admin.updateUserById(prepared.user_id,{email_confirm:true});
    if(error)return reply({error:'APPROVAL_RETRY_REQUIRED'},503);
   }
   return reply(await rpc('finish_approval',args));
  }
  return reply({error:'UNKNOWN_ACTION'},400);
 } catch { return reply({error:'REQUEST_DENIED_OR_EXPIRED'},403) }
});
