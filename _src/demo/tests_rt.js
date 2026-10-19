const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const errs=[];const c=await b.newContext({locale:'ru-RU',viewport:{width:1440,height:900}});const p=await c.newPage();p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/prev.html');await p.waitForTimeout(300);
// Minh is me. Create table, accept as Minh, then reorder
await p.click('#simBtn');await p.click('#roles [data-role="waiter"]');await p.click('#pb-waiter [data-wt="new"]');
let id=(await p.$$eval('#pb-waiter [data-a="accept"]',bs=>bs.map(b=>b.dataset.id))).pop();await p.click(`#pb-waiter [data-a="accept"][data-id="${id}"]`);
const tbl=await p.evaluate(id=>ST.orders.find(o=>o.id===id).table,id);
// force reorder on that table
await p.evaluate(t=>{mutate(()=>newOrder({table:t,lang:"en",items:[{mid:"b1",qty:1,note:"",done:false}],comment:"",wishes:[],src:"qr"}))},tbl);
const r1=await p.evaluate(()=>{const o=ST.orders[ST.orders.length-1];return [o.round,o.owner,forMe(o)]});
// switch to Lan → should not be able to accept
await p.selectOption('#meSel','lan');await p.click('#pb-waiter [data-wt="new"]');await p.waitForTimeout(200);
const lanSees=await p.evaluate(()=>{const o=ST.orders[ST.orders.length-1];return [forMe(o),!!document.querySelector(`[data-a="accept"][data-id="${o.id}"]`)]});
await p.screenshot({path:'r1.png'});
// fast-forward escalation
await p.evaluate(()=>{const o=ST.orders[ST.orders.length-1];o.createdAt-=41000;save()});await p.waitForTimeout(1500);
const lanAfter=await p.evaluate(()=>{const o=ST.orders[ST.orders.length-1];return [o.reEsc,forMe(o)]});
await p.screenshot({path:'r2.png'});
console.log(r1,lanSees,lanAfter,errs);await b.close()})();
