import {createClient} from 'npm:@supabase/supabase-js@2.119.0';
import webpush from 'npm:web-push@3.6.7';

const titles:Record<string,string>={new:'Новый заказ',online:'Новый онлайн заказ',overdue:'Заказ не приняли',test:'Тест уведомлений — НЕ ЗАКАЗ'};
const endpointAllowed=(s:string)=>{try{const u=new URL(s);return u.protocol==='https:'&&!u.username&&!u.password&&(!u.port||u.port==='443')&&/^(fcm\.googleapis\.com|updates\.push\.services\.mozilla\.com|web\.push\.apple\.com|[a-z0-9.-]+\.notify\.windows\.com)$/.test(u.hostname)}catch{return false}};
const cors={'Access-Control-Allow-Origin':'https://dellviktoriapro.github.io','Access-Control-Allow-Headers':'authorization,apikey,content-type','Access-Control-Allow-Methods':'POST, OPTIONS'};
Deno.serve(async req=>{
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers:cors});
 if(req.method!=='POST')return new Response('Method not allowed',{status:405});
 const key=req.headers.get('X-Worker-Key');
 const svc=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
 const rpc=async(name:string,args={})=>{const {data,error}=await svc.rpc(name,args);if(error)throw Error('Database operation failed');return data};
 try{
  if(!key){
   const jwt=(req.headers.get('Authorization')||'').replace(/^Bearer /,'');if(!jwt)return new Response('Denied',{status:403,headers:cors});
   const {data,error}=await svc.auth.getUser(jwt);if(error||!data.user)return new Response('Denied',{status:403,headers:cors});
   const keys=webpush.generateVAPIDKeys(),secret=Array.from(crypto.getRandomValues(new Uint8Array(32)),x=>x.toString(16).padStart(2,'0')).join('');
   const initialized=await rpc('rp_push_initialize',{actor:data.user.id,pub:keys.publicKey,priv:keys.privateKey,secret});
   return Response.json(initialized,{headers:cors});
  }
  if(key.length!==64)return new Response('Denied',{status:403});
  const cfg=await rpc('rp_push_worker_config');if(!cfg?.enabled)return new Response('Disabled',{status:503});
  // Compare all characters, without logging either key.
  let mismatch=key.length^cfg.dispatch_token.length;for(let n=0;n<64;n++)mismatch|=key.charCodeAt(n)^cfg.dispatch_token.charCodeAt(n);
  if(mismatch)return new Response('Denied',{status:403});
  const jobs=await rpc('rp_push_claim');let sent=0;
  for(let at=0;at<jobs.length;at+=6)await Promise.all(jobs.slice(at,at+6).map(async(j:any)=>{
   let status=400;
   if(endpointAllowed(j.endpoint)&&titles[j.kind])try{
    const payload=JSON.stringify({title:titles[j.kind],body:j.kind==='test'?'Проверка уведомлений. Ничего принимать не нужно.':j.kind==='overdue'?'Прошло 3 минуты. Откройте новые заказы.':'Откройте приложение, чтобы принять заказ.',tag:'order-'+j.event_id,cafe_id:j.cafe_id});
    const details=webpush.generateRequestDetails({endpoint:j.endpoint,keys:j.keys},payload,{TTL:300,urgency:'high',vapidDetails:{subject:'https://dellviktoriapro.github.io/qr-menu/',publicKey:cfg.public_key,privateKey:cfg.private_key}});
    const response=await fetch(details.endpoint,{method:'POST',headers:details.headers,body:details.body,signal:AbortSignal.timeout(10000)});status=response.status;await response.body?.cancel();
   }catch{status=503}
   await rpc('rp_push_ack',{i:j.id,l:j.lease,status});if(status>=200&&status<300)sent++;
  }));
  return Response.json({ok:true,processed:jobs.length,sent});
 }catch{return new Response('Worker unavailable',{status:503,headers:cors})}
});
