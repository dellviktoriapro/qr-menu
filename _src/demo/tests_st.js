const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const errs=[];
for(const [loc,w] of [['ru-RU',1440],['vi-VN',390]]){
const c=await b.newContext({locale:loc,viewport:{width:w,height:860}});const p=await c.newPage();p.on('pageerror',e=>errs.push(loc+': '+e.message));
await p.goto('file://'+process.cwd()+'/prev.html#join');await p.waitForTimeout(400);
const out={};
out.joinVisible=await p.isVisible('#jName');
await p.click('#jSend');await p.waitForTimeout(200);
out.stillForm=await p.isVisible('#jName');
await p.fill('#jName','Bảo Ngọc');await p.fill('#jPhone','+84 912 345 678');await p.click('#jSend');await p.waitForTimeout(200);
out.pending=await p.isVisible('#jCancel');
await p.screenshot({path:`s1_${w}.png`});
await p.click('#roles [data-role="owner"]');await p.waitForTimeout(150);
await p.click('[data-ot="staff"]');await p.waitForTimeout(200);
out.reqs=await p.$$eval('[data-ok]',x=>x.length);
await p.screenshot({path:`s2_${w}.png`,fullPage:true});
const dev=await p.evaluate(()=>ST.device);
await p.selectOption(`[data-rrole="${dev}"]`,'waiter');await p.click(`[data-ok="${dev}"]`);await p.waitForTimeout(200);
out.status=await p.evaluate(d=>ST.staff.find(s=>s.id===d).status,dev);
// reject phuc
const ph=await p.$$eval('[data-rej]',x=>x.map(y=>y.dataset.rej));if(ph[0]){await p.click(`[data-rej="${ph[0]}"]`)}
await p.click('#roles [data-role="join"]');await p.waitForTimeout(150);
out.ok=await p.isVisible('#jOpen');await p.click('#jOpen');await p.waitForTimeout(200);
out.afterOpen=await p.evaluate(()=>[ST.role,ST.me]);
// block
await p.click('#roles [data-role="owner"]');await p.click('[data-ot="staff"]');await p.click(`[data-blk="${dev}"]`);await p.waitForTimeout(150);
out.blocked=await p.evaluate(d=>ST.staff.find(s=>s.id===d).status,dev);
await p.click('#roles [data-role="waiter"]');await p.waitForTimeout(200);
out.waiterText=(await p.textContent('#pb-waiter')).slice(0,120);
await p.screenshot({path:`s3_${w}.png`});
await p.click('#roles [data-role="owner"]');await p.click('[data-ot="staff"]');
await p.click(`[data-del="${dev}"]`);await p.click(`[data-del="${dev}"]`);await p.waitForTimeout(150);
out.deleted=await p.evaluate(d=>ST.staff.find(s=>s.id===d).status,dev);
const code0=await p.evaluate(()=>ST.joinCode);await p.click('#reissue');out.code=[code0,await p.evaluate(()=>ST.joinCode)];
out.log=await p.$$eval('.jlog li',x=>x.length);
out.overflow=await p.evaluate(()=>document.documentElement.scrollWidth>innerWidth);
await p.screenshot({path:`s4_${w}.png`,fullPage:true});
await p.click('#roles [data-role="waiter"]');await p.waitForTimeout(200);
out.waiterAfterDel=await p.evaluate(()=>ST.me);
console.log(loc,JSON.stringify(out));await c.close()}
console.log('errs',errs);await b.close()})();
