const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const errs=[];
for(const skin of ['light','dark']){const c=await b.newContext({locale:'ru-RU',viewport:{width:1000,height:900}});const p=await c.newPage();p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/prev.html');await p.waitForTimeout(300);
await p.evaluate(s=>{ST.theme=s;ST.role="waiter";ST.split=false;save();
 for(let t=1;t<=8;t++){if(!openBill(t))newOrder({table:t,lang:"en",items:[{mid:"b1",qty:1,note:"",done:false}],comment:"",wishes:[],src:"qr"})}ST.wtab="tables";save();render()},skin);
await p.waitForTimeout(300);await p.evaluate(()=>document.querySelector('.tgrid')?.scrollIntoView());await p.screenshot({path:`t8_${skin}.png`});
await c.close()}
console.log(errs);await b.close()})();
