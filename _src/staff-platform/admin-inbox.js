'use strict';
// Derived only from server invitation state; opening a notification never approves it.
const cafeAdminSignals={
 addedDate(value){const d=new Date(value);return value&&Number.isFinite(d.getTime())?new Intl.DateTimeFormat("ru-RU",{day:"2-digit",month:"2-digit",year:"numeric"}).format(d):"Дата не указана"},
 pending(cafes,now=Date.now()){
  return cafes.flatMap(c=>c.archived_at?[]:(c.invites||[]).filter(i=>i.mode==='manual'&&!i.accepted_at&&!i.revoked_at&&Date.parse(i.expires_at)>now&&['pending','approving'].includes(i.request?.state)).map(i=>({cafe:c,invite:i,request:i.request})));
 },
 metrics(c){const orders=Number(c.stats?.orders||0),amount=Number(c.stats?.order_amount||0);return {orders,amount,average:orders?amount/orders:null,payments:Number(c.stats?.recorded_payments||0)}},
 links(c){const key={'chez-oanh-test':'co','chez-oanh':'co','sun-sea':'ss','sunsea':'ss'}[c.slug];if(!key)return null;const root='https://dellviktoriapro.github.io/qr-menu/';return {menu:root+(key==='co'?'chez-oanh/':'sun-sea/'),app:key==='co'?root+'app/':null}}
};
if(typeof module!=='undefined')module.exports=cafeAdminSignals;
