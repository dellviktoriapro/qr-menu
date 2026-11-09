const assert=require('node:assert/strict'),core=require('./operations-core.js');
const o={status:'cooking',items:[{quantity:2,unit_price_minor:80000,station:'kitchen',name_snapshot:{ru:'Пашот'}},{quantity:2,unit_price_minor:40000,station:'bar',ready_at:'now'}]};
assert.equal(core.total(o),240000);assert.deepEqual(core.station(o,'bar'),{present:true,ready:true,served:false});assert.equal(core.station(o,'kitchen').ready,false);assert.equal(core.hasPending(o),true);o.items[1].served_at='now';assert.equal(core.hasPending(o),false);o.items[0].ready_at='now';assert.equal(core.hasPending(o),true);assert.equal(core.name(o.items[0]),'Пашот');o.items.push({quantity:5,unit_price_minor:100000,cancelled_at:'now',station:'bar'});assert.equal(core.total(o),240000);assert.equal(core.station({items:[]},'bar').ready,false);assert.match(core.error({message:'VERSION_CONFLICT'}),/другом устройстве/);console.log('PASS: totals, cancelled exclusion, independent readiness/service, empty stations, version message');

assert.equal(core.definitive({code:20,message:'AbortError'}),false);
assert.equal(core.definitive({code:'PGRST000'}),false);
assert.equal(core.definitive({code:'40P01'}),false);
assert.equal(core.definitive({code:'P0001',message:'ITEM_UNAVAILABLE'}),true);
assert.equal(core.definitive({code:'40001',message:'VERSION_CONFLICT'}),true);
assert.match(core.error({message:'AbortError: signal aborted'}),/Нет подтверждения/);

assert.equal(core.viewAllowed('kitchen','workbench'),false);
assert.equal(core.viewAllowed('waiter','prep'),false);
assert.equal(core.viewAllowed('waiter','report'),false);
assert.equal(core.viewAllowed('owner','workbench'),true);
assert.equal(core.viewAllowed('bar','menu'),true);

assert.equal(core.personalControls({me:{id:'w',role:'waiter'},shifts:{w:false}},'ru',false).shiftLabel,'Открыть смену');
assert.equal(core.personalControls({me:{id:'w',role:'waiter'},shifts:{w:true}},'ru',true).shiftLabel,'Завершить смену');
assert.equal(core.personalControls({me:{id:'w',role:'waiter'},shifts:{}},'ru',false).qrAttention,true);
assert.equal(core.personalControls({me:{id:'w',role:'waiter'},shifts:{}},'ru',true).qrAttention,false);
assert.equal(core.personalControls({me:{id:'b',role:'bar'},shifts:{}},'ru',false).visible,false);
