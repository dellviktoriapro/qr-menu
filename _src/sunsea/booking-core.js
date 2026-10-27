/* Pure reservation rules. No customer data is persisted or sent here. */
const BOOKING_CORE=(()=>{
 const tables=BOOKING_LAYOUT.tables;
 function table(id){return tables.find(t=>t.id===Number(id))||null}
 function today(now=Date.now()){const p=new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Ho_Chi_Minh',year:'numeric',month:'2-digit',day:'2-digit'}).formatToParts(new Date(now));const v=k=>p.find(x=>x.type===k).value;return v('year')+'-'+v('month')+'-'+v('day')}
 function validate(v,now=Date.now()){
  const t=table(v.table);if(!t)return 'table';
  const n=Number(v.guests);if(!Number.isSafeInteger(n)||n<1||n>100)return 'guests';if(t.max&&n>t.max)return 'capacity';
  if(!/^\d{4}-\d{2}-\d{2}$/.test(v.date||''))return 'date';
  const day=new Date(v.date+'T00:00:00+07:00');if(!Number.isFinite(+day)||today(+day)!==v.date)return 'date';
  if(!/^([01]\d|2[0-3]):[0-5]\d$/.test(v.time||''))return 'time';
  if(+new Date(v.date+'T'+v.time+':00+07:00')<=now)return 'past';return null;
 }
 function message(v,now=Date.now()){
  const error=validate(v,now);if(error)throw Error(error);const n=Number(v.guests),[y,m,d]=v.date.split('-');const word=n%100>=11&&n%100<=14?'человек':n%10>=1&&n%10<=4?'человека':'человек';
  return `Здравствуйте! Хочу забронировать столик № ${Number(v.table)} в Sun&Sea на ${n} ${word}.\nДата: ${d}.${m}.${y}.\nВремя: ${v.time} (по времени Вьетнама, UTC+7).\nПодтвердите, пожалуйста, возможность бронирования.`;
 }
 function links(contact,text){
  const result={whatsapp:null,telegram:null,zalo:null};if(!contact)return result;
  const digits=String(contact.whatsapp||'').replace(/[+\s()-]/g,'');if(/^[1-9]\d{7,14}$/.test(digits)){const u=new URL('https://wa.me/'+digits);u.searchParams.set('text',text);result.whatsapp=u.href}
  let tg=String(contact.telegram||'').replace(/^@/,'');try{if(tg.startsWith('https://')){const u=new URL(tg);tg=['t.me','telegram.me'].includes(u.hostname)?u.pathname.replace(/^\//,''):''}}catch{tg=''}
  if(/^[a-zA-Z][a-zA-Z0-9_]{4,31}$/.test(tg)||/^\+[1-9]\d{7,14}$/.test(tg)){const u=new URL('https://t.me/'+tg);u.searchParams.set('text',text);result.telegram=u.href}
  const z=String(contact.zalo||'');try{if(!z.startsWith('https://')&&!/^\+?[\d\s()-]{8,24}$/.test(z))return result;const u=new URL(z.startsWith('https://')?z:'https://zalo.me/'+z.replace(/[+\s()-]/g,''));if(u.protocol==='https:'&&u.hostname==='zalo.me'&&u.pathname.length>1&&!u.username&&!u.password)result.zalo=u.href}catch{}
  return result;
 }
 return {table,today,validate,message,links};
})();
