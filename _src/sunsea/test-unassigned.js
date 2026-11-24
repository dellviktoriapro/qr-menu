/* The single test-entry QR identifies the cafe. The waiter assigns the table. */
(()=>{'use strict';
const hash=new URLSearchParams(location.hash.slice(1)),valid=x=>/^[a-f0-9]{64}$/.test(x||'');
if(valid(hash.get('table')))return;
let entry=hash.get('entry')||sessionStorage.getItem('rp_sunsea_test_entry');if(!valid(entry))return;
sessionStorage.setItem('rp_sunsea_test_entry',entry);sessionStorage.removeItem('rp_sunsea_test_test_table');
if(hash.has('entry'))history.replaceState(null,'',location.pathname+location.search);
const key='rp_sunsea_unassigned_pending:'+entry,endpoint='https://vppgtrbewgqigfinknex.supabase.co/rest/v1/rpc/rp_test_entry_submit';let busy=false;
const dialog=document.createElement('dialog');dialog.id='test-submit-dialog';dialog.innerHTML='<p role="status"></p><div class="guest-dialog-actions"><button type="button" data-back>Вернуться к меню</button><button type="button" data-retry hidden>Повторить отправку</button></div>';
dialog.style.cssText='max-width:480px;width:calc(100% - 32px);padding:28px;border:1px solid #a38652;border-radius:20px;background:#fff8ed;color:#243c30;font:16px Montserrat,system-ui;box-shadow:0 25px 80px #0006';
dialog.querySelector('button').style.cssText='padding:13px 22px;border:1px solid #a38652;border-radius:12px;background:linear-gradient(135deg,#efdca9,#bd9c64);color:#26392c;font:600 15px Montserrat,system-ui;cursor:pointer';document.body.append(dialog);dialog.querySelector('button').onclick=()=>dialog.close();
const retry=dialog.querySelector('[data-retry]');retry.onclick=()=>sendOrder();
const notice=(text,canRetry=false)=>{retry.hidden=!canRetry;dialog.querySelector('p').textContent=text;if(!dialog.open)dialog.showModal()};
const notesKey='rp_sunsea_test_item_notes';let lineNotes={};try{lineNotes=JSON.parse(sessionStorage.getItem(notesKey)||'{}')}catch{}
const notesId=(ck,k)=>(ck||'Общий счёт')+'\n'+k,saveNotes=()=>sessionStorage.setItem(notesKey,JSON.stringify(lineNotes));
const originalSheet=renderSheet;renderSheet=()=>{originalSheet();$('chips').hidden=true;$('wishL').hidden=true;for(const li of $('sheet').querySelectorAll('.lines li')){const control=li.querySelector('[data-k]');if(!control)continue;const k=control.dataset.k,ck=control.dataset.c||'',id=notesId(ck,k),value=lineNotes[id]||{flags:[],text:''},group=SEC[k.split('|')[0]]?.g||'food';const box=document.createElement('details');box.className='line-wishes';box.style.cssText='flex-basis:100%;width:100%;padding:8px 0';const summary=document.createElement('summary');summary.textContent=(lang==='ru'?'Пожелания к позиции':lang==='vi'?'Ghi chú cho món':'Item preferences')+(guestLineOptions.note(value)?' ✓':'');box.append(summary);const tags=document.createElement('div');tags.style.cssText='display:flex;flex-wrap:wrap;gap:6px;margin:10px 0';for(const option of guestLineOptions.options(group)){const button=document.createElement('button');button.type='button';button.className='chip';button.textContent=option[lang]||option.en;button.setAttribute('aria-pressed',value.flags.includes(option.k));button.onclick=()=>{value.flags=guestLineOptions.toggle(value.flags,option.k);lineNotes[id]=value;saveNotes();for(const b of tags.children)b.setAttribute('aria-pressed',value.flags.includes(b.dataset.option));summary.textContent=(lang==='ru'?'Пожелания к позиции':lang==='vi'?'Ghi chú cho món':'Item preferences')+' ✓'};button.dataset.option=option.k;tags.append(button)}box.append(tags);const input=document.createElement('textarea');input.maxLength=240;input.value=value.text;input.placeholder=lang==='ru'?'Комментарий к этому блюду или напитку':lang==='vi'?'Ghi chú cho món này':'Comment for this item';input.setAttribute('aria-label',input.placeholder);input.style.cssText='width:100%;box-sizing:border-box;padding:10px;border-radius:10px;font:inherit';input.oninput=()=>{value.text=input.value;lineNotes[id]=value;saveNotes()};box.append(input);li.style.flexWrap='wrap';li.append(box)}};
openPick=()=>sendOrder();$('tChip').hidden=true;
sendOrder=async()=>{if(busy)return;busy=true;let request;try{
 request=JSON.parse(sessionStorage.getItem(key)||'null');
 if(!request){if(!allTotals().n)return;const note=WISH.filter(w=>wish[w.k]).map(w=>w.vi).join('; ');const checks=allCarts().map(([name,c])=>({label:name||'Общий счёт',items:totals(c).L.map(l=>({key:'sunsea|'+(Array.isArray(l.it[5])?l.k:l.k.split('|').slice(0,2).join('|')),cart_key:l.k,quantity:l.q,note:[guestLineOptions.note(lineNotes[notesId(name,l.k)]),note].filter(Boolean).join('; ').slice(0,300)}))})).filter(c=>c.items.length);
 request={r:crypto.randomUUID(),b:{lang:lang||'ru',checks}};sessionStorage.setItem(key,JSON.stringify(request));}
 notice(lang==='vi'?'Đang gửi…':lang==='en'?'Sending your order…':'Отправляем заказ…');
 const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json',apikey:'sb_publishable_02aoSyGU3H5SXUbsqwzeow_TyaxYKtq'},body:JSON.stringify({entry_token:entry,...request})}),result=await response.json();
 if(!response.ok){const message=result.message||'SERVER_ERROR';if(response.status<500&&response.status!==429)sessionStorage.removeItem(key);const error=Error(message);error.status=response.status;throw error}
 if(!result.ok||result.id!==request.r)throw Error('INVALID_RECEIPT');
 const applied=CK.serverApplied||{};
 if(!applied[request.r]){for(const ck of request.b.checks){const match=allCarts().find(([name])=>(name||'Общий счёт')===ck.label);if(match)for(const i of ck.items){const n=Math.max(0,Number(match[1][i.cart_key]||0)-i.quantity);if(n)match[1][i.cart_key]=n;else delete match[1][i.cart_key]}}CK.serverApplied={...applied,[request.r]:true};wish={};save();}
 for(const ck of request.b.checks)for(const i of ck.items)delete lineNotes[notesId(ck.label,i.cart_key)];saveNotes();sessionStorage.removeItem(key);$('sheet').hidden=true;render();$('tChip').hidden=true;
 notice(lang==='vi'?'Đơn đã gửi. Nhân viên sẽ chọn số bàn.':lang==='en'?'Order sent. Your waiter will assign the table.':'Заказ отправлен. Номер стола укажет официант при принятии.');
 }catch(error){
 const definitive=error.status&&error.status<500&&error.status!==429;
 const text=/ITEM_UNAVAILABLE/.test(error.message)?'Блюдо недоступно. Проверьте заказ и повторите.':/TEST_ENTRY_DISABLED/.test(error.message)?'Тестовая ссылка недействительна. Обратитесь к официанту.':error.status===429?'Слишком много запросов. Подождите немного и повторите отправку.':definitive?'Сервер не принял заказ. Проверьте состав заказа или обратитесь к официанту.':!request?'Не удалось подготовить заказ. Обновите меню и попробуйте снова.':'Связь с сервером прервалась. Нажмите «Повторить отправку»: повторный заказ не создастся.';
 notice(text,!!request&&!definitive);
 }finally{busy=false}};
})();
