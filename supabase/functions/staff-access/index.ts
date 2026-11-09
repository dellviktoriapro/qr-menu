import {createClient} from 'npm:@supabase/supabase-js@2.119.0';
const origin='https://dellviktoriapro.github.io';
const headers={'Access-Control-Allow-Origin':origin,'Access-Control-Allow-Headers':'authorization,apikey,content-type,x-client-info','Access-Control-Allow-Methods':'POST, OPTIONS','Content-Type':'application/json','Cache-Control':'no-store'};
const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers});
const uuid=(x:unknown)=>typeof x==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(x);
const token=(x:unknown)=>typeof x==='string'&&/^[a-f0-9]{64}$/.test(x);
const commands=new Set(['invite_create','invite_revoke','member_set','reviews','notification','shift','reject','asset_remove']);
Deno.serve(async req=>{
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
 if(req.method!=='POST')return reply({error:'METHOD_NOT_ALLOWED'},405);
 if(req.headers.get('origin')&&req.headers.get('origin')!==origin)return reply({error:'ORIGIN_DENIED'},403);
 let size=0;const chunks:Uint8Array[]=[];for await(const chunk of req.body??[]){size+=chunk.length;if(size>380000)return reply({error:'TOO_LARGE'},413);chunks.push(chunk)}
 let b:any;try{const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length}b=JSON.parse(new TextDecoder().decode(bytes));if(!b||typeof b!=='object'||Array.isArray(b))throw Error()}catch{return reply({error:'INVALID_JSON'},400)}
 const svc=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
 const rpc=async(a:string,p:unknown)=>{const {data,error}=await svc.rpc('rp_staff_gateway',{a,b:p});if(error){const e=new Error(error.message);(e as any).transient=!error.code||error.code==='PGRST000';throw e}return data};
 try{
  if(b.action==='describe'){if(!token(b.token))return reply({error:'INVALID_REQUEST'},400);return reply(await rpc('describe',{token:b.token}))}
  if(b.action==='register'){
   if(!token(b.token)||!uuid(b.request_id)||typeof b.email!=='string'||b.email.length>254||typeof b.password!=='string'||b.password.length<10||b.password.length>128||typeof b.phone!=='string'||b.phone.length>40)return reply({error:'INVALID_REQUEST'},400);
   let reserved;try{reserved=await rpc('reserve',{token:b.token,request_id:b.request_id,email:b.email,phone:b.phone})}catch(e){if((e as any)?.transient)return reply({error:'SERVER_RETRY_REQUIRED'},503);return reply({error:'INVITE_UNAVAILABLE'},403)}
   if(reserved.reuse_user_id)return reply({state:'pending',code:reserved.code,existing_account:true});
   const {data,error}=await svc.auth.admin.createUser({email:reserved.email,password:b.password,email_confirm:false,app_metadata:{staff_request_id:b.request_id}});
   if(error&&(error.status>=500||/fetch|network|timeout/i.test(error.message)))return reply({error:'SERVER_RETRY_REQUIRED'},503);
   if(error||!data.user){await rpc('failed',{request_id:b.request_id});return reply({error:'ACCOUNT_EXISTS_OR_CREATION_FAILED'},409)}
   return reply(await rpc('registered',{request_id:b.request_id,user_id:data.user.id}));
  }
  if(b.action==='status'){
   if(!token(b.token)||!uuid(b.request_id))return reply({error:'INVALID_REQUEST'},400);
   return reply(await rpc('status',{token:b.token,request_id:b.request_id}));
  }
  const jwt=(req.headers.get('Authorization')||'').replace(/^Bearer /,'');
  const {data,error}=await svc.auth.getUser(jwt);if(error||!data.user)return reply({error:error&&(error.status>=500||/fetch|network/i.test(error.message))?'SERVER_RETRY_REQUIRED':'AUTH_REQUIRED'},error&&(error.status>=500||/fetch|network/i.test(error.message))?503:401);
  const actor_id=data.user.id;
  if(b.action==='join_existing'){
   if(!token(b.token)||!uuid(b.request_id)||typeof b.phone!=='string'||b.phone.length>40)return reply({error:'INVALID_REQUEST'},400);
   return reply(await rpc('join_existing',{actor_id,token:b.token,request_id:b.request_id,phone:b.phone}));
  }
  if(!uuid(b.cafe_id))return reply({error:'INVALID_CAFE'},400);
  const auth={actor_id,cafe_id:b.cafe_id};
  if(b.action==='snapshot'){
   const result=await rpc('snapshot',auth);
   const sign=async(path:unknown)=>{if(!path)return '';if(typeof path!=='string'||!path.startsWith(result.cafe_id+'/'))throw Error('INVALID_PATH');const {data,error}=await svc.storage.from('restaurant-qr').createSignedUrl(path,300);if(error)throw Error('QR_UNAVAILABLE');return data.signedUrl};
   result.settings.payment_url=await sign(result.settings.payment_path);
   for(const member of result.members)member.tip_url=await sign(member.tip_path);
   return reply(result);
  }
  if(b.action==='command'){
   if(!commands.has(b.command)||!b.body||typeof b.body!=='object'||Array.isArray(b.body)||!uuid(b.body.request_id))return reply({error:'INVALID_COMMAND'},400);
   const payload={...b.body,...auth}; // Never trust actor/cafe IDs supplied inside body.
   return reply(await rpc(b.command,payload));
  }
  if(b.action==='approve'){
   if(!uuid(b.request_id)||typeof b.code!=='string'||!/^[0-9a-f]{8}$/i.test(b.code)||!['manager','waiter','kitchen','bar'].includes(b.role))return reply({error:'INVALID_REQUEST'},400);
   const payload={...auth,request_id:b.request_id,code:b.code,role:b.role};
   const prepared=await rpc('prepare_approval',payload);
   if(prepared.state!=='approved'){const {error}=await svc.auth.admin.updateUserById(prepared.user_id,{email_confirm:true});if(error)return reply({error:'APPROVAL_RETRY_REQUIRED'},503)}
   return reply(await rpc('finish_approval',payload));
  }
  if(b.action==='upload'){
   if(!uuid(b.request_id)||!uuid(b.commit_id)||!['payment','tip'].includes(b.kind)||typeof b.image!=='string')return reply({error:'INVALID_REQUEST'},400);
   const match=b.image.match(/^data:(image\/(?:jpeg|png|webp));base64,([A-Za-z0-9+/]+={0,2})$/);if(!match)return reply({error:'INVALID_IMAGE'},400);
   const bytes=Uint8Array.from(atob(match[2]),c=>c.charCodeAt(0));if(bytes.length>262144)return reply({error:'TOO_LARGE'},413);
   const valid=match[1]==='image/jpeg'?bytes[0]===255&&bytes[1]===216&&bytes[2]===255:match[1]==='image/png'?bytes[0]===137&&bytes[1]===80&&bytes[2]===78&&bytes[3]===71:new TextDecoder().decode(bytes.slice(0,4))==='RIFF'&&new TextDecoder().decode(bytes.slice(8,12))==='WEBP';if(!valid)return reply({error:'INVALID_IMAGE'},400);
   const digest=await crypto.subtle.digest('SHA-256',bytes),content_hash=Array.from(new Uint8Array(digest),x=>x.toString(16).padStart(2,'0')).join('');
   const prepared=await rpc('asset_prepare',{...auth,request_id:b.request_id,kind:b.kind,content_hash});
   const {error}=await svc.storage.from('restaurant-qr').upload(prepared.path,bytes,{contentType:match[1],upsert:false});if(error&&String(error.statusCode)!=='409')return reply({error:'UPLOAD_RETRY_REQUIRED'},503);
   return reply(await rpc('asset_commit',{...auth,request_id:b.commit_id,upload_id:b.request_id}));
  }
  return reply({error:'UNKNOWN_ACTION'},400);
 }catch(e){const reason=e instanceof Error?e.message:'';if((e as any)?.transient||reason==='QR_UNAVAILABLE')return reply({error:'SERVER_RETRY_REQUIRED'},503);return reply({error:['CODE_MISMATCH','EMAIL_MISMATCH','REQUEST_UNAVAILABLE','INVITE_UNAVAILABLE','ACCOUNT_NOT_READY','REQUEST_ID_REUSED','RATE_LIMIT','OWNER_REQUIRED','ACCESS_DENIED','ROLE_DENIED','QR_UNAVAILABLE'].includes(reason)?reason:'REQUEST_DENIED_OR_EXPIRED'},403)}
});
