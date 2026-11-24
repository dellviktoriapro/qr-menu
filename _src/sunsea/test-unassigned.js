/* The single test-entry QR identifies the cafe. The waiter assigns the table. */
(()=>{'use strict';
const hash=new URLSearchParams(location.hash.slice(1)),valid=x=>/^[a-f0-9]{64}$/.test(x||'');
if(valid(hash.get('table')))return;
let entry=hash.get('entry')||sessionStorage.getItem('rp_sunsea_test_entry');if(!valid(entry))return;
sessionStorage.setItem('rp_sunsea_test_entry',entry);sessionStorage.removeItem('rp_sunsea_test_test_table');
if(hash.has('entry'))history.replaceState(null,'',location.pathname+location.search);
const key='rp_sunsea_unassigned_pending:'+entry,endpoint='https://vppgtrbewgqigfinknex.supabase.co/rest/v1/rpc/rp_test_entry_submit';let busy=false;
const dialog=document.createElement('dialog');dialog.id='test-submit-dialog';dialog.innerHTML='<p role="status"></p><button type="button">Вернуться к меню</button>';
dialog.style.cssText='max-width:480px;width:calc(100% - 32px);padding:28px;border:1px solid #a38652;border-radius:20px;background:#fff8ed;color:#243c30;font:16px Montserrat,system-ui;box-shadow:0 25px 80px #0006';
dialog.querySelector('button').style.cssText='padding:13px 22px;border:1px solid #a38652;border-radius:12px;background:linear-gradient(135deg,#efdca9,#bd9c64);color:#26392c;font:600 15px Montserrat,system-ui;cursor:pointer';document.body.append(dialog);dialog.querySelector('button').onclick=()=>dialog.close();
const notice=text=>{dialog.querySelector('p').textContent=text;if(!dialog.open)dialog.showModal()};
openPick=()=>sendOrder();$('tChip').hidden=true;
sendOrder=async()=>{if(busy)return;busy=true;try{
 let request=JSON.parse(sessionStorage.getItem(key)||'null');
 if(!request){if(!allTotals().n)return;const note=WISH.filter(w=>wish[w.k]).map(w=>w.vi).join('; ');const checks=allCarts().map(([name,c])=>({label:name||'Общий счёт',items:totals(c).L.map(l=>({key:'sunsea|'+(Array.isArray(l.it[5])?l.k:l.k.split('|').slice(0,2).join('|')),cart_key:l.k,quantity:l.q,note:guestLineOptions.note(lineNotes[notesId(name,l.k)])||note}))})).filter(c=>c.items.length);
 request={r:crypto.randomUUID(),b:{lang:lang||'ru',checks}};sessionStorage.setItem(key,JSON.stringify(request));}
 notice(lang==='vi'?'Đang gửi…':lang==='en'?'Sending your order…':'Отправляем заказ…');
 const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json',apikey:'sb_publishable_02aoSyGU3H5SXUbsqwzeow_TyaxYKtq'},body:JSON.stringify({entry_token:entry,...request})}),result=await response.json();
 if(!response.ok){if(/ITEM_UNAVAILABLE|TEST_ENTRY_DISABLED|INVALID_/.test(result.message||''))sessionStorage.removeItem(key);throw Error(result.message||'SERVER_ERROR')}
 if(!result.ok||result.id!==request.r)throw Error('INVALID_RECEIPT');
 const applied=CK.serverApplied||{};
 if(!applied[request.r]){for(const ck of request.b.checks){const match=allCarts().find(([name])=>(name||'Общий счёт')===ck.label);if(match)for(const i of ck.items){const n=Math.max(0,Number(match[1][i.cart_key]||0)-i.quantity);if(n)match[1][i.cart_key]=n;else delete match[1][i.cart_key]}}CK.serverApplied={...applied,[request.r]:true};wish={};save();}
 for(const ck of request.b.checks)for(const i of ck.items)delete lineNotes[notesId(ck.label,i.cart_key)];saveNotes();sessionStorage.removeItem(key);$('sheet').hidden=true;render();$('tChip').hidden=true;
 notice(lang==='vi'?'Đơn đã gửi. Nhân viên sẽ chọn số bàn.':lang==='en'?'Order sent. Your waiter will assign the table.':'Заказ отправлен. Номер стола укажет официант при принятии.');
}catch(error){notice(/ITEM_UNAVAILABLE/.test(error.message)?'Блюдо недоступно. Проверьте заказ и повторите.':/TEST_ENTRY_DISABLED/.test(error.message)?'Тестовая ссылка недействительна. Обратитесь к официанту.':'Нет подтверждения отправки. Повторите: номер запроса сохранён.')}finally{busy=false}};
})();
