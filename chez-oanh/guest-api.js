/** Public table capability transport. Not loaded until the reviewed guest rollout. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.guestApi=api})(typeof window==='object'?window:this,()=>{
'use strict';
const endpoint='https://vppgtrbewgqigfinknex.supabase.co/functions/v1/guest-orders',key='sb_publishable_02aoSyGU3H5SXUbsqwzeow_TyaxYKtq';
function create({fetchImpl=fetch,timeout=20000}={}){
 async function call(action,payload){const control=new AbortController(),timer=setTimeout(()=>control.abort(),timeout);try{const response=await fetchImpl(endpoint,{method:'POST',headers:{'Content-Type':'application/json',apikey:key},body:JSON.stringify({action,...payload}),signal:control.signal});const data=await response.json();if(!response.ok){const e=Error(data.error||'SERVER_ERROR');e.status=response.status;throw e}return data}finally{clearTimeout(timer)}}
 return {open:(table_token,visit_secret)=>call('open',{table_token,visit_secret}),submit:(visit_secret,request)=>call('submit',{visit_secret,request_id:request.request_id,order:{lang:request.lang,checks:request.checks}}),status:(visit_secret,request_id)=>call('status',{visit_secret,request_id})};
}
function message(e){const code=String(e?.message||'');if(/VISIT_CLOSED|VISIT_UNAVAILABLE/.test(code))return 'Сессия стола завершена. Отсканируйте QR на столе заново.';if(code==='ITEM_UNAVAILABLE')return 'Одна из позиций закончилась или её цену нужно уточнить. Корзина сохранена.';if(code==='TABLE_UNAVAILABLE')return 'QR стола недействителен. Обратитесь к официанту.';if(code==='RATE_LIMIT')return 'Слишком много запросов. Подождите немного и повторите.';return 'Нет подтверждения сервера. Корзина сохранена. Повторная отправка не создаст дубль.'}
return {create,message};
});
