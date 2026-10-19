const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const errs=[];
for(const skin of ['light','dark']){const c=await b.newContext({locale:'ru-RU',viewport:{width:1400,height:800}});const p=await c.newPage();p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/prev.html');await p.waitForTimeout(300);
await p.evaluate(s=>{ST.theme=s;ST.split=true;
 for(const t of [1,2,4,6]){const o=newOrder({table:t,lang:"en",items:[{mid:"b1",qty:1,note:"",done:false},{mid:"k2",qty:1,note:"",done:false}],comment:"",wishes:[],src:"qr"});o.status="cooking";o.waiter="minh";o.acceptedAt=Date.now();o.sentAt=Date.now()-(t===4?20*60e3:60e3)}
 save();render()},skin);await p.waitForTimeout(2500);
await p.evaluate(()=>window.scrollTo(0,0));await p.screenshot({path:`kc_${skin}.png`});await c.close()}
console.log(errs);await b.close()})();
