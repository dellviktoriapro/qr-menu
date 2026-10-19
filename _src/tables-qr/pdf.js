const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:794,height:1123}});
await p.goto('file://'+process.cwd()+'/tables.html');await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(500);
await p.pdf({path:'qr-tables-chez-oanh.pdf',format:'A4',printBackground:true,preferCSSPageSize:true});
await p.screenshot({path:'t1.png'});await b.close()})();
