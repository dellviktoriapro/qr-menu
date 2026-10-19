const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const errs=[];const c=await b.newContext({locale:'ru-RU',viewport:{width:390,height:844}});
const d=await c.newPage();d.on('pageerror',e=>errs.push('D '+e.message));await d.goto('http://localhost:8765/d/');await d.waitForTimeout(500);await d.click('#roles [data-role="waiter"]');
const m=await c.newPage();m.on('pageerror',e=>errs.push('M '+e.message));
// no table first
await m.goto('http://localhost:8765/m/');await m.waitForTimeout(600);await m.click('#gate button[data-l="ru"]');await m.waitForTimeout(200);
await m.evaluate(()=>document.querySelectorAll('button[data-k][data-d="1"]')[0].click());await m.waitForTimeout(100);
const noT=await m.evaluate(()=>[document.querySelector('#barGo').textContent,!document.querySelector('#billBtn').hidden]);
await m.evaluate(()=>{localStorage.removeItem('co_cart')});
await m.goto('http://localhost:8765/m/?t=7');await m.waitForTimeout(600);
await m.screenshot({path:'/home/claude/demo/n0.png'});
await m.evaluate(()=>{const a=document.querySelectorAll('button[data-k][data-d="1"]');a[1].click()});await m.waitForTimeout(100);
await m.evaluate(()=>{const a=document.querySelectorAll('button[data-k][data-d="1"]');a[a.length-3].click()});await m.waitForTimeout(100);
await m.click('#barBtn');await m.waitForTimeout(200);const btn=await m.textContent('#waiterBtn');
await m.screenshot({path:'/home/claude/demo/n1.png'});
await m.click('#waiterBtn');await m.waitForTimeout(300);await m.screenshot({path:'/home/claude/demo/n2.png'});
await m.click('#doneOk');await m.waitForTimeout(200);
const billVis=await m.evaluate(()=>[!document.querySelector('#billBtn').hidden,document.querySelector('#billT').textContent,document.querySelector('#barBtn').hidden]);
await m.screenshot({path:'/home/claude/demo/n3.png'});
await m.click('#billBtn');await m.waitForTimeout(200);await m.screenshot({path:'/home/claude/demo/n4.png'});
await m.click('[data-pay="qr"]');await m.waitForTimeout(300);
const after=await m.evaluate(()=>document.querySelector('#billT').textContent);
await d.bringToFront();await d.waitForTimeout(3000);
// accept order as Minh so the bill has a waiter
const st=await d.evaluate(()=>{const b=Object.values(ST.bills).find(x=>!x.closed&&x.table===7);return b?{req:b.req,orders:billOrders(b.id).length}:null});
await d.screenshot({path:'/home/claude/demo/n5.png'});
await d.click('[data-wt="tables"]');await d.waitForTimeout(200);await d.screenshot({path:'/home/claude/demo/n6.png'});
console.log(JSON.stringify({noT,btn,billVis,after,st}),errs);await b.close()})();
