"""Compile the ORIGINAL staff management and tip QR markup with server callbacks."""
from pathlib import Path
HERE=Path(__file__).resolve().parent

def build():
 s=(HERE.parent/'ops/tpl.html').read_text(encoding='utf-8')
 strings=s[s.index('const S='):s.index('const G=')]
 renderer=s[s.index('function rStaff(el)'):s.index('function rJoin(el)')]
 renderer=renderer[:renderer.index('  const q=')]+ '\n}\n'
 line=next(x for x in renderer.splitlines() if 'esc(t("qrTitle"))' in x)
 renderer=renderer.replace(line,'''    <div class="card staff-invite-card"><h3>${esc(t("qrTitle"))}</h3><p>Персональная ссылка для сотрудника. Действует 48 часов; доступ появляется после вашего одобрения.</p><form id="staff-invite-form"><label>Имя сотрудника<input name="name" required maxlength="100" autocomplete="off" value="${esc(currentLink?.name||'')}"></label><button type="submit">${currentLink?'Перевыпустить приглашение':'Создать приглашение'}</button></form>${currentLink?.url?`<div class="qrbox"><div id="qrJoin" class="qr"></div><div class="qrt"><strong>${esc(currentLink.name)}</strong><p>До ${esc(new Date(currentLink.expires_at).toLocaleString('ru-RU'))}</p><button type="button" id="staff-copy-link">Скопировать ссылку</button></div></div>`:''}<div id="staff-invites"></div></div>''')
 renderer=renderer.replace('aria-label="role"','aria-label="Роль: ${esc(x.name)}"')
 # A flex container belongs inside a cell; applying flex to td breaks table row borders.
 renderer=renderer.replace('<td class="acts">','<td class="staff-actions-cell"><div class="acts">').replace('</button>`}</td></tr>','</button>`}</div></td></tr>')
 renderer=renderer.replace('<span class="pill st-ready">${esc(t("onShift"))}</span>','<span class="pill staff-shift-badge">${esc(t("onShift"))}</span>')
 renderer=renderer.replace('src="${ST.payQr}"','src="${esc(ST.payQr)}"')
 tip=s[s.index('function openTipQr()'):s.index('let ED=null;')]
 tipmarkup=tip[tip.index('   <div class="payqr">'):tip.index('`;')]
 return '''// Generated from the original ops/tpl.html staff UI. Edit builder/source.
window.staffUi=(()=>{const links=new Map();
function renderStaff(el,options){
 const {cafe,data}=options,key=cafe.id+':'+data.me,currentLink=links.get(key),now=Date.now();
 const ST={lang:options.lang||'ru',staff:data.members.map(x=>({id:x.id,name:x.name,phone:x.phone||'',role:x.role,status:x.deleted_at?'deleted':x.active?'active':'blocked',tipQr:x.tip_url||''})).concat(data.invites.filter(i=>!i.revoked_at&&!i.accepted_at&&Date.parse(i.expires_at)>now&&['pending','approving'].includes(i.state)).map(i=>({id:i.request_id,name:i.name,phone:(i.email.startsWith('staff.')?'Персональная ссылка':i.email)+(i.phone?' · '+i.phone:''),role:'waiter',status:'pending',createdAt:Date.parse(i.request_at)}))),payQr:data.settings.payment_url||'',rev:data.settings.reviews||{},shift:Object.fromEntries(data.members.map(x=>[x.id,!!x.on_shift])),log:data.events.map(e=>({at:Date.parse(e.created_at),k:e.kind,who:e.target_id,extra:e.details.role||e.details.email||''})),device:data.me};
 const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
'''+strings+'''
 S.ru.payQrH='Банковский QR для оплаты в вашем кафе. Банк и касса не подключаются.';S.ru.r_kitchen='Кухня';S.ru.r_bar='Бар';S.vi.r_kitchen='Bếp';S.vi.r_bar='Bar';const t=k=>S[ST.lang][k],ROLE_OPTS=['waiter','kitchen','bar','manager'],roleName=r=>t('r_'+r),wname=id=>ST.staff.find(s=>s.id===id)?.name||'—';
'''+renderer+'''
 el.classList.add('original-report','original-staff');rStaff(el);
 const invoke=(command,body)=>options.onAction(command,body);
 const form=el.querySelector('#staff-invite-form');form.onsubmit=async e=>{e.preventDefault();const f=new FormData(form),name=f.get('name').trim(),email='';const result=await invoke('invite_create',{name,mode:'link',...(currentLink?.id?{replace_id:currentLink.id}:{})});if(result?.token){links.set(key,{name,email,id:result.id,expires_at:result.expires_at,url:'https://dellviktoriapro.github.io/qr-menu/app/#staff='+result.token});options.onRefresh()}else if(result?.reissue_required){links.set(key,{name,email,id:result.id,expires_at:result.expires_at});options.onNotice('Приглашение создано, но ссылка не была получена. Перевыпустите её — старая будет отменена.');options.onRefresh()}};
 if(currentLink){new QRCode(el.querySelector('#qrJoin'),{text:currentLink.url,width:164,height:164,colorDark:'#152235',colorLight:'#ffffff',correctLevel:QRCode.CorrectLevel.M});el.querySelector('#staff-copy-link').onclick=async()=>{try{await navigator.clipboard.writeText(currentLink.url);options.onNotice('Ссылка скопирована. Отправьте её сотруднику.')}catch{options.onNotice('Не удалось скопировать ссылку. Используйте QR.') }}}
 const invites=el.querySelector('#staff-invites');invites.innerHTML=data.invites.filter(i=>!i.revoked_at&&!i.accepted_at&&Date.parse(i.expires_at)>now).map(i=>`<div class="staff-invite-row"><span>${esc(i.name)} · ${esc(i.email.startsWith('staff.')?'Персональная ссылка':i.email)}</span><button type="button" data-revoke="${i.id}">Отменить приглашение</button></div>`).join('');
 invites.querySelectorAll('[data-revoke]').forEach(b=>b.onclick=()=>invoke('invite_revoke',{invite_id:b.dataset.revoke}));
 el.querySelector('#revSave').onclick=()=>invoke('reviews',{google:el.querySelector('#revG').value.trim(),tripadvisor:el.querySelector('#revTa').value.trim()});
 el.querySelector('#payQrIn').onchange=e=>options.onUpload('payment',e.target.files[0]);
 const remove=el.querySelector('#payQrDel');if(remove)remove.onclick=()=>{if(!remove.dataset.arm){remove.dataset.arm='1';remove.textContent='Точно убрать QR?';return}invoke('asset_remove',{kind:'payment'})};
 el.querySelectorAll('[data-ok]').forEach(b=>b.onclick=()=>options.onApprove(b.dataset.ok,el.querySelector(`[data-rrole="${b.dataset.ok}"]`).value));
 el.querySelectorAll('[data-rej]').forEach(b=>b.onclick=()=>invoke('reject',{pending_id:b.dataset.rej}));
 const member=(id,role,active,deleted=false)=>invoke('member_set',{user_id:id,role,active,deleted});
 el.querySelectorAll('[data-blk]').forEach(b=>b.onclick=()=>{const x=ST.staff.find(s=>s.id===b.dataset.blk);member(x.id,x.role,x.status==='blocked')});
 el.querySelectorAll('[data-del]').forEach(b=>b.onclick=()=>{if(!b.dataset.arm){b.dataset.arm='1';b.textContent='Точно удалить?';return}const x=ST.staff.find(s=>s.id===b.dataset.del);member(x.id,x.role,false,true)});
 el.querySelectorAll('[data-role-s]').forEach(b=>b.onchange=()=>{const x=ST.staff.find(s=>s.id===b.dataset.roleS);member(x.id,b.value,x.status==='active')});
 if(data.role!=='owner'){el.querySelector('.staff-invite-card')?.parentElement.remove();el.querySelectorAll('[data-blk],[data-del],[data-role-s]').forEach(n=>{if(n.tagName==='SELECT'){const text=document.createElement('span');text.textContent=n.options[n.selectedIndex]?.text||'';n.replaceWith(text)}else n.remove()})}
 const settings=document.createElement('div');settings.className='card';settings.innerHTML=`<h3>${esc(t('oSettings'))}</h3>${[['taker',t('nTaker')],['all',t('nAll')],['esc',t('nEsc')]].map(([k,label])=>`<label class="staff-radio"><input type="radio" name="staff-notify" value="${k}" ${data.settings.notify===k?'checked':''}>${esc(label)}</label>`).join('')}`;el.append(settings);settings.querySelectorAll('input').forEach(i=>i.onchange=()=>invoke('notification',{notify:i.value}));
}
function renderProfile(el,options){const {data}=options,me=data.members.find(x=>x.id===data.me);if(!me)return;el.classList.add('original-report','original-staff');const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
'''+strings+'''
 S.ru.tipQrH='Ваш банковский QR для прямых переводов чаевых.';const t=k=>S.ru[k];me.tipQr=me.tip_url||'';
 el.innerHTML=`<div class="card"><div class="row"><h2>${esc(me.name)}</h2><button type="button" id="staff-shift">${me.on_shift?'Закончить смену':'Начать смену'}</button></div></div><div class="card"><h3>${esc(t('tipQrT'))}</h3>
'''+tipmarkup+'''
</div>`;
 el.querySelector('#staff-shift').onclick=()=>options.onAction('shift',{on_shift:!me.on_shift});
 el.querySelector('#tqIn').onchange=e=>options.onUpload('tip',e.target.files[0]);
 const remove=el.querySelector('#tqDel');if(remove)remove.onclick=()=>options.onAction('asset_remove',{kind:'tip'});
}
return {render:renderStaff,profile:renderProfile,acceptInvite(cafe,actor,data){if(data.token)links.set(cafe+':'+actor,{name:data.name,email:data.email,expires_at:data.expires_at,url:'https://dellviktoriapro.github.io/qr-menu/app/#staff='+data.token})},reset(){links.clear()}};})();
'''
if __name__=='__main__':(HERE/'staff-ui.js').write_text(build(),encoding='utf-8')
