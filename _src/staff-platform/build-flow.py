# Compile original waiter, kitchen, bill and editor functions against server callbacks.
from pathlib import Path
import json
import runpy
HERE=Path(__file__).resolve().parent
def build():
 s=(HERE.parent/'ops/tpl.html').read_text(encoding='utf-8')
 categories={section['id']:{k:section['n'][k] for k in ('ru','vi')} for venue in ('chez','sunsea') for section in runpy.run_path(str(HERE.parent/venue/'data.py'))['S']}
 def cut(a,b):return s[s.index(a):s.index(b,s.index(a))]
 chunks=[cut('const WISH=','const G='),cut('const esc=','/* sound */'),cut('function reqTxt','function newOrder'),cut('function forMe','function accept'),cut('function billOrders','function closeBill'),cut('function serveActions','function kReady'),cut('function stationItems','function simulate'),cut('function orderLines','function rGuest'),cut('function oCard(o,mode)','/* --- owner --- */'),cut('let stopQ=','const ROLE_OPTS=')]
 chunks[-1]=chunks[-1].replace('class="btn sm ${out?"":"outb"}" type="button" data-stop=', 'class="btn sm availability-toggle ${out?"":"outb"}" type="button" role="switch" aria-checked="${!out}" aria-label="${esc((l==="ru"?"Доступность: ":"Tình trạng: ")+coName(d,l))}" data-stop=').replace('${esc(out?t("stopBack"):t("stopOut"))}', '<span aria-hidden="true"></span><b>${esc(out?(l==="ru"?"Выключено":"Đã tắt"):(l==="ru"?"Доступно":"Có món"))}</b>')
 chunks[-1]=chunks[-1].replace('let stopQ="";', 'let stopQ=ST.stopQ||"";').replace('stopQ=qi.value;flt()', 'stopQ=qi.value;ST.stopQ=stopQ;save();flt()')
 chunks=[x.replace('const g={};','const g=Object.create(null);').replace('const r={};','const r=Object.create(null);').replace('hour:"2-digit",minute:"2-digit"','timeZone:snapshot.cafe.timezone||"Asia/Ho_Chi_Minh",hour:"2-digit",minute:"2-digit"').replace('const mineO=o.waiter===ST.me;', "const mineO=o.waiter===ST.me||['owner','manager'].includes(snapshot.me.role);").replace('${o.table}', '${esc(o.table)}').replace('${b.table}', '${esc(b.table)}') for x in chunks]
 chunks[-2]=chunks[-2].replace('const timeRef=o.status===', 'const timeRef=(o.status===').replace('o.servedAt;', 'o.servedAt)||o.createdAt;')
 chunks[-2]=chunks[-2].replace('const filt=o=>f==="all"||o.items.some(i=>M[i.mid].st===(f==="bar"?"b":"k"));', 'const filt=o=>(f==="all"||o.items.some(i=>M[i.mid].st===(f==="bar"?"b":"k")))&&!(f!=="all"&&o.stationServedAt?.[f]);')
 # Original bill close used synchronous local mutation. Wait for the actual receipt instead.
 chunks[-2]=chunks[-2].replace('ED.table=Math.max(1,+tb.value||1)','ED.table=tb.value')
 chunks[-2]=chunks[-2].replace('$("sheet").addEventListener("click",e=>{if(e.target===$("sheet"))closeEditor()});','')
 chunks[-2]=chunks[-2].replace('$("bClose").onclick=e=>','$("bClose").onclick=async e=>').replace('if(!btn.dataset.arm){btn.dataset.arm="1";btn.textContent=t("closeSure");return}closeBill(bid,{...PM});closeEditor();','if(!window.confirm(t("closeSure")))return;if(!await closeBill(bid,{...PM}))return;closeEditor();')
 # Keep the original order renderers; use the server shell for personal controls.
 chunks=[x.replace('${on?"":`<div class="alert red"><span>${esc(t("offNote"))}</span></div>`}', '') for x in chunks]
 chunks=[x.replace('...groups,["tables",t("tTables"),bills]];', '...groups,["tables",t("tTables"),bills],["closed",ST.lang==="ru"?"Закрытые · 24 часа":"Đã đóng · 24 giờ",Object.values(ST.bills).filter(b=>b.closed&&b.closedAt>Date.now()-86400000&&billOrders(b.id).length).sort((a,b)=>b.closedAt-a.closedAt)]];') for x in chunks]
 # Keep the selected queue visible after an action. Mobile exposes the four live queues;
 # paid receipts remain available from the tables screen.
 chunks=[x.replace('if(a==="accept"){accept(id);ST.wtab="cooking";save();render()}', 'if(a==="accept"){accept(id)}')
          .replace('ST.wtab="cooking";save();closeEditor();render()', 'save();closeEditor();render()') for x in chunks]
 chunks=[x.replace('const cur=tabs.find(x=>x[0]===ST.wtab)||tabs[0];', 'const visibleTabs=matchMedia("(max-width:760px)").matches?tabs.filter(x=>!["all","closed"].includes(x[0])):tabs;const cur=visibleTabs.find(x=>x[0]===ST.wtab)||visibleTabs[0];')
          .replace('${tabs.map(([k,lab,arr])=>', '${visibleTabs.map(([k,lab,arr])=>')
          .replace('const bills=Object.values(ST.bills).filter(b=>!b.closed&&billOrders(b.id).some(o=>!o.seed));', 'const bills=Object.values(ST.bills).filter(b=>!b.closed);') for x in chunks]
 chunks=[x.replace('cur[0]==="all"?groups.map', 'cur[0]==="closed"?`<div class="flow-grid">${cur[2].length?cur[2].map(closedBillCard).join(""):`<p class="empty">${ST.lang==="ru"?"За последние 24 часа закрытых счетов нет":"Không có hóa đơn đã đóng trong 24 giờ qua"}</p>`}</div>`:cur[0]==="all"?groups.map') for x in chunks]
 chunks=[__import__('re').sub(r'<button type="button" id="waiterHistory">.*?</button>', '', x) for x in chunks]
 chunks=['\n'.join(line for line in x.splitlines() if 'el.querySelector("#waiterHistory").onclick' not in line) for x in chunks]
 table_body='''const tablesBody=()=>{const closed=Object.values(ST.bills).filter(b=>b.closed&&b.closedAt>Date.now()-86400000&&billOrders(b.id).length).sort((a,b)=>b.closedAt-a.closedAt);return `<div class="table-view-switch"><button type="button" data-tv="map" class="${ST.tview!=="closed"?"on":""}">${ST.lang==="ru"?"Карта столов":"Sơ đồ bàn"}</button><button type="button" data-tv="closed" class="${ST.tview==="closed"?"on":""}">${ST.lang==="ru"?"Закрытые чеки":"Hóa đơn đã đóng"} · ${closed.length}</button></div>${ST.tview==="closed"?`<div class="flow-grid">${closed.length?closed.map(closedBillCard).join(""):`<p class="empty">${ST.lang==="ru"?"За последние 24 часа закрытых счетов нет":"Không có hóa đơn đã đóng trong 24 giờ qua"}</p>`}</div>`:hallMap()}`};'''
 chunks=[__import__('re').sub(r'const tablesBody=\(\)=>[^\n]+', table_body, x) for x in chunks]
 # Availability is managed from the dedicated Menu screen.
 chunks=[x.replace('const f=ST.ktab;const L=live();', 'const f=ST.ktab==="stop"?"all":ST.ktab;const L=live();').replace(',["stop",t("kStop")]', '') for x in chunks]
 chunks=[__import__('re').sub(r'--tc:var\(--t(\$\{[^}]+\})\)',r'--tc:var(--t\1);--tc-ink:var(--t\1-ink)',x) for x in chunks]
 layout=json.loads((HERE.parent/'sunsea/table-layout.json').read_text(encoding='utf-8'))
 return r'''// Generated from the original ops/tpl.html. Do not edit generated UI.
window.staffFlow=(()=>{const SUNSEA_LAYOUT='''+json.dumps(layout,ensure_ascii=False,separators=(',',':'))+r''';const CATALOG_CATEGORIES='''+json.dumps(categories,ensure_ascii=False,separators=(',',':'))+r''';const preferences=new Map();let overlay=null;
function renderFlow(el,options){
const {snapshot,cafe}=options,mapped=staffServerState.mapSnapshot(snapshot),M=mapped.menu;let ST=mapped.state;const pref=preferences.get(cafe.id+':'+ST.me)||{};Object.assign(ST,pref);if(options.lang)ST.lang=options.lang;ST.role=options.screen==='prep'?'kitchen':'waiter';ST.split=options.screen==='workbench';ST.ktab=ST.ktab==='stop'?'all':ST.ktab||'all';ST.shift[ST.me]=snapshot.shifts?.[ST.me]||false;
if(matchMedia('(max-width:760px)').matches&&['all','closed'].includes(ST.wtab))ST.wtab=ST.wtab==='closed'?'tables':'new';
let accept,toKitchen,kReady,kItem,served,closeBill;
const stopMenu=snapshot.menu.filter(i=>['owner','manager','waiter'].includes(snapshot.me.role)||i.station===snapshot.me.role),CMENU=[['menu','Thực đơn','Меню',stopMenu.map(i=>[i.names?.vi||i.names?.ru||'',i.names?.ru||i.names?.vi||''])]];
const MENU=Object.values(M).filter(m=>m.active&&m.p!==null&&!snapshot.menu.find(i=>i.id===m.id)?.stopped),PH={},NEW_LATE_MS=45000,READY_ESC_MS=30000,REORDER_MS=40000;
const WAITERS=()=>ST.staff.filter(x=>x.status==='active'&&(['owner','manager','waiter'].includes(x.role)||x.id===ST.me));
if(!overlay){overlay=document.createElement('div');overlay.className='original-flow flow-overlay';overlay.innerHTML='<section id="flow-sheet" class="sheet" hidden><div class="sheetin" id="flow-sheetIn"></div></section><div id="flow-toasts"></div>';document.body.append(overlay)}
const $=id=>overlay.querySelector('#flow-'+id)||overlay.querySelector('#'+id)||el.querySelector('#'+id);
overlay.querySelector('#flow-sheet').onclick=e=>{if(e.target===e.currentTarget)closeEditor()};
const save=()=>preferences.set(cafe.id+':'+ST.me,Object.fromEntries(['lang','wtab','ktab','mineOnly','tview','stopQ'].map(k=>[k,ST[k]]))),render=()=>{save();options.onRender()},toast=(msg,sub)=>options.onNotice(msg+(sub?' · '+sub:''));
const mutate=()=>{throw Error('LOCAL_BUSINESS_MUTATION_FORBIDDEN')},staffBy=id=>ST.staff.find(x=>x.id===id),readyTargets=o=>['owner','manager'].includes(snapshot.me.role)?[ST.me]:[o.waiter],showsForMe=()=>true;
'''+'\n'.join(x.rstrip() for c in chunks for x in c.splitlines())+r'''
// Operational cards separate each station's items and readiness.
orderLines=(o,opts={})=>`<div class="order-stations">${["kitchen","bar"].map(scope=>{
 const items=stationItems(o,scope);if(!items.length)return "";
 const state=o.status==="served"||o.stationServedAt?.[scope]?"served":stationReady(o,scope)?"ready":["new","accepted"].includes(o.status)?"waiting":"cooking";
 const label=ST.lang==="ru"?{served:"Вынесено",ready:"Можно вынести",waiting:"Ожидает передачи",cooking:"Готовится"}[state]:{served:"Đã phục vụ",ready:"Có thể phục vụ",waiting:"Chờ chuyển",cooking:"Đang chuẩn bị"}[state];
 return `<section class="order-station is-${state}"><div class="order-station-head"><strong>${esc(t(scope==="bar"?"kBar":"kKitchen"))}</strong><span class="order-station-state">${label}</span></div><ul class="lines">${items.map(i=>`<li><span class="q">${i.qty}×</span><span class="n"><b>${esc(nm(i.mid,"vi"))}</b>${i.added?`<span class="badge-new">+</span>`:""}${ST.lang==="ru"?`<span class="tr">${esc(nm(i.mid,"ru"))}</span>`:o.lang!=="vi"?`<span class="tr">${esc(nm(i.mid,"en"))}</span>`:""}${i.note?`<span class="note">${esc(i.note)}</span>`:""}${i.done&&state==="cooking"?`<span class="item-ready">${ST.lang==="ru"?"Готово":"Đã xong"}</span>`:""}</span><span class="p">${vnd(M[i.mid].p*i.qty)}</span></li>`).join("")}</ul></section>`;
 }).join("")}</div>`;
// Authoritative commands replace all business mutations; preferences remain local.
setStop=(key,on)=>{const item=stopMenu[Number(key.split('|')[1])];if(item)return options.onCommand('stop',{item_id:item.id,stopped:on})};
const originalStop=rStop;rStop=host=>{const prior=ST.stop;ST.stop=Object.fromEntries(stopMenu.map((i,n)=>[i,n]).filter(([i])=>i.stopped).map(([i,n])=>['menu|'+n,{at:0}]));originalStop(host);if(snapshot.me.role==='waiter'){host.querySelectorAll('[data-stop]').forEach(b=>b.disabled=true);const text=host.querySelector('p');if(text)text.textContent=ST.lang==='ru'?'Доступность меняет кухня, бар или управляющий.':'Bếp, bar hoặc quản lý cập nhật tình trạng món.'}ST.stop=prior};
const command=async(a,b)=>options.onCommand(a,b);
 const closedBillCard=b=>{const os=billOrders(b.id),sum=billTotal(b.id),ru=ST.lang==='ru';return `<article class="closed-bill"><div class="closed-bill-head"><span>${ru?'Стол':'Bàn'} ${esc(b.table)}</span><span>${ru?'Оплачено':'Đã thanh toán'}</span></div><h3>${ru?'Итоговый счёт':'Hóa đơn cuối cùng'}</h3><p>${os.length} ${ru?'заказ(а) в одном счёте':'lượt gọi món trong một hóa đơn'} · ${new Date(b.closedAt).toLocaleString(ru?'ru-RU':'vi-VN')}</p>${billChecks(os)||`<ul class="lines bill">${aggItems(os).map(billLine).join('')}</ul>`}<div class="closed-bill-total"><span>${ru?'Итого по счёту':'Tổng hóa đơn'}</span><strong>${vnd(sum)}</strong></div><button type="button" class="btn ghost sm" data-a="bill" data-id="${b.id}">${ru?'Посмотреть счёт':'Xem hóa đơn'}</button></article>`};
accept=id=>command('guest_accept',{submission_id:id});toKitchen=id=>command('send',staffServerState.orderCommand(ST,'send',id).b);
kReady=(id,station)=>command('station_ready',staffServerState.orderCommand(ST,'station_ready',id,{station}).b);
kItem=(id,index)=>{const i=ST.orders.find(o=>o.id===id)?.items[index];if(i)return command('item_ready',staffServerState.orderCommand(ST,'item_ready',id,{item_id:i.id,ready:!i.done}).b)};
served=(id,station)=>command('serve',staffServerState.orderCommand(ST,'serve',id,{station}).b);
closeBill=async(id,pays)=>{const bill=snapshot.bills.find(b=>b.id===id);if(!bill||bill.status!=='open'){options.onNotice(ST.lang==='ru'?'Этот счёт уже закрыт. Данные обновляются.':'Hóa đơn đã đóng. Đang cập nhật.');return false}return !!await command('bill_close',staffFlowContract.closeBody(snapshot,id,pays));};
openTipQr=()=>options.onProfile();
commitED=async send=>{syncED();const draft=structuredClone(ED);if(!draft.items.length)return;draft.items=draft.items.map(i=>({...i,serverId:M[i.mid]?.serverId}));const request=staffFlowContract.editBody(snapshot,draft,send);if(await command(request.a,request.b)){closeEditor();save();options.onRender()}};
el.querySelectorAll?.('[data-a=accept]');
// Pending guest submissions retain their exact server ID, quotes, notes and check names.
for(const g of options.incoming||[]){const items=[];for(const ck of g.checks)for(const [n,i] of ck.items.entries()){const mid='incoming:'+g.id+':'+ck.id+':'+n;M[mid]={...i.names,p:i.price};items.push({mid,qty:i.quantity,note:(g.checks.length>1?'Чек '+ck.label+'. ':'')+(i.note||'')})}ST.orders.push({id:g.id,no:g.id.slice(0,8),status:'new',table:g.table,items,createdAt:Date.parse(g.created_at),check:g.checks.length===1?g.checks[0].label:'',src:'qr',lang:g.lang,wishes:[],seed:false})}
for(const q of options.services||[]){const b=ST.bills[q.bill_id];if(b){b.req={at:Date.parse(q.created_at),pay:q.method==='qr_transfer'?'qr':q.method,check:q.check,paid:q.paid};(b.reqs||=[]).push(b.req)}}
hallMap=()=>{
 const ru=ST.lang==='ru',isSunSea=snapshot.menu.some(item=>String(item.external_key||'').startsWith('sunsea|'));
 const byLabel=new Map(snapshot.tables.map(tb=>[String(tb.label),tb]));
 const capacity=slot=>slot.min===slot.max?String(slot.max):slot.min+'–'+slot.max;
 const card=(tb,slot)=>{
  const bill=snapshot.bills.find(b=>b.table_id===tb.id&&b.status==='open'),os=bill?ST.orders.filter(o=>o.bill===bill.id):[];
  const waiting=(options.incoming||[]).some(g=>g.table===tb.label),req=bill&&(options.services||[]).some(q=>q.bill_id===bill.id&&!q.done);
  const state=waiting?'waiting':!bill?'free':req?'bill':os.some(o=>o.status==='ready'||['bar','kitchen'].some(scope=>pendingServe(o,scope)))?'ready':os.some(o=>['accepted','cooking'].includes(o.status))?'cook':os.some(o=>o.status==='new')?'new':'eat';
  const label=(ru?{waiting:'Ожидает заказ',free:'Свободен',bill:'Просит счёт',ready:'Можно выносить',cook:'Готовится',new:'Новый заказ',eat:'Занят'}:{waiting:'Chờ gọi món',free:'Còn trống',bill:'Yêu cầu tính tiền',ready:'Sẵn sàng phục vụ',cook:'Đang chuẩn bị',new:'Đơn mới',eat:'Đang dùng bữa'})[state];
  const sum=os.reduce((n,o)=>n+tot(o),0),seats=slot?capacity(slot):tb.seats;
  const position=slot?' style="left:'+slot.x/6+'%;top:'+slot.y/9+'%;width:'+slot.w/6+'%;height:'+slot.h/9+'%"':'';
  return '<div class="hall-table '+state+(slot?' hall-plan-table'+(slot.kind==='booth'?' is-booth':'')+(slot.group?' in-room':''):'')+'"'+position+'><button type="button" class="hall-table-main" data-ht="'+esc(tb.label)+'" aria-label="'+(ru?'Стол ':'Bàn ')+esc(tb.label)+', '+seats+(ru?' мест, ':' chỗ, ')+label+'"><strong>'+esc(tb.label)+'</strong><span>'+seats+(ru?' мест':' chỗ')+'</span><small>'+label+'</small>'+(bill?'<em>'+vnd(sum)+'</em>':'')+'</button>'+(options.onQr?'<button type="button" class="hall-table-qr" data-hall-qr="'+esc(tb.id)+'" aria-label="QR меню стола '+esc(tb.label)+'">QR</button>':'')+'</div>';
 };
 const planned=isSunSea?SUNSEA_LAYOUT.tables.filter(slot=>byLabel.has(String(slot.id))):[];
 const seen=new Set(planned.map(slot=>String(slot.id)));
 const extras=snapshot.tables.filter(tb=>!seen.has(String(tb.label)));
 const floor='<div class="server-hall-plan-scroll" tabindex="0" aria-label="'+(ru?'План зала Sun&Sea, можно прокрутить горизонтально':'Sơ đồ Sun&Sea, có thể cuộn ngang')+'"><div class="server-hall-plan"><div class="hall-plan-door" aria-hidden="true">⌄<span>'+(ru?'Вход':'Lối vào')+'</span></div><div class="hall-plan-aisle" aria-hidden="true">'+(ru?'ПРОХОД':'LỐI ĐI')+'</div><div class="hall-plan-room" aria-hidden="true"><span>'+(ru?'Зал · 30 мест':'Phòng · 30 chỗ')+'</span></div>'+planned.map(slot=>card(byLabel.get(String(slot.id)),slot)).join('')+'</div></div>';
 const cells=isSunSea?floor+(extras.length?'<div class="server-hall-grid">'+extras.map(tb=>card(tb)).join('')+'</div>':''):'<div class="server-hall-grid">'+snapshot.tables.map(tb=>card(tb)).join('')+'</div>';
 return '<div class="server-hall"><div class="server-hall-heading"><h3>'+(ru?'Карта зала':'Sơ đồ bàn')+'</h3><span>'+snapshot.tables.length+(ru?' столов · ':' bàn · ')+snapshot.tables.reduce((n,t)=>n+t.seats,0)+(ru?' мест':' chỗ')+'</span></div>'+cells+'<div class="server-hall-legend"><span>○ '+(ru?'Свободен':'Còn trống')+'</span><span>● '+(ru?'Ожидает заказ':'Chờ gọi món')+'</span><span>● '+(ru?'Занят':'Đang dùng bữa')+'</span><span>● '+(ru?'Можно выносить':'Sẵn sàng phục vụ')+'</span></div></div>';
};
el.classList.add('original-flow');
if(options.screen==='menu'){rStop(el)}else if(options.screen==='workbench'){el.innerHTML='<section><h2>'+esc(ST.lang==='ru'?'Заказы':'Đơn hàng')+'</h2><div id=\"flow-waiter-pane\"></div></section><section><h2>'+esc(ST.lang==='ru'?'Кухня и бар':'Bếp & Bar')+'</h2><div id=\"flow-prep-pane\"></div></section>';el.classList.add('flow-workbench');rWaiter(el.querySelector('#flow-waiter-pane'));rKitchen(el.querySelector('#flow-prep-pane'))}else if(options.screen==='prep'){if(['bar','kitchen'].includes(snapshot.me.role)&&ST.ktab!=='stop')ST.ktab=snapshot.me.role;rKitchen(el);if(['bar','kitchen'].includes(snapshot.me.role))el.querySelectorAll('[data-kt]').forEach(b=>{if(![snapshot.me.role,'stop'].includes(b.dataset.kt))b.remove()})}
else rWaiter(el);
el.querySelectorAll('[data-a=accept]').forEach(b=>{const decline=document.createElement('button');decline.type='button';decline.className='btn ghost sm';decline.textContent=ST.lang==='ru'?'Отклонить':'Từ chối';decline.onclick=()=>{if(confirm(ST.lang==='ru'?'Отклонить этот заказ?':'Từ chối đơn này?'))options.onCommand('guest_reject',{submission_id:b.dataset.id})};b.after(decline);
  // A shift controls notifications, not the server permission to accept an order.
  b.disabled=false;b.onclick=async()=>{const label=b.textContent;b.disabled=true;b.textContent=ST.lang==='ru'?'Принимаем…':'Đang nhận…';try{const saved=await accept(b.dataset.id);if(saved)options.onRender()}finally{if(b.isConnected){b.disabled=false;b.textContent=label}}};
});
if(options.headerManaged)el.querySelector('.who')?.remove();
const select=el.querySelector('#meSel');if(select){select.value=ST.me;select.disabled=true;select.setAttribute('aria-label',ST.lang==='ru'?'Ваш аккаунт':'Tài khoản của bạn')}
const shift=el.querySelector('#shiftBtn');if(shift)shift.onclick=()=>options.onShift(!ST.shift[ST.me]);
const manual=el.querySelector('#manualBtn');if(manual)manual.disabled=snapshot.me.role==='waiter'&&!ST.shift[ST.me];
// Only authenticated assignment may edit a draft; others can view status.
el.querySelectorAll('[data-a=edit],[data-a=kitchen],[data-a=served]').forEach(b=>{const o=ST.orders.find(o=>o.id===b.dataset.id);if(snapshot.me.role==='waiter'&&o?.waiter!==ST.me)b.disabled=true});
el.querySelectorAll('[data-a=edit]').forEach(b=>{const o=ST.orders.find(o=>o.id===b.dataset.id);if(o?.status!=='accepted')b.remove()});
const originalDraw=drawEditor;drawEditor=()=>{originalDraw();if(!ED.id){const old=$('sheetIn').querySelector('#edTable');if(old){const select=document.createElement('select');select.id='edTable';for(const t of snapshot.tables){const option=document.createElement('option');option.value=t.label;option.textContent=t.label;option.selected=t.label===String(ED.table);select.append(option)}old.replaceWith(select)}const field=document.createElement('label');field.textContent=ST.lang==='ru'?'Чек':'Hóa đơn';const input=document.createElement('input');input.id='edCheck';input.maxLength=80;input.value=ED.check||'Общий счёт';input.oninput=()=>ED.check=input.value;field.append(input);$('sheetIn').querySelector('.ed').before(field)}};
const baseDraw=drawEditor;drawEditor=()=>{baseDraw();const sheet=$('sheetIn'),picker=sheet?.querySelector('#edPick .picker');if(!picker)return;
 sheet.classList.add('ed-editor');ED.categoryOpen=ED.categoryOpen||{};
 const groups=new Map();for(const button of [...picker.querySelectorAll('[data-add]')]){const item=M[button.dataset.add],parts=String(item?.externalKey||'').split('|'),key=parts[0]==='sunsea'||parts[0]==='chez'?parts[1]:parts[0],category=CATALOG_CATEGORIES[key],groupKey=category?key:item?.st==='b'?'other-bar':'other-kitchen';if(!groups.has(groupKey))groups.set(groupKey,{name:category?.[ST.lang]||category?.ru||(ST.lang==='ru'?(item?.st==='b'?'Напитки':'Блюда'):(item?.st==='b'?'Đồ uống':'Món ăn')),buttons:[]});groups.get(groupKey).buttons.push(button);
 const number=window.sunSeaPrintedNumbers?.[item?.externalKey];if(number){const badge=document.createElement('span');badge.className='ed-item-number';badge.textContent='№ '+number;button.prepend(badge)}}
 picker.replaceChildren();picker.classList.add('ed-category-list');for(const [key,group] of groups){const section=document.createElement('details');section.className='ed-category';section.dataset.category=key;section.open=ED.categoryOpen[key]??key===groups.keys().next().value;const summary=document.createElement('summary');summary.innerHTML='<strong>'+esc(group.name)+'</strong><span>'+group.buttons.length+'</span>';const grid=document.createElement('div');grid.className='ed-category-grid';grid.append(...group.buttons);section.append(summary,grid);section.addEventListener('toggle',()=>{if(!ED.search)ED.categoryOpen[key]=section.open});picker.append(section)}
 const search=document.createElement('input');search.type='search';search.className='ed-menu-search';search.placeholder=ST.lang==='ru'?'Найти блюдо по названию…':'Tìm món…';search.setAttribute('aria-label',search.placeholder);search.value=ED.search||'';picker.before(search);const empty=document.createElement('p');empty.className='ed-search-empty';empty.textContent=ST.lang==='ru'?'Блюдо не найдено':'Không tìm thấy món';picker.after(empty);
 const filter=()=>{ED.search=search.value;const q=search.value.trim().toLocaleLowerCase();let count=0;picker.querySelectorAll('.ed-category').forEach(section=>{let visible=0;section.querySelectorAll('[data-add]').forEach(button=>{const item=M[button.dataset.add],match=!q||[item?.vi,item?.ru,item?.en,window.sunSeaPrintedNumbers?.[item?.externalKey]].some(n=>String(n||'').toLocaleLowerCase().includes(q));button.hidden=!match;if(match){visible++;count++}});section.hidden=!visible;if(q&&visible)section.open=true;else if(!q)section.open=ED.categoryOpen[section.dataset.category]??section.dataset.category===groups.keys().next().value});empty.hidden=!!count};search.oninput=filter;search.onkeydown=e=>{if(e.key==='Enter'){e.preventDefault();picker.querySelector('[data-add]:not([hidden])')?.click()}};filter();
 sheet.querySelectorAll('[data-note]').forEach((input,k)=>{input.maxLength=300;input.id='edNote'+k;const label=document.createElement('label');label.className='ed-note-label';label.htmlFor=input.id;label.textContent=ST.lang==='ru'?'Комментарий к блюду':'Ghi chú món';input.before(label)});
 const header=sheet.firstElementChild,lines=sheet.querySelector('.ed'),footer=sheet.lastElementChild,content=document.createElement('div'),cart=document.createElement('section');content.className='ed-editor-scroll';cart.className='ed-cart';cart.setAttribute('aria-label',ST.lang==='ru'?'Текущий заказ':'Đơn hiện tại');for(const node of [...sheet.children])if(node!==header&&node!==lines&&node!==footer)content.append(node);const heading=document.createElement('div');heading.className='ed-cart-heading';heading.innerHTML='<strong>'+(ST.lang==='ru'?'Текущий заказ':'Đơn hiện tại')+'</strong><span>'+ED.items.reduce((n,i)=>n+i.qty,0)+'</span>';cart.append(heading,lines,footer);sheet.append(content,cart)};
const originalOpen=openEditor;openEditor=(id,parent)=>{originalOpen(id,parent);if(ED){ED.check=parent?.check||'Общий счёт';const input=$('sheetIn').querySelector('#edCheck');if(input)input.value=ED.check}};
const originalClose=closeEditor;closeEditor=()=>{$('sheetIn')?.classList.remove('ed-editor');originalClose()};
if(manual)manual.onclick=()=>openEditor(null,{table:snapshot.tables[0]?.label,lang:'vi'});
const ensureBill=openBillSheet;openBillSheet=id=>{$('sheetIn')?.classList.remove('ed-editor');ensureBill(id);const sheet=$('sheetIn'),close=$('bClose');if(close&&billOrders(id).some(o=>o.status!=='served')){close.remove();sheet?.querySelector('.pmbox')?.remove();const note=document.createElement('p');note.className='flow-bill-pending';note.textContent=ST.lang==='ru'?'Счёт уже можно показать гостю. Оплату и закрытие стола отметьте после подачи всех позиций.':'Có thể cho khách xem hóa đơn ngay. Ghi nhận thanh toán và đóng bàn sau khi phục vụ đủ món.';sheet?.querySelector('.btot')?.after(note)}if(ST.bills[id]?.closed){$('bClose')?.remove();$('bMore')?.remove();sheet?.querySelector('.pmbox')?.remove()}};
el.querySelectorAll('[data-ht]').forEach(b=>b.onclick=()=>{const tb=snapshot.tables.find(t=>t.label===b.dataset.ht),bl=Object.values(ST.bills).find(x=>!x.closed&&x.tableId===tb?.id);if(bl)openBillSheet(bl.id);else openEditor(null,{table:tb.label,lang:'vi',no:null})});
el.querySelectorAll('[data-hall-qr]').forEach(b=>b.onclick=()=>options.onQr?.(b.dataset.hallQr));

return {isEditing:()=>!$('sheet').hidden,close:closeEditor};
}
return {render:renderFlow,stop(){overlay?.remove();overlay=null}};})();
'''
if __name__=='__main__':(HERE/'flow-ui.js').write_text(build(),encoding='utf-8')
