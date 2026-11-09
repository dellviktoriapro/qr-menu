# Compile original waiter, kitchen, bill and editor functions against server callbacks.
from pathlib import Path
HERE=Path(__file__).resolve().parent
def build():
 s=(HERE.parent/'ops/tpl.html').read_text(encoding='utf-8')
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
 chunks[-2]=chunks[-2].replace('$("bClose").onclick=e=>','$("bClose").onclick=async e=>').replace('closeBill(bid,{...PM});closeEditor();','if(!await closeBill(bid,{...PM}))return;closeEditor();')
 return r'''// Generated from the original ops/tpl.html. Do not edit generated UI.
window.staffFlow=(()=>{const preferences=new Map();let overlay=null;
function renderFlow(el,options){
const {snapshot,cafe}=options,mapped=staffServerState.mapSnapshot(snapshot),M=mapped.menu;let ST=mapped.state;const pref=preferences.get(cafe.id+':'+ST.me)||{};Object.assign(ST,pref);if(options.lang)ST.lang=options.lang;ST.role=options.screen==='prep'?'kitchen':'waiter';ST.split=options.screen==='workbench';ST.ktab=ST.ktab||'all';ST.shift[ST.me]=snapshot.shifts?.[ST.me]||false;
let accept,toKitchen,kReady,kItem,served,closeBill;
const stopMenu=snapshot.menu.filter(i=>['owner','manager','waiter'].includes(snapshot.me.role)||i.station===snapshot.me.role),CMENU=[['menu','Thực đơn','Меню',stopMenu.map(i=>[i.names?.vi||i.names?.ru||'',i.names?.ru||i.names?.vi||''])]];
const MENU=Object.values(M).filter(m=>m.active&&m.p!==null&&!snapshot.menu.find(i=>i.id===m.id)?.stopped),PH={},NEW_LATE_MS=45000,READY_ESC_MS=40000,REORDER_MS=40000;
const WAITERS=()=>ST.staff.filter(x=>x.status==='active'&&(['owner','manager','waiter'].includes(x.role)||x.id===ST.me));
if(!overlay){overlay=document.createElement('div');overlay.className='original-flow flow-overlay';overlay.innerHTML='<section id="flow-sheet" class="sheet" hidden><div class="sheetin" id="flow-sheetIn"></div></section><div id="flow-toasts"></div>';document.body.append(overlay)}
const $=id=>overlay.querySelector('#flow-'+id)||el.querySelector('#'+id);
overlay.querySelector('#flow-sheet').onclick=e=>{if(e.target===e.currentTarget){e.currentTarget.hidden=true}};
const save=()=>preferences.set(cafe.id+':'+ST.me,Object.fromEntries(['lang','wtab','ktab','mineOnly','tview','stopQ'].map(k=>[k,ST[k]]))),render=()=>{save();options.onRender()},toast=(msg,sub)=>options.onNotice(msg+(sub?' · '+sub:''));
const mutate=()=>{throw Error('LOCAL_BUSINESS_MUTATION_FORBIDDEN')},staffBy=id=>ST.staff.find(x=>x.id===id),readyTargets=o=>['owner','manager'].includes(snapshot.me.role)?[ST.me]:[o.waiter],showsForMe=()=>true;
'''+'\n'.join(chunks)+r'''
// Authoritative commands replace all business mutations; preferences remain local.
setStop=(key,on)=>{const item=stopMenu[Number(key.split('|')[1])];if(item)return options.onCommand('stop',{item_id:item.id,stopped:on})};
const originalStop=rStop;rStop=host=>{const prior=ST.stop;ST.stop=Object.fromEntries(stopMenu.map((i,n)=>[i,n]).filter(([i])=>i.stopped).map(([i,n])=>['menu|'+n,{at:0}]));originalStop(host);if(snapshot.me.role==='waiter'){host.querySelectorAll('[data-stop]').forEach(b=>b.disabled=true);const text=host.querySelector('p');if(text)text.textContent=ST.lang==='ru'?'Доступность меняет кухня, бар или управляющий.':'Bếp, bar hoặc quản lý cập nhật tình trạng món.'}ST.stop=prior};
const command=async(a,b)=>options.onCommand(a,b);
accept=id=>command('guest_accept',{submission_id:id});toKitchen=id=>command('send',staffServerState.orderCommand(ST,'send',id).b);
kReady=(id,station)=>command('station_ready',staffServerState.orderCommand(ST,'station_ready',id,{station}).b);
kItem=(id,index)=>{const i=ST.orders.find(o=>o.id===id)?.items[index];if(i)return command('item_ready',staffServerState.orderCommand(ST,'item_ready',id,{item_id:i.id,ready:!i.done}).b)};
served=(id,station)=>command('serve',staffServerState.orderCommand(ST,'serve',id,{station}).b);
closeBill=(id,pays)=>command('bill_close',staffFlowContract.closeBody(snapshot,id,pays));
openTipQr=()=>options.onProfile();
commitED=async send=>{syncED();const draft=structuredClone(ED);if(!draft.items.length)return;draft.items=draft.items.map(i=>({...i,serverId:M[i.mid]?.serverId}));const request=staffFlowContract.editBody(snapshot,draft,send);if(await command(request.a,request.b)){closeEditor();ST.wtab='cooking';save();options.onRender()}};
hallMap=()=>'<div class="hall"><h3>'+esc(ST.lang==='ru'?'Столы кафе':'Bàn trong quán')+'</h3><div class="tgrid">'+snapshot.tables.map(tb=>{const b=Object.values(ST.bills).find(b=>!b.closed&&b.tableId===tb.id),total=b?billTotal(b.id):0;return '<button type="button" class="tcard" data-ht="'+esc(tb.label)+'"><b>'+esc(t('table'))+' '+esc(tb.label)+'</b><span>'+tb.seats+' '+(ST.lang==='ru'?'мест':'chỗ')+'</span><span>'+vnd(total)+'</span></button>'}).join('')+'</div></div>';
el.querySelectorAll?.('[data-a=accept]');
// Pending guest submissions retain their exact server ID, quotes, notes and check names.
for(const g of options.incoming||[]){const items=[];for(const ck of g.checks)for(const [n,i] of ck.items.entries()){const mid='incoming:'+g.id+':'+ck.id+':'+n;M[mid]={...i.names,p:i.price};items.push({mid,qty:i.quantity,note:(g.checks.length>1?'Чек '+ck.label+'. ':'')+(i.note||'')})}ST.orders.push({id:g.id,no:g.id.slice(0,8),status:'new',table:g.table,items,createdAt:Date.parse(g.created_at),check:g.checks.length===1?g.checks[0].label:'',src:'qr',lang:g.lang,wishes:[],seed:false})}
for(const q of options.services||[]){const b=ST.bills[q.bill_id];if(b){b.req={at:Date.parse(q.created_at),pay:q.method==='qr_transfer'?'qr':q.method,check:q.check,paid:q.paid};(b.reqs||=[]).push(b.req)}}
el.classList.add('original-flow');
if(options.screen==='menu'){rStop(el)}else if(options.screen==='workbench'){el.innerHTML='<section><h2>'+esc(ST.lang==='ru'?'Заказы':'Đơn hàng')+'</h2><div id=\"flow-waiter-pane\"></div></section><section><h2>'+esc(ST.lang==='ru'?'Кухня и бар':'Bếp & Bar')+'</h2><div id=\"flow-prep-pane\"></div></section>';el.classList.add('flow-workbench');rWaiter(el.querySelector('#flow-waiter-pane'));rKitchen(el.querySelector('#flow-prep-pane'))}else if(options.screen==='prep'){if(['bar','kitchen'].includes(snapshot.me.role)&&ST.ktab!=='stop')ST.ktab=snapshot.me.role;rKitchen(el);if(['bar','kitchen'].includes(snapshot.me.role))el.querySelectorAll('[data-kt]').forEach(b=>{if(![snapshot.me.role,'stop'].includes(b.dataset.kt))b.remove()})}
else rWaiter(el);
el.querySelectorAll('[data-a=accept]').forEach(b=>{const decline=document.createElement('button');decline.type='button';decline.className='btn ghost sm';decline.textContent=ST.lang==='ru'?'Отклонить':'Từ chối';decline.onclick=()=>{if(confirm(ST.lang==='ru'?'Отклонить этот заказ?':'Từ chối đơn này?'))options.onCommand('guest_reject',{submission_id:b.dataset.id})};b.after(decline)});
const select=el.querySelector('#meSel');if(select){select.value=ST.me;select.disabled=true;select.setAttribute('aria-label',ST.lang==='ru'?'Ваш аккаунт':'Tài khoản của bạn')}
const shift=el.querySelector('#shiftBtn');if(shift)shift.onclick=()=>options.onShift(!ST.shift[ST.me]);
const manual=el.querySelector('#manualBtn');if(manual)manual.disabled=snapshot.me.role==='waiter'&&!ST.shift[ST.me];
// Only authenticated assignment may edit a draft; others can view status.
el.querySelectorAll('[data-a=edit],[data-a=kitchen],[data-a=served]').forEach(b=>{const o=ST.orders.find(o=>o.id===b.dataset.id);if(snapshot.me.role==='waiter'&&o?.waiter!==ST.me)b.disabled=true});
el.querySelectorAll('[data-a=edit]').forEach(b=>{const o=ST.orders.find(o=>o.id===b.dataset.id);if(o?.status!=='accepted')b.remove()});
const originalDraw=drawEditor;drawEditor=()=>{originalDraw();if(!ED.id){const old=$('sheetIn').querySelector('#edTable');if(old){const select=document.createElement('select');select.id='edTable';for(const t of snapshot.tables){const option=document.createElement('option');option.value=t.label;option.textContent=t.label;option.selected=t.label===String(ED.table);select.append(option)}old.replaceWith(select)}const field=document.createElement('label');field.textContent=ST.lang==='ru'?'Чек':'Hóa đơn';const input=document.createElement('input');input.id='edCheck';input.maxLength=80;input.value=ED.check||'Общий счёт';input.oninput=()=>ED.check=input.value;field.append(input);$('sheetIn').querySelector('.ed').before(field)}};
const originalOpen=openEditor;openEditor=(id,parent)=>{originalOpen(id,parent);if(ED){ED.check=parent?.check||'Общий счёт';const input=$('sheetIn').querySelector('#edCheck');if(input)input.value=ED.check}};
if(manual)manual.onclick=()=>openEditor(null,{table:snapshot.tables[0]?.label,lang:'vi'});
const ensureBill=openBillSheet;openBillSheet=id=>{ensureBill(id);const close=$('bClose');if(close&&billOrders(id).some(o=>o.status!=='served')){close.disabled=true;close.title=ST.lang==='ru'?'Сначала подайте все позиции':'Phục vụ tất cả món trước'}if(ST.bills[id]?.closed){$('bClose')?.remove();$('bMore')?.remove()}};
el.querySelectorAll('[data-ht]').forEach(b=>b.onclick=()=>{const tb=snapshot.tables.find(t=>t.label===b.dataset.ht),bl=Object.values(ST.bills).find(x=>!x.closed&&x.tableId===tb?.id);if(bl)openBillSheet(bl.id);else openEditor(null,{table:tb.label,lang:'vi',no:null})});
if(ST.wtab==='tables'&&options.onQr){const box=document.createElement('div');box.className='row';for(const tb of snapshot.tables){const b=document.createElement('button');b.type='button';b.textContent='QR · '+t('table')+' '+tb.label;b.onclick=()=>options.onQr(tb.id);box.append(b)}el.append(box)}

return {isEditing:()=>!$('sheet').hidden,close:closeEditor};
}
return {render:renderFlow,stop(){overlay?.remove();overlay=null}};})();
'''
if __name__=='__main__':(HERE/'flow-ui.js').write_text(build(),encoding='utf-8')
