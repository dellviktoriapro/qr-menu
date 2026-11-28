'use strict';
window.orderPush=(()=>{
 const messages=new Map();
 const supported=()=>isSecureContext&&'serviceWorker'in navigator&&'PushManager'in window&&'Notification'in window;
 const rpc=async(n,args)=>{const {data,error}=await client.rpc(n,args);if(error)throw Error(error.message);return data};
 const decode=s=>Uint8Array.from(atob(s.replace(/-/g,'+').replace(/_/g,'/')+'='.repeat((4-s.length%4)%4)),c=>c.charCodeAt(0));
 async function registration(){await navigator.serviceWorker.register('./sw.js',{scope:'./',updateViaCache:'none'});return navigator.serviceWorker.ready}
 function render(host,cafe){
  const box=document.createElement('section');box.className='card push-settings';box.innerHTML='<h3>Уведомления на телефоне</h3><p>Новый заказ, новый онлайн заказ и напоминание через 3 минуты. Приходят и при заблокированном экране. Официанту — во время открытой смены.</p><button type="button" data-push-enable>Включить на этом устройстве</button><button type="button" data-push-test>Проверить уведомление — НЕ ЗАКАЗ</button><button type="button" data-push-disable>Выключить на этом устройстве</button><p data-push-status role="status" aria-live="polite"></p>';host.prepend(box);
  const status=box.querySelector('[data-push-status]'),enable=box.querySelector('[data-push-enable]'),disable=box.querySelector('[data-push-disable]'),test=box.querySelector('[data-push-test]');const say=text=>{messages.set(cafe.id,text);status.textContent=text},busy=value=>{if(value)box.dataset.busy='true';else delete box.dataset.busy;enable.disabled=disable.disabled=test.disabled=value};
  if(!supported()){enable.disabled=disable.disabled=test.disabled=true;status.textContent='Установите приложение на главный экран и откройте его оттуда. На iPhone требуется iOS 16.4 или новее.';return}
  status.textContent=messages.get(cafe.id)||(Notification.permission==='denied'?'Разрешите уведомления для приложения в настройках телефона.':Notification.permission==='granted'?'Разрешение получено. Для подключения этого кафе нажмите «Включить».':'Телефон запросит разрешение на уведомления.');
  enable.onclick=async()=>{
   // Permission must be requested directly from the tap, before network awaits (iOS).
   if(box.dataset.busy)return;const permission=Notification.requestPermission();busy(true);
   try{if(await permission!=='granted')throw Error('NOTIFICATION_PERMISSION');const cfg=await rpc('rp_push_config',{c:cafe.id});if(!cfg?.enabled)throw Error('PUSH_NOT_ENABLED');const reg=await registration();let sub=await reg.pushManager.getSubscription();if(!sub)sub=await reg.pushManager.subscribe({userVisibleOnly:true,applicationServerKey:decode(cfg.public_key)});await rpc('rp_push_subscribe',{c:cafe.id,s:sub.toJSON()});say('Уведомления включены на этом устройстве.')}catch(e){say(e.message==='NOTIFICATION_PERMISSION'?'Уведомления не разрешены. Включите их в настройках телефона.':e.message==='PUSH_NOT_ENABLED'?'Сервер уведомлений ещё подключается. Повторите позже.':'Не удалось подключить уведомления. Проверьте интернет и повторите.')}finally{busy(false)}
  };
  test.onclick=async()=>{if(box.dataset.busy)return;busy(true);try{const reg=await registration(),sub=await reg.pushManager.getSubscription();if(!sub)throw Error();await rpc('rp_push_test',{c:cafe.id,ep:sub.endpoint});say('Тест отправлен только на это устройство.')}catch{say('Сначала включите уведомления на этом устройстве.')}finally{busy(false)}};
  disable.onclick=async()=>{if(box.dataset.busy)return;busy(true);try{await disableAll();say('Уведомления на этом устройстве выключены.')}catch{say('Не удалось отключить. Повторите при подключённом интернете.')}finally{busy(false)}};
 }
 async function disableAll(){messages.clear();if(!supported())return;const reg=await navigator.serviceWorker.getRegistration('./');const sub=await reg?.pushManager.getSubscription();if(sub){try{await rpc('rp_push_unsubscribe',{ep:sub.endpoint})}finally{await sub.unsubscribe()}}}
 async function initialize(){const {data}=await client.auth.getSession();if(!data.session)throw Error('AUTH_REQUIRED');const r=await fetch('https://vppgtrbewgqigfinknex.supabase.co/functions/v1/order-push',{method:'POST',headers:{'Content-Type':'application/json',apikey:'sb_publishable_02aoSyGU3H5SXUbsqwzeow_TyaxYKtq',Authorization:'Bearer '+data.session.access_token},body:'{}'});if(!r.ok)throw Error('PUSH_SETUP_FAILED');return r.json()}
 return {render,disableAll,initialize};
})();
