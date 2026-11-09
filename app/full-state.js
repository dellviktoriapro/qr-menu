/** Authoritative server snapshot -> original staff UI model. No local/demo business state. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.staffServerState=api})(typeof window==='object'?window:this,()=>{
'use strict';
const ms=x=>x?Date.parse(x):null;
const prefKeys=['lang','theme','sound','wtab','ktab','otab','oper','mineOnly'];
function mapSnapshot(snapshot,previous={}){
 if(!snapshot?.cafe?.id||!snapshot.me?.id)throw Error('INVALID_SERVER_SNAPSHOT');
 const own=previous.cafeId===snapshot.cafe.id;
 const prefs=Object.fromEntries(prefKeys.filter(k=>own&&Object.hasOwn(previous,k)).map(k=>[k,structuredClone(previous[k])]));
 const menu={},stopped={},tableById=Object.fromEntries((snapshot.tables||[]).map(x=>[x.id,x]));
 for(const i of snapshot.menu||[]){menu[i.id]={id:i.id,serverId:i.id,externalKey:i.external_key,vi:i.names?.vi||i.names?.ru||'',ru:i.names?.ru||i.names?.vi||'',en:i.names?.en||i.names?.vi||'',p:i.price_minor,st:i.station==='bar'?'b':'k',active:i.active,ph:i.photo_key||''};if(i.stopped)stopped[i.id]={at:ms(snapshot.server_at),by:'server'}}
 const checks=Object.fromEntries((snapshot.checks||[]).map(x=>[x.id,x]));
 const bills={};
 for(const b of snapshot.bills||[]){const table=tableById[b.table_id];if(!table)throw Error('TABLE_NOT_IN_SNAPSHOT');bills[b.id]={id:b.id,table:table.label,tableId:b.table_id,openedAt:ms(b.opened_at),closed:b.status!=='open',closedAt:ms(b.closed_at),version:b.version,pays:{}}}
 const orders=[];
 for(const o of snapshot.orders||[]){if(o.status==='cancelled')continue;if(!bills[o.bill_id])throw Error('BILL_NOT_IN_SNAPSHOT');
  const check=checks[o.check_id];if(!check||check.bill_id!==o.bill_id)throw Error('CHECK_NOT_IN_SNAPSHOT');
  const items=[];for(const i of o.items||[]){if(i.cancelled_at)continue;
   // A unique historical menu key is essential: two orders may record different prices for the same dish.
   const mid='recorded:'+i.id;
   menu[mid]={id:mid,serverId:i.menu_item_id,vi:i.name_snapshot?.vi||'',ru:i.name_snapshot?.ru||i.name_snapshot?.vi||'',en:i.name_snapshot?.en||i.name_snapshot?.vi||'',p:i.unit_price_minor,st:i.station==='bar'?'b':'k',active:false};
   items.push({id:i.id,mid,station:i.station,qty:i.quantity,note:i.note||'',done:!!i.ready_at,readyAt:ms(i.ready_at),servedAt:ms(i.served_at),servedBy:i.served_by||null});
  }
  const stationReadyAt={},stationServedAt={},stationServedBy={};
  for(const [scope,code] of [['kitchen','k'],['bar','b']]){const rows=items.filter(i=>menu[i.mid].st===code);if(rows.length&&rows.every(i=>i.done))stationReadyAt[scope]=Math.max(...rows.map(i=>i.readyAt));if(rows.length&&rows.every(i=>i.servedAt)){stationServedAt[scope]=Math.max(...rows.map(i=>i.servedAt));stationServedBy[scope]=rows.at(-1).servedBy}}
  orders.push({id:o.id,no:o.number,table:bills[o.bill_id].table,bill:o.bill_id,check:check.label,checkId:o.check_id,items,status:o.status,waiter:o.waiter_id,waiterName:o.waiter_name_snapshot,createdAt:ms(o.created_at),acceptedAt:ms(o.accepted_at),sentAt:ms(o.sent_at),readyAt:ms(o.ready_at),servedAt:ms(o.served_at),stationReadyAt,stationServedAt,stationServedBy,comment:o.comment||'',wishes:o.wishes||[],lang:o.guest_lang||'vi',src:o.source||'waiter',version:o.version,seed:false});
 }
 const staff=(snapshot.staff||[]).map(x=>({id:x.id,name:x.name,phone:x.phone||'',role:x.role,status:x.active?'active':'blocked',tipQr:x.tip_qr||''}));
 const role=['owner','manager'].includes(snapshot.me.role)?'owner':['kitchen','bar'].includes(snapshot.me.role)?'kitchen':'waiter';
 return {state:{v:2,cafeId:snapshot.cafe.id,orders,bills,staff,log:snapshot.staff_log||[],stop:stopped,shift:snapshot.shifts||{},me:snapshot.me.id,role,serverRole:snapshot.me.role,split:false,lang:'ru',theme:'dark',sound:false,wtab:'all',ktab:snapshot.me.role==='bar'?'bar':'all',otab:'stats',oper:{k:'today'},seen:{},notify:snapshot.settings?.notify||'esc',payQr:snapshot.settings?.pay_qr||'',rev:snapshot.settings?.reviews||{},design:snapshot.cafe.design||'atelier',serverAt:ms(snapshot.server_at),...prefs},menu,tables:snapshot.tables||[],capabilities:snapshot.capabilities||{}};
}
function orderCommand(state,action,id,extra={}){
 const o=state.orders.find(o=>o.id===id);if(!o)throw Error('ORDER_NOT_FOUND');
 const body={order_id:o.id,version:o.version};
 if(action==='send')return {a:'send',b:body};
 if(action==='station_ready'||action==='serve'){if(!['kitchen','bar'].includes(extra.station))throw Error('INVALID_STATION');return {a:action,b:{...body,station:extra.station}}}
 if(action==='item_ready'){const item=o.items.find(i=>i.id===extra.item_id);if(!item)throw Error('ITEM_NOT_FOUND');return {a:action,b:{...body,item_id:extra.item_id,station:item.station,ready:!!extra.ready}}}
 throw Error('UNSUPPORTED_ACTION');
}
return {mapSnapshot,orderCommand};
});
