const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const source=fs.readFileSync(__dirname+'/flow-ui.js','utf8');
const tabLine=source.split('\n').find(s=>s.trim().startsWith('const tabs='));
const cardLine=source.split('\n').find(s=>s.trim().startsWith('const closedBillCard='));
assert.ok(tabLine&&cardLine);
const now=Date.now(),old=now-25*3600000;
const orders=[{bill:'one',items:[{qty:1,mid:'a'}]},{bill:'one',items:[{qty:2,mid:'b'}]},{bill:'old',items:[{qty:1,mid:'c'}]}];
const bills={one:{id:'one',table:'1',closed:true,closedAt:now-60000},old:{id:'old',table:'2',closed:true,closedAt:old},open:{id:'open',table:'3',closed:false,closedAt:null}};
const context={ST:{lang:'ru',bills},bills:[],groups:[['new','Новые',[]],['cooking','Готовятся',[]],['ready','Можно выносить',[]]],L:orders,t:()=>'',Date,Math,Object,
 billOrders:id=>orders.filter(o=>o.bill===id),billTotal:id=>orders.filter(o=>o.bill===id).reduce((s,o)=>s+o.items.reduce((v,i)=>v+i.qty*(i.mid==='a'?70000:i.mid==='b'?75000:10000),0),0),
 billChecks:()=>'',aggItems:os=>os.flatMap(o=>o.items),billLine:i=>'<li>'+i.qty+'× '+i.mid+'</li>',vnd:n=>n.toLocaleString('ru-RU')+' ₫',esc:x=>String(x)};
vm.createContext(context);vm.runInContext(tabLine+';this.tabs=tabs',context);
const closed=context.tabs.find(x=>x[0]==='closed');
assert.equal(closed[2].length,1,'two additions on one bill must produce one closed card');
assert.equal(closed[2][0].id,'one');
vm.runInContext(cardLine+';this.closedBillCard=closedBillCard',context);
const html=context.closedBillCard(closed[2][0]);
assert.match(html,/Итоговый счёт/);assert.match(html,/220.000 ₫/);assert.match(html,/1× a/);assert.match(html,/2× b/);
assert.equal((html.match(/data-a="bill"/g)||[]).length,1);
console.log('PASS closed bills: additions grouped into one final bill, 24-hour filter, total and lines');
