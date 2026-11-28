'use strict';
// Everyone enters an E.164 phone. The private server resolves it to the
// existing Auth account; the administrator keeps the same account and password.
// Preserve an open session when upgrading from the former tab-only storage.
const authStorageKey='sb-vppgtrbewgqigfinknex-auth-token';
try{if(!localStorage.getItem(authStorageKey)){const previous=sessionStorage.getItem(authStorageKey);if(previous){localStorage.setItem(authStorageKey,previous);sessionStorage.removeItem(authStorageKey)}}}catch{}
const client=window.createRestaurantClient('https://vppgtrbewgqigfinknex.supabase.co','sb_publishable_02aoSyGU3H5SXUbsqwzeow_TyaxYKtq',{auth:{persistSession:true,storage:localStorage,autoRefreshToken:true,detectSessionInUrl:true}});
const $=id=>document.getElementById(id);
let signup=false,busy=false,lastAuthUser=undefined;
const staffLogin=()=>/^[a-f0-9-]{36}$/.test(new URLSearchParams(location.hash.slice(1)).get('staffLogin')||'');
const phoneNumber=value=>String(value||'').replace(/[ ()-]/g,'');
function passwordVisible(show){$('password').type=show?'text':'password';$('password-toggle').setAttribute('aria-pressed',String(show));$('password-toggle').setAttribute('aria-label',show?'Скрыть пароль':'Показать пароль')}
$('password-toggle').addEventListener('click',()=>passwordVisible($('password').type==='password'));
$('email-sent-close').addEventListener('click',()=>$('email-sent').close());
function message(text,failed=false){const el=$('message');el.textContent=text;el.classList.toggle('auth-error',failed);el.setAttribute('role',failed?'alert':'status');el.setAttribute('aria-live',failed?'assertive':'polite');if(failed){el.focus();el.scrollIntoView({block:'nearest'})}}
function lock(value){busy=value;for(const e of document.querySelectorAll('button,input'))e.disabled=value}
function showIdentity(){
 if(window.staffInvite?.active()||staffLogin())return;
 const input=$('email'),label=document.querySelector('label[for=email]');
 input.type='tel';input.autocomplete='tel';input.maxLength=25;
 input.placeholder='+84 90 123 45 67';
 if(label)label.textContent='Номер телефона';
}
window.refreshLoginIdentity=showIdentity;
function errorText(error){
 const s=String(error?.message||'');
 if(/INVALID_PHONE/.test(s))return 'Введите номер в международном формате, например +84901234567.';
 if(error?.code==='invalid_credentials'||/invalid login credentials/i.test(s))return 'Неверный номер или пароль. Проверьте данные и попробуйте ещё раз.';
 if(window.staffInvite?.active())return staffAccess.error(error);
 if(/ACCOUNT_CREATION_FAILED_USE_NEW_INVITE/.test(s))return 'Не удалось создать аккаунт. Попросите администратора выдать новую ссылку.';
 if(/REQUEST_DENIED_OR_EXPIRED/.test(s))return 'Ссылка истекла, отменена или данные не совпали. Обратитесь к администратору.';
 if(/email not confirmed/i.test(s))return 'Дождитесь одобрения приглашения и войдите снова.';
 const wait=s.match(/after (\d+) seconds/i);if(wait)return 'Повторить запрос можно через '+wait[1]+' сек.';
 if(/rate|too many/i.test(s))return 'Сервис ограничил частые запросы. Подождите и повторите позже.';
 if(/fetch|network/i.test(s))return 'Нет связи с сервером. Проверьте интернет и повторите.';
 return 'Не удалось выполнить действие. '+s;
}
function authenticated(session){
 if(window.staffInvite?.active()){document.body?.classList.remove('app-booting');window.staffInvite.onSession(session);return}
 const identity=session?.user.id||null;if(identity===lastAuthUser)return;lastAuthUser=identity;
 setTimeout(()=>window.adminUiStart?.(session),0);
 const active=Boolean(session);if(!active)document.body?.classList.remove('app-booting');
 $('auth').hidden=active;$('mode').hidden=true;$('logout').hidden=!active;
 if(active){$('password').value='';passwordVisible(false);$('heading').textContent='Аккаунт подключён';$('intro').textContent='Проверяем доступ к вашему кабинету…';message('Проверяем доступ к вашему кабинету…');return}
 showIdentity();
 $('heading').textContent=signup&&window.manualOwner?.mode()?'Регистрация владельца':staffLogin()?'Вход сотрудника':'Вход в приложение';
 $('intro').textContent=signup&&window.manualOwner?.mode()?'Укажите номер телефона и задайте пароль. Доступ появится после одобрения.':staffLogin()?'Для этого старого приглашения введите пароль. Последующие входы будут по номеру телефона.':'Вход по номеру телефона и паролю. Первый доступ выдаётся по персональной ссылке.';
}
$('mode').addEventListener('click',()=>{
 if(busy)return;
 if(window.staffInvite?.active()){window.staffInvite.toggleMode();return}
 if(!window.manualOwner?.mode())return;
 signup=!signup;passwordVisible(false);$('heading').textContent=signup?'Регистрация владельца':'Вход в приложение';
 $('submit').textContent=signup?'Создать аккаунт и отправить заявку':'Войти';
 $('password').autocomplete=signup?'new-password':'current-password';showIdentity();
 message(signup?'Укажите номер из приглашения, задайте пароль от 10 символов и дождитесь одобрения.':'');
});
$('auth').addEventListener('submit',async e=>{
 e.preventDefault();if(busy||!e.target.reportValidity())return;
 lock(true);message('Соединяемся с сервером…');
 try{
  const identity=$('email').value.trim(),password=$('password').value;
  if(window.staffInvite?.active()){await window.staffInvite.submit({email:identity,password});$('password').value='';passwordVisible(false);return}
  if(signup&&window.manualOwner?.mode()){await window.manualOwner.register(identity,password);$('password').value='';passwordVisible(false);return}
  let email=identity;
  if(!$('email').hidden){
   const phone=phoneNumber(identity);if(!/^\+[1-9][0-9]{7,14}$/.test(phone))throw Error('INVALID_PHONE');
   const result=await staffAccess.call('resolve_phone',{phone});email=result.alias;
  }
  const result=await client.auth.signInWithPassword({email,password});if(result.error)throw result.error;
  $('password').value='';if(result.data.session)authenticated(result.data.session);
 }catch(error){message(errorText(error),true)}finally{lock(false)}
});
$('logout').addEventListener('click',async()=>{lock(true);try{await window.orderPush?.disableAll().catch(()=>{});const {error}=await client.auth.signOut({scope:'local'});if(error)throw error;authenticated(null);message('Вы вышли из аккаунта.')}catch(e){message(errorText(e),true)}finally{lock(false)}});
client.auth.onAuthStateChange((_event,session)=>authenticated(session));
client.auth.getSession().then(({data,error})=>{if(error)message(errorText(error),true);else authenticated(data.session)}).catch(e=>message(errorText(e),true));
window.staffInvite?.init();
if(staffLogin()){
 const id=new URLSearchParams(location.hash.slice(1)).get('staffLogin');
 sessionStorage.removeItem('staff_invite_token');sessionStorage.removeItem('staff_invite_request');
 $('email').value='staff.'+id+'@accounts.invalid';$('email').hidden=true;$('email').required=false;
 document.querySelector('label[for=email]')?.setAttribute('hidden','');
 $('heading').textContent='Вход сотрудника';$('intro').textContent='Введите пароль. После входа используйте свой номер телефона.';
}
showIdentity();
