'use strict';
// Token belongs only on the cafe LAN computer. No inbound port or router forwarding.
const fs=require('node:fs'),net=require('node:net'),path=require('node:path');const {raster}=require('./receipt.cjs');
const publicKey='sb_publishable_02aoSyGU3H5SXUbsqwzeow_TyaxYKtq',base='https://vppgtrbewgqigfinknex.supabase.co/rest/v1/rpc/';
function localHost(host){if(!/^[0-9]{1,3}(\.[0-9]{1,3}){3}$/.test(String(host)))return false;const p=String(host).split('.').map(Number);return p.length===4&&p.every(n=>Number.isInteger(n)&&n>=0&&n<=255)&&(p[0]===10||p[0]===192&&p[1]===168||p[0]===172&&p[1]>=16&&p[1]<=31)}
async function writePrinter(job,bytes){
 if(!localHost(job.printer.host)||!Number.isInteger(job.printer.port)||job.printer.port<1||job.printer.port>65535)throw Error('INVALID_LAN_TARGET');
 return new Promise(resolve=>{let began=false,settled=false;const finish=s=>{if(settled)return;settled=true;socket.destroy();resolve(s)};const socket=net.createConnection({host:job.printer.host,port:job.printer.port});socket.setTimeout(10000);socket.on('connect',()=>{began=true;socket.end(bytes,()=>finish('sent'))});socket.on('timeout',()=>finish(began?'uncertain':'failed'));socket.on('error',()=>finish(began?'uncertain':'failed'))});
}
async function main(){
 const configPath=path.join(__dirname,'config.json');let config;
 try{config=JSON.parse(fs.readFileSync(configPath,'utf8'))}catch(e){if(e.code!=='ENOENT')throw e;const rl=require('node:readline/promises').createInterface({input:process.stdin,output:process.stdout});const token=(await rl.question('Код подключения из кабинета владельца: ')).trim();rl.close();if(!/^[a-f0-9]{64}$/.test(token))throw Error('Неверный формат кода подключения.');config={token};fs.writeFileSync(configPath,JSON.stringify(config),{mode:0o600})}
 if(!/^[a-f0-9]{64}$/.test(config.token||''))throw Error('Неверный код подключения.');
 const canvas=require('@napi-rs/canvas');
 const rpc=async(name,args)=>{const r=await fetch(base+name,{method:'POST',headers:{apikey:publicKey,'Content-Type':'application/json'},body:JSON.stringify(args),signal:AbortSignal.timeout(15000)});if(!r.ok)throw Error('Сервер недоступен или код подключения отменён.');return r.status===204?null:r.json()};
 console.log('Мост печати запущен. Окно должно оставаться открытым.');
 for(;;){try{const jobs=await rpc('rp_print_bridge_poll',{t:config.token});for(const job of jobs){let state='failed';try{state=await writePrinter(job,raster(job,canvas))}catch{};try{await rpc('rp_print_bridge_ack',{t:config.token,i:job.id,l:job.lease,s:state})}catch{console.error('Нет подтверждения сервера. Автоматический повтор печати запрещён.')}console.log(new Date().toLocaleTimeString(),job.is_test?'ТЕСТ — НЕ ЗАКАЗ':job.purpose==='kitchen'?'КУХНЯ':'ЧЕК',state)}}catch(e){console.error(e.message)}await new Promise(r=>setTimeout(r,3000))}
}
if(require.main===module)main().catch(e=>{console.error(e.message);process.exitCode=1});module.exports={localHost,writePrinter};
