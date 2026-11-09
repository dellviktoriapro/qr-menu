/** Receipt-backed guest submission. Integration remains gated until the guest API is enabled. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.guestOutbox=api})(typeof window==='object'?window:this,()=>{
'use strict';
function createGuestOutbox({storage,scope,uuid,transport}){
 if(typeof scope!=='string'||!scope||scope.length>300)throw Error('INVALID_SCOPE');
 const key='rp_guest_pending:'+scope;let flight=null;
 function pending(){const raw=storage.getItem(key);if(raw===null)return null;let r;try{r=JSON.parse(raw)}catch{throw Error('CORRUPT_PENDING_ORDER')}if(r.scope!==scope||!r.request_id||!Array.isArray(r.checks))throw Error('CORRUPT_PENDING_ORDER');return r}
 function prepare(checks,lang){if(!['ru','vi','en','de','zh','ko'].includes(lang))throw Error('INVALID_LANGUAGE');if(pending())throw Error('PENDING_ORDER');if(!Array.isArray(checks)||checks.length<1||checks.length>20)throw Error('INVALID_CHECKS');const labels=new Set();let lines=0;
 for(const c of checks){if(typeof c.label!=='string'||!c.label.trim()||c.label.length>80||labels.has(c.label)||!Array.isArray(c.items)||!c.items.length)throw Error('INVALID_CHECK');labels.add(c.label);for(const i of c.items){if(typeof i.key!=='string'||!i.key||i.key.length>160||!Number.isInteger(i.quantity)||i.quantity<1||i.quantity>99||typeof i.note!=='string'||i.note.length>300)throw Error('INVALID_ITEM');lines++}}
 if(lines>100)throw Error('TOO_MANY_ITEMS');const r={scope,request_id:uuid(),lang,checks:structuredClone(checks)};const json=JSON.stringify(r);if(json.length>60000)throw Error('ORDER_TOO_LARGE');storage.setItem(key,json);return structuredClone(r)}
 function send(){if(flight)return flight;flight=(async()=>{const r=pending();if(!r)throw Error('NO_PENDING_ORDER');if(r.receipt)return r.receipt;const receipt=await transport(structuredClone(r));if(receipt?.ok!==true||receipt.request_id!==r.request_id||!Array.isArray(receipt.order_ids)||receipt.order_ids.length!==r.checks.length||receipt.order_ids.some(x=>typeof x!=='string'||!x)||new Set(receipt.order_ids).size!==receipt.order_ids.length)throw Error('INVALID_RECEIPT');if(pending()?.request_id===r.request_id)storage.setItem(key,JSON.stringify({...r,receipt}));return receipt})().finally(()=>{flight=null});return flight}
 function discardRejected(id,code){if(flight||pending()?.receipt||code!=='ITEM_UNAVAILABLE'||pending()?.request_id!==id)throw Error('UNSAFE_DISCARD');storage.removeItem(key)}
 function acknowledge(id){const r=pending();if(flight||r?.request_id!==id||!r.receipt)throw Error('UNSAFE_ACK');storage.removeItem(key)}
 return {pending,prepare,send,discardRejected,acknowledge};
}
return {createGuestOutbox};
});
