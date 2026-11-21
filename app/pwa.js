(()=>{
 'use strict';
 if('serviceWorker' in navigator)navigator.serviceWorker.register('sw.js',{scope:'./',updateViaCache:'none'}).catch(()=>{});
 let promptEvent=null;
 let toastTimer;
 function installNotice(message){
  let notice=document.getElementById('install-notice');
  if(!notice){notice=document.createElement('div');notice.id='install-notice';notice.setAttribute('role','status');document.body.append(notice)}
  notice.textContent=message;
  notice.hidden=false;
  clearTimeout(toastTimer);
  toastTimer=setTimeout(()=>{notice.hidden=true},5000);
 }
 window.addEventListener('beforeinstallprompt',event=>{
  event.preventDefault();
  promptEvent=event;
  document.getElementById('install-app')?.remove();
  const button=document.createElement('button');
  button.id='install-app';button.type='button';button.className='quiet';
  button.textContent='Установить приложение';
  button.onclick=async()=>{
   if(!promptEvent)return;
   const pending=promptEvent;promptEvent=null;
   await pending.prompt();
   const choice=await pending.userChoice;
   if(choice?.outcome==='accepted')button.remove();
  };
  document.body.append(button);
 });
 window.addEventListener('appinstalled',()=>{
  promptEvent=null;
  document.getElementById('install-app')?.remove();
  installNotice('Приложение установлено');
 });
 window.addEventListener('offline',()=>{
  const status=document.getElementById('operations-status')||document.getElementById('message');
  if(status){status.hidden=false;status.setAttribute('role','alert');status.textContent='Нет интернета. Новые действия не подтверждены. После восстановления связи используйте повторную отправку сохранённого запроса.'}
 });
})();
