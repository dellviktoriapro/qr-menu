'use strict';
const manualOwner=(()=>{
 const endpoint='https://vppgtrbewgqigfinknex.supabase.co/functions/v1/manual-owner';
 const hash=new URLSearchParams(location.hash.slice(1));
 if(hash.get('invite')&&hash.get('invite')!==sessionStorage.getItem('owner_invite')){sessionStorage.removeItem('owner_request_id');sessionStorage.removeItem('owner_invite_mode')}if(hash.get('invite')&&hash.get('mode')!=='manual')sessionStorage.removeItem('owner_invite_mode');
 if(hash.get('mode')==='manual'&&/^[a-f0-9]{64}$/.test(hash.get('invite')||''))sessionStorage.setItem('owner_invite_mode','manual');
 const mode=()=>sessionStorage.getItem('owner_invite_mode')==='manual';
 async function call(body){const {data}=await client.auth.getSession();const headers={'Content-Type':'application/json','apikey':'sb_publishable_02aoSyGU3H5SXUbsqwzeow_TyaxYKtq'};if(body.action==='approve'&&data.session)headers.Authorization='Bearer '+data.session.access_token;const response=await fetch(endpoint,{method:'POST',headers,body:JSON.stringify(body)});const result=await response.json();if(!response.ok)throw Error(result.error||'SERVER_ERROR');return result}
 function pending(data){if(data.state==='failed')throw Error('ACCOUNT_CREATION_FAILED_USE_NEW_INVITE');if(data.state==='reserved'){message('Регистрация ещё обрабатывается. Повторите проверку позже.');return}const el=$('email-sent');$('email-sent-title').textContent=data.state==='approved'?'Доступ одобрен':'Заявка отправлена';$('email-sent-description').textContent=data.state==='approved'?'Теперь войдите со своим email и паролем.':'Передайте администратору этот код по вашему знакомому каналу связи. До одобрения доступ к кафе закрыт. Письмо на почту не отправляется.';$('confirmation-address').textContent='Код заявки: '+data.code;el.showModal();message(data.state==='approved'?'Доступ одобрен. Войдите со своим паролем.':'Код заявки: '+data.code+'. Ожидайте одобрения администратора.');}
 async function register(email,password){let requestId=sessionStorage.getItem('owner_request_id');const token=sessionStorage.getItem('owner_invite')||hash.get('invite');if(requestId){const status=await call({action:'status',token,request_id:requestId});pending(status);return}requestId=crypto.randomUUID();sessionStorage.setItem('owner_request_id',requestId);const result=await call({action:'register',token,email,password,request_id:requestId});pending(result)}
 if(mode()){setTimeout(()=>{if(!$('auth').hidden&&!signup)$('mode').click();},0);$('intro').textContent='Подключение владельца с ручным одобрением администратора. Письмо подтверждения не требуется.';message('Задайте пароль и отправьте заявку. Доступ появится после одобрения администратора.');}
 return {mode,call,register};
})();
window.manualOwner=manualOwner;
