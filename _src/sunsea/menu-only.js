/* Reversible standalone menu layer. Shared ordering engine is preserved. */
{
 const texts={
 ru:{showW:'Показать официанту',wHint:'Заказ не отправляется. Покажите выбранные блюда официанту.',title:'Покажите официанту',back:'Вернуться к меню',estimate:'Предварительная сумма. Итоговый счёт уточните у официанта.',qrNone:'QR-код для оплаты ещё не добавлен. Обратитесь к официанту.',payHint:'Уточните сумму у официанта и отсканируйте QR-код в банковском приложении.',aP:'Sun&Sea Restaurant в Муйне: морепродукты, вьетнамская и тайская кухня, пицца, паста и фирменные блюда от шефа.'},
 en:{showW:'Show the waiter',wHint:'Nothing is sent. Show your selection to the waiter.',title:'Show this to the waiter',back:'Back to menu',estimate:'Estimated total. Confirm the final bill with the waiter.',qrNone:'The payment QR code has not been added yet. Please ask the waiter.',payHint:'Confirm the amount with the waiter, then scan the QR code in your banking app.',aP:'Sun&Sea Restaurant in Mui Ne: seafood, Vietnamese and Thai cuisine, pizza, pasta and signature dishes from our chef.'},
 vi:{showW:'Đưa cho nhân viên xem',wHint:'Không gửi đơn tự động. Hãy đưa các món đã chọn cho nhân viên xem.',title:'Đưa màn hình này cho nhân viên',back:'Về thực đơn',estimate:'Tổng tiền tạm tính. Vui lòng xác nhận hóa đơn với nhân viên.',qrNone:'Chưa có mã QR thanh toán. Vui lòng hỏi nhân viên.',payHint:'Xác nhận số tiền với nhân viên rồi quét mã QR bằng ứng dụng ngân hàng.',aP:'Sun&Sea Restaurant tại Mũi Né: hải sản, món Việt và Thái, pizza, mì Ý và các món đặc biệt của bếp trưởng.'},
 ko:{showW:'직원에게 보여주기',wHint:'주문은 전송되지 않습니다. 선택한 메뉴를 직원에게 보여주세요.',title:'직원에게 이 화면을 보여주세요',back:'메뉴로 돌아가기',estimate:'예상 금액입니다. 최종 계산은 직원에게 확인하세요.',qrNone:'결제 QR 코드가 아직 등록되지 않았습니다. 직원에게 문의하세요.',payHint:'직원에게 금액을 확인한 후 은행 앱으로 QR 코드를 스캔하세요.',aP:'무이네 Sun&Sea Restaurant: 해산물, 베트남 및 태국 요리, 피자, 파스타와 셰프의 시그니처 요리.'},
 zh:{showW:'出示给服务员',wHint:'不会自动发送订单。请将已选菜品出示给服务员。',title:'请将此屏幕出示给服务员',back:'返回菜单',estimate:'此为预估金额，请向服务员确认最终账单。',qrNone:'尚未添加收款二维码，请联系服务员。',payHint:'先向服务员确认金额，再使用银行应用扫描二维码。',aP:'美奈 Sun&Sea Restaurant：海鲜、越南菜与泰国菜、披萨、意面和主厨招牌菜。'}
 };
 for(const [lg,copy] of Object.entries(texts))Object.assign(T[lg],copy);
 STOP=new Set();loadStop=()=>false;PUB=()=>({});billState=()=>'';liveOrders=()=>[];inbox=()=>{};
 CK.mode='one';CK.names=[];CK.act='';CK.carts={'':cart};save();
 const originalBump=bump;bump=function(...args){CK.mode='one';return originalBump(...args)};
 const qrIcon='<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><rect x="3" y="3" width="6" height="6"/><rect x="15" y="3" width="6" height="6"/><rect x="3" y="15" width="6" height="6"/><path d="M15 15h3v3h-3zm6 0v6m-6 0h3"/></svg>';
 function makeQr(id,after){const button=document.createElement('button');button.type='button';button.id=id;button.className='tipb menu-qr';button.addEventListener('click',()=>openQr());after.insertAdjacentElement('afterend',button);return button}
 const qrFooter=makeQr('menuQrPay',$('tipF'));
 const qrCart=makeQr('menuQrPayCart',$('sheetHint'));
 const view=document.createElement('div');view.id='waiterView';view.className='sheet';view.hidden=true;document.body.appendChild(view);
 function qrLabel(){return qrIcon+'<span>'+esc(T[lang].qrPay)+'</span>'}
 renderBar=function(){const t=T[lang],x=allTotals();$('bar').hidden=!x.n;document.body.classList.toggle('hasbar',!!x.n);$('capG').innerHTML=`<i class="n">${x.n}</i>`;$('barL').textContent=t.items(x.n)+(cur==='VND'?'':' · '+moneyLine(x.sum));$('barT').textContent=fmtVND(x.sum);$('cap').classList.remove('live');$('barBtn').hidden=false;$('barGo').textContent=t.showW;qrFooter.innerHTML=qrLabel();qrCart.innerHTML=qrLabel();requestAnimationFrame(()=>document.documentElement.style.setProperty('--barh',$('bar').offsetHeight+'px'))};
 const originalSheet=renderSheet;renderSheet=function(){originalSheet();$('splitBtn').hidden=true;if(lang){$('sheetHint').textContent=T[lang].wHint;qrCart.innerHTML=qrLabel()}};
 function showWaiter(){const t=T[lang],x=totals();if(!x.n)return;
 const lines=x.L.map(l=>{const label=optLabel(l.o,lang),viLabel=optLabel(l.o,'vi');const name=l.it[IDX[lang]]+(label?' · '+label:''),vi=l.it[1]+(viLabel?' · '+viLabel:'');return `<li><span class="waiter-qty">${l.q}×</span><div><b>${esc(name)}</b>${lang==='vi'?'':`<small lang="vi">${esc(vi)}</small>`}</div><strong>${l.p===null?esc(t.ask):fmtVND(l.p*l.q)}</strong></li>`}).join('');
 const wishes=WISH.filter(w=>wish[w.k]).map(w=>esc(w[lang])+(lang==='vi'?'':' / '+esc(w.vi))).join(' · ');
 view.innerHTML=`<div class="panel waiter-panel"><div class="hd"><h3>${esc(t.title)}</h3><button type="button" class="x" data-waiter-close aria-label="${esc(t.cancel)}">×</button></div><p class="hint">${esc(t.wHint)}</p><ul class="waiter-lines">${lines}</ul>${wishes?`<p class="waiter-wishes">${wishes}</p>`:''}<div class="tot"><span>${esc(t.total)}</span><div><b>${fmtVND(x.sum)}</b><small>${esc(moneyLine(x.sum))}</small></div></div><p class="hint">${esc(t.estimate)}${x.extra?' '+esc(t.extra(x.extra)):''}</p><button class="btn" type="button" data-waiter-close>${esc(t.back)}</button><button class="tipb menu-qr" type="button" data-menu-qr>${qrLabel()}</button></div>`;
 $('sheet').hidden=true;view.hidden=false;
 }
 view.addEventListener('click',e=>{if(e.target===view||e.target.closest('[data-waiter-close]'))view.hidden=true;else if(e.target.closest('[data-menu-qr]'))openQr()});
 document.addEventListener('keydown',e=>{if(e.key==='Escape')view.hidden=true});
 sendOrder=showWaiter;openPick=showWaiter;openTbl=()=>{renderSheet();$('sheet').hidden=false};openPay=()=>{};openTips=()=>{};
 openQr=function(){const t=T[lang],qr=SERVICE_CONFIG.paymentQr;$('sheet').hidden=true;view.hidden=true;$('qrH').textContent=t.qrH;$('qrCk').hidden=true;$('qrImg').hidden=!qr;if(qr)$('qrImg').src=qr;else $('qrImg').removeAttribute('src');$('qrBox').classList.toggle('has',!!qr);$('qrBox').classList.toggle('none',!qr);$('qrBox').querySelector('svg').style.display='none';$('qrSoon').hidden=!!qr;$('qrSoon').textContent=t.qrNone;$('qrPaid').hidden=true;$('qrS').textContent=qr?t.payHint:'';$('qrs').hidden=false};
}
