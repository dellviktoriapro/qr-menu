const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const file=require('path').join(__dirname,'../ops/tpl.html'),s=fs.readFileSync(file,'utf8');
const block=s.slice(s.indexOf('function served('),s.indexOf('function simulate('));
const item=mid=>({mid,qty:1,done:false});
let o={id:'mixed',status:'cooking',sentAt:10,items:[item('food'),item('drink')]};
const ctx={ST:{orders:[o],ktab:'all',stop:{}},M:{food:{st:'k'},drink:{st:'b'}},mutate:fn=>fn(),Date};vm.createContext(ctx);vm.runInContext(block,ctx);
ctx.kReady('mixed','bar');assert.equal(o.status,'cooking','Bar completion must not finish the whole order');assert.equal(o.items[0].done,false,'Kitchen item must remain cooking');assert.equal(o.items[1].done,true);assert.equal(o.readyAt,undefined);
ctx.kReady('mixed','kitchen');assert.equal(o.status,'ready');assert(o.readyAt);assert(o.items.every(i=>i.done));const readyAt=o.readyAt;ctx.kReady('mixed','bar');assert.equal(o.readyAt,readyAt);
o={id:'mixed',status:'cooking',items:[item('food'),item('drink')]};ctx.ST.orders=[o];ctx.kReady('mixed','kitchen');assert.equal(o.status,'cooking');assert.equal(o.items[1].done,false);ctx.kReady('mixed','bar');assert.equal(o.status,'ready');
o={id:'mixed',status:'cooking',items:[item('drink')]};ctx.ST.orders=[o];ctx.kReady('mixed','bar');assert.equal(o.status,'ready');
o={id:'mixed',status:'cooking',items:[item('food'),item('drink')]};ctx.ST.orders=[o];ctx.kReady('mixed','all');assert(o.items.every(i=>!i.done));ctx.kItem('mixed',0);assert.equal(o.status,'cooking');ctx.kItem('mixed',1);assert.equal(o.status,'ready');
o={id:'mixed',status:'new',items:[item('food')]};ctx.ST.orders=[o];ctx.kItem('mixed',0);assert.equal(o.items[0].done,false);
ctx.served('mixed');assert.equal(o.status,'new','Cannot serve an unfinished order');
// Render real station tabs with an isolated DOM stub; ready bar and cooking kitchen must separate.
o={id:'mixed',no:1,table:5,status:'cooking',sentAt:10,waiter:'a',items:[item('food'),{...item('drink'),done:true}],stationReadyAt:{b:20}};ctx.ST.orders=[o];
Object.assign(ctx,{live:()=>[o],t:x=>x,esc:String,nm:mid=>mid,wname:x=>x,mmss:()=>'',since:()=>'',prepSummary:ctx.prepSummary});
assert(!ctx.readyBanner(o).includes('data-a="served"'),'Partial alert cannot serve the whole order');o.status='ready';assert(ctx.readyBanner(o).includes('data-a="served"'));o.status='cooking';
vm.runInContext(s.slice(s.indexOf('function rKitchen('),s.indexOf('/* --- owner --- */')),ctx);
const el={innerHTML:'',querySelectorAll:()=>[]};ctx.ST.ktab='bar';ctx.rKitchen(el);assert(!el.innerHTML.includes('data-kr='),'Ready bar cannot offer completion again');assert(el.innerHTML.includes('class="kc ready"'));ctx.ST.ktab='kitchen';ctx.rKitchen(el);assert(el.innerHTML.includes('data-kr="mixed"'));assert(el.innerHTML.includes('data-station="kitchen"'));ctx.ST.ktab='all';ctx.rKitchen(el);assert(el.innerHTML.includes('data-station="kitchen"'));assert(!el.innerHTML.includes('data-station="bar"'));
// Partial readiness emits a station-specific notification, never the whole-order message.
const notices=[];Object.assign(ctx,{readyTargets:()=>['me'],showsForMe:()=>true,toast:(title)=>notices.push(title),beep:()=>{}});
ctx.ST.me='me';ctx.ST.shift={me:true};ctx.ST.role='waiter';ctx.ST.bills={};ctx.ST.staff=[];
vm.runInContext(s.slice(s.indexOf('function detectEvents('),s.indexOf('function mutate(')),ctx);
const pending={id:'mixed',status:'cooking',items:[item('food'),item('drink')]};o=structuredClone(pending);o.items[1].done=true;ctx.ST.orders=[o];ctx.detectEvents({orders:[pending],staff:[],bills:{}});assert.equal(notices.length,1);assert(notices[0].includes('kBar'));assert(!notices[0].includes('readyAlert'));
const partial=structuredClone(o);o.items[0].done=true;o.status='ready';notices.length=0;ctx.detectEvents({orders:[partial],staff:[],bills:{}});assert.equal(notices.length,1);assert(notices[0].includes('readyAlert'));
console.log('PASS independent bar/kitchen completion, reverse sequence, single station, idempotency, item checks, invalid-scope guards, station rendering and partial/full notifications.');
