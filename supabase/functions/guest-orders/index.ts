import {createClient} from 'npm:@supabase/supabase-js@2.119.0';
const origin='https://dellviktoriapro.github.io';
const headers={'Access-Control-Allow-Origin':origin,'Access-Control-Allow-Headers':'apikey,content-type','Access-Control-Allow-Methods':'POST,OPTIONS','Content-Type':'application/json','Cache-Control':'no-store'};
const reply=(b:unknown,s=200)=>new Response(JSON.stringify(b),{status:s,headers});
const cap=(x:unknown)=>typeof x==='string'&&/^[a-f0-9]{64}$/.test(x);
const uuid=(x:unknown)=>typeof x==='string'&&/^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i.test(x);
Deno.serve(async req=>{
 if(req.headers.get('origin')&&req.headers.get('origin')!==origin)return reply({error:'ORIGIN_DENIED'},403);
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});if(req.method!=='POST')return reply({error:'METHOD_NOT_ALLOWED'},405);
 let size=0;const chunks:Uint8Array[]=[];for await(const chunk of req.body??[]){size+=chunk.length;if(size>65000)return reply({error:'TOO_LARGE'},413);chunks.push(chunk)}
 let b:any;try{const bytes=new Uint8Array(size);let off=0;for(const c of chunks){bytes.set(c,off);off+=c.length}b=JSON.parse(new TextDecoder().decode(bytes));if(!b||typeof b!=='object'||Array.isArray(b))throw Error()}catch{return reply({error:'INVALID_JSON'},400)}
 if(!['open','submit','status'].includes(b.action)||!cap(b.visit_secret))return reply({error:'INVALID_REQUEST'},400);
 if(b.action==='open'&&!cap(b.table_token)||b.action!=='open'&&!uuid(b.request_id))return reply({error:'INVALID_REQUEST'},400);
 if(b.action==='submit'&&(!b.order||typeof b.order!=='object'||Array.isArray(b.order)))return reply({error:'INVALID_REQUEST'},400);
 // Guest never selects a cafe, table ID, price, station or authenticated actor.
 const payload=b.action==='open'?{visit_secret:b.visit_secret,table_token:b.table_token}:{visit_secret:b.visit_secret,request_id:b.request_id,...(b.action==='submit'?{order:b.order}:{})};
 try{const svc=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});const {data,error}=await svc.rpc('rp_guest_transport',{a:b.action,b:payload});if(error){if(!error.code||error.code==='PGRST000')return reply({error:'SERVER_RETRY_REQUIRED'},503);const known=['VISIT_CLOSED','VISIT_UNAVAILABLE','TABLE_UNAVAILABLE','REQUEST_UNAVAILABLE','REQUEST_ID_REUSED','ITEM_UNAVAILABLE','RATE_LIMIT','INVALID_CHECKS','INVALID_CHECK','INVALID_ITEM'];return reply({error:known.includes(error.message)?error.message:'REQUEST_DENIED'},error.message==='RATE_LIMIT'?429:403)}return reply(data)}catch{return reply({error:'SERVER_RETRY_REQUIRED'},503)}
});
