"""Reuse owner analytics renderers from the ORIGINAL staff app; no second analytics UI."""
from pathlib import Path
HERE=Path(__file__).resolve().parent

def build():
 s=(HERE.parent/'ops/tpl.html').read_text(encoding='utf-8')
 strings=s[s.index('const S='):s.index('const G=')]
 agg=s[s.index('function agg0()'):s.index('function aggOrder(')]
 helpers=s[s.index('function keysIn('):s.index('function rOwner(el)')]
 a=helpers.index('function fmtK(');b=helpers.index('function delta(',a)
 helpers=helpers[:a]+'''function fmtK(k,o){return new Date(k+'T12:00:00Z').toLocaleDateString(ST.lang==='ru'?'ru-RU':'vi-VN',{timeZone:'UTC',...(o||{day:'numeric',month:'short'})})}\n'''+helpers[b:]
 renderer=s[s.index('function rOwner(el)'):s.index('/* ---------- top controls ---------- */')]
 settings=next(line for line in renderer.splitlines() if 'esc(t("oSettings"))' in line)
 renderer=renderer.replace(settings,'   `;')
 renderer='\n'.join(line for line in renderer.splitlines() if 'querySelectorAll("input[name=notify]")' not in line)
 renderer=renderer.replace('acc:mean(x.acc),late:x.late','acc:mean(x.acc),hasAcc:x.acc[1]>0,late:x.late')
 renderer=renderer.replace('${Math.round(mean(A.acc))}', '${A.acc[1]?Math.round(mean(A.acc)):"—"}').replace('${mean(A.cook).toFixed(1)}','${A.cook[1]?mean(A.cook).toFixed(1):"—"}').replace('${p.n?Math.round(p.acc)', '${p.hasAcc?Math.round(p.acc)')
 renderer=renderer.replace('s.role==="waiter"&&s.status', '(s.role==="waiter"||A.w[s.id])&&s.status')
 renderer=renderer.replace('Math.max(1,...Object.values(hrs))','Math.max(1,...Object.values(hrs).map(Math.abs))').replace('Math.max(1,...Object.values(pmS))','Math.max(1,...Object.values(pmS).map(Math.abs))').replace('perDay.map(([,d])=>d.rev)','perDay.map(([,d])=>Math.abs(d.rev))').replace('${d.rev/dMax*100}', '${Math.abs(d.rev)/dMax*100}').replace('${v/hMax*100}', '${Math.abs(v)/hMax*100}').replace('Math.max(4,pmS[k]/pmMax*100)','Math.max(4,Math.abs(pmS[k])/pmMax*100)')
 renderer=renderer.replace('if(!i.value)return;', 'if(!i.value||!i.checkValidity())return;')
 # Daily chart dates are calendar labels rather than fixed UTC+7 time arithmetic.
 renderer=renderer.replace('new Date(kts(k)+7*3600e3).getUTCDate()','Number(k.slice(8))')
 return '''// Generated from _src/ops/tpl.html by build-report.py. Edit source/template or builder.
window.staffReport=(()=>{const preferences=new Map();
function selected(cafe){return preferences.get(cafe.id)||{k:'today'}}
function range(cafe){return staffReportCore.range(selected(cafe),cafe.timezone||'Asia/Ho_Chi_Minh')}
function renderReport(el,options){
const {cafe,snapshot}=options,timezone=cafe.timezone||'Asia/Ho_Chi_Minh';let report=options.report;const requested=range(cafe);if(report&&(Date.parse(report.from)!==Date.parse(requested.f)||Date.parse(report.to)!==Date.parse(requested.t)))report=null;
const ST={lang:options.lang||'ru',oper:{...selected(cafe)},bills:Object.fromEntries((snapshot.bills||[]).map(b=>[b.id,{closed:b.status!=='open'}])),staff:(snapshot.staff||[]).map(s=>({id:s.id,name:s.name,role:s.role,status:s.active?'active':'blocked'})),shift:snapshot.shifts||{}};
for(const [id,name] of Object.entries(report?.staff_names||{}))if(!ST.staff.some(s=>s.id===id))ST.staff.push({id,name,role:'waiter',status:'former'});
const CAFE={file:cafe.slug||('cafe-'+cafe.id.slice(0,8))},DAY=86400000,HIST_DAYS=179,PAYS=['cash','card','qr'];
const dkey=ts=>staffReportCore.dayKey(ts,timezone),addD=staffReportCore.addDay,kts=k=>Date.parse(staffReportCore.midnight(k,timezone));
const periodKeys=()=>staffReportCore.periodKeys(ST.oper,timezone);
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const vnd=n=>new Intl.NumberFormat('vi-VN').format(Math.round(n))+' '+(cafe.currency==='VND'?'₫':cafe.currency),short=n=>new Intl.NumberFormat(ST.lang==='ru'?'ru-RU':'vi-VN',{notation:'compact',maximumFractionDigits:1}).format(n);
const nm=(id,l)=>report?.item_names?.[id]?.[l]||report?.item_names?.[id]?.vi||snapshot.menu?.find(i=>i.id===id)?.names?.[l]||'—';
const save=()=>preferences.set(cafe.id,{...ST.oper}),render=()=>options.onPeriod();
const dayAgg=k=>structuredClone(report?.days?.[k]||agg0());
'''+strings+'''
S.ru.histNote='Сохранённые данные кафе. Оплаты отмечены сотрудниками; банк не подключён. Суммы заказов используют исторические цены.';
S.ru.noToday='За выбранный день ещё нет заказов.';S.ru.oRev='Отмеченные оплаты';S.ru.oRevS='Сумма заказов';S.ru.oHours='Оплаты по часам';S.ru.oPay='Отмеченные способы оплаты';
S.vi.histNote='Dữ liệu máy chủ. Nhân viên ghi nhận thanh toán; không kết nối ngân hàng.';
const LANGNAME={ru:'Русский',vi:'Tiếng Việt',en:'English',de:'Deutsch',ko:'한국어',zh:'中文'},t=k=>S[ST.lang][k];
'''+agg+helpers+renderer+'''
el.classList.add('original-report');rOwner(el);
if(!report){el.querySelectorAll(':scope > :not(.pbar)').forEach(n=>n.remove());const loading=document.createElement('p');loading.setAttribute('role','status');loading.textContent='Загружаем отчёт с сервера…';el.append(loading)}
}
return {range,render:renderReport};})();
'''

if __name__=='__main__':
 target=HERE/'report-ui.js';target.write_text(build(),encoding='utf-8');print('Built original owner analytics:',target.name)
