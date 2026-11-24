"""Compile the ORIGINAL staff management and tip QR markup with server callbacks."""
from pathlib import Path
HERE=Path(__file__).resolve().parent

def build():
 s=(HERE.parent/'ops/tpl.html').read_text(encoding='utf-8')
 strings=s[s.index('const S='):s.index('const G=')]
 renderer=s[s.index('function rStaff(el)'):s.index('function rJoin(el)')]
 renderer=renderer[:renderer.index('  const q=')]+ '\n}\n'
 line=next(x for x in renderer.splitlines() if 'esc(t("qrTitle"))' in x)
 renderer=renderer.replace(line,'''    <div class="card staff-invite-card"><h3>${esc(t("qrTitle"))}</h3><p>Персональная ссылка для сотрудника. Действует 48 часов; доступ появляется после вашего одобрения.</p><form id="staff-invite-form"><label>Имя сотрудника<input name="name" required maxlength="100" autocomplete="off" value="${esc(inviteDraft?.name??currentLink?.name??'')}"></label><div class="staff-invite-roles"><span>Роли сотрудника</span><details class="staff-role-picker staff-invite-role-picker"><summary>${esc(inviteRoles.map(roleName).join(', ')||'Выберите роли')}</summary><div popover="auto"><fieldset><legend>Роли сотрудника</legend>${ROLE_OPTS.map(role=>`<label><input type="checkbox" name="roles" value="${role}" ${inviteRoles.includes(role)?'checked':''}>${esc(roleName(role))}</label>`).join('')}</fieldset><button type="button" data-save-invite-roles>Сохранить</button></div></details></div><button type="submit">${currentLink?'Перевыпустить приглашение':'Создать приглашение'}</button></form>${currentLink?.url?`<div class="qrbox"><div id="qrJoin" class="qr"></div><div class="qrt"><strong>${esc(currentLink.name)}</strong><p>${esc((currentLink.roles||[currentLink.role||'waiter']).map(roleName).join(', '))} · До ${esc(new Date(currentLink.expires_at).toLocaleString('ru-RU'))}</p><button type="button" id="staff-copy-link">Скопировать ссылку</button><span id="staff-copy-status" role="status" aria-live="polite"></span></div></div>`:''}<div id="staff-invites"></div></div>''')
 settings_markup=renderer[renderer.index('<div class="card"><h3>${esc(t("payQrT"))}'):renderer.index('   <div class="two">')]
 renderer=renderer.replace(settings_markup,'')
 renderer=renderer.replace('aria-label="role"','aria-label="Роль: ${esc(x.name)}"')
 renderer=renderer.replace('<select data-rrole="${x.id}" aria-label="Роль: ${esc(x.name)}">','<select data-rrole="${x.id}" aria-label="Роль: ${esc(x.name)}" ${x.assignedRole?"disabled":""}>')
 renderer=renderer.replace('<option value="${r}">${esc(roleName(r))}</option>','<option value="${r}" ${x.role===r?"selected":""}>${esc(roleName(r))}</option>')
 import re
 renderer=re.sub(r'<select data-role-s=.*?</select>', '${rolePicker(x)}', renderer)
 # A flex container belongs inside a cell; applying flex to td breaks table row borders.
 renderer=renderer.replace('<td class="acts">','<td class="staff-actions-cell"><div class="acts">').replace('</button>`}</td></tr>','</button>`}</div></td></tr>')
 renderer=renderer.replace('<span class="pill st-ready">${esc(t("onShift"))}</span>','<span class="pill staff-shift-badge">${esc(t("onShift"))}</span>')
 renderer=renderer.replace('src="${ST.payQr}"','src="${esc(ST.payQr)}"')
 settings_markup=settings_markup.replace('src="${ST.payQr}"','src="${esc(ST.payQr)}"')
 tip=s[s.index('function openTipQr()'):s.index('let ED=null;')]
 tipmarkup=tip[tip.index('   <div class="payqr">'):tip.index('`;')]
 return '''// Generated from the original ops/tpl.html staff UI. Edit builder/source.
window.staffUi=(()=>{const links=new Map(),inviteDrafts=new Map();
function renderStaff(el,options){
  const {cafe,data}=options,key=cafe.id+':'+data.me,now=Date.now(),savedLink=links.get(key),serverLink=data.invites.find(i=>i.id===savedLink?.id),currentLink=savedLink&&Date.parse(savedLink.expires_at)>now&&(!serverLink||(!serverLink.revoked_at&&!serverLink.accepted_at))?savedLink:null;
  const inviteDraft=inviteDrafts.get(key),inviteRoles=inviteDraft?.roles||currentLink?.roles||[currentLink?.role||'waiter'];
  const ST={lang:options.lang||'ru',staff:data.members.map(x=>({id:x.id,name:x.name,phone:x.phone||'',role:x.role,status:x.deleted_at?'deleted':x.active?'active':'blocked',tipQr:x.tip_url||''})).concat(data.invites.filter(i=>!i.revoked_at&&!i.accepted_at&&Date.parse(i.expires_at)>now&&['pending','approving'].includes(i.state)).map(i=>({id:i.request_id,name:i.name,phone:(i.email.startsWith('staff.')?'Персональная ссылка':i.email)+(i.phone?' · '+i.phone:''),role:i.assigned_role||'waiter',assignedRole:i.assigned_role,status:'pending',createdAt:Date.parse(i.request_at)}))),payQr:data.settings.payment_url||'',rev:data.settings.reviews||{},shift:Object.fromEntries(data.members.map(x=>[x.id,!!x.on_shift])),log:data.events.map(e=>({at:Date.parse(e.created_at),k:e.kind,who:e.target_id,extra:e.details.role||e.details.email||''})),device:data.me};
 const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
'''+strings+'''
 S.ru.payQrH='Банковский QR для оплаты в вашем кафе. Банк и касса не подключаются.';S.ru.r_kitchen='Кухня';S.ru.r_bar='Бар';S.vi.r_kitchen='Bếp';S.vi.r_bar='Bar';const t=k=>S[ST.lang][k],ROLE_OPTS=['waiter','kitchen','bar','manager'],roleName=r=>t('r_'+r),wname=id=>ST.staff.find(s=>s.id===id)?.name||'—';
 function rolePicker(x){const m=data.members.find(m=>m.id===x.id),roles=m?.roles||[x.role];if(data.role!=='owner'||x.id===data.me)return esc(roles.map(roleName).join(', '));return `<details class="staff-role-picker"><summary>${esc(roles.map(roleName).join(', '))}</summary><form popover="auto" data-member-roles="${esc(x.id)}"><fieldset><legend>Роли сотрудника</legend>${ROLE_OPTS.map(role=>`<label><input type="checkbox" name="roles" value="${role}" ${roles.includes(role)?'checked':''}>${esc(roleName(role))}</label>`).join('')}</fieldset><button type="submit">Сохранить</button></form></details>`;}
'''+renderer+'''
 el.classList.add('original-report','original-staff');rStaff(el);
 const invoke=(command,body)=>options.onAction(command,body);
 el.querySelectorAll('.staff-role-picker').forEach(picker=>{const popup=picker.querySelector('[popover]');picker.addEventListener('toggle',()=>{if(picker.open){const rect=picker.querySelector('summary').getBoundingClientRect();popup.style.left=Math.max(8,Math.min(rect.left,window.innerWidth-256))+'px';popup.style.top=Math.max(8,Math.min(rect.bottom+6,window.innerHeight-270))+'px';popup.showPopover()}else if(popup.matches(':popover-open'))popup.hidePopover()});popup.addEventListener('toggle',e=>{if(e.newState==='closed')picker.open=false})});
 el.querySelectorAll('form[data-member-roles]').forEach(form=>form.onsubmit=e=>{e.preventDefault();const m=data.members.find(m=>m.id===form.dataset.memberRoles),roles=new FormData(form).getAll('roles');if(!roles.length){options.onNotice('Выберите хотя бы одну роль.');return}form.closest('details').open=false;invoke('member_set',{user_id:m.id,role:roles.includes(m.role)?m.role:roles[0],roles,active:m.active})});

  const form=el.querySelector('#staff-invite-form');const rememberInvite=()=>inviteDrafts.set(key,{name:form.elements.name.value,roles:new FormData(form).getAll('roles')});form.addEventListener('input',rememberInvite);form.querySelector('[data-save-invite-roles]').onclick=()=>{const roles=new FormData(form).getAll('roles');if(!roles.length){options.onNotice('Выберите хотя бы одну роль.');return}rememberInvite();const picker=form.querySelector('.staff-role-picker');picker.querySelector('summary').textContent=roles.map(roleName).join(', ');picker.open=false};form.onsubmit=async e=>{e.preventDefault();const f=new FormData(form),name=f.get('name').trim(),roles=f.getAll('roles'),email='';if(!roles.length){options.onNotice('Выберите хотя бы одну роль.');return}const role=roles.includes(currentLink?.role)?currentLink.role:roles[0];const result=await invoke('invite_create',{name,role,roles,mode:'link',...(currentLink?.id?{replace_id:currentLink.id}:{})});if(result?.token){inviteDrafts.delete(key);links.set(key,{name,email,role,roles,id:result.id,expires_at:result.expires_at,url:'https://dellviktoriapro.github.io/qr-menu/app/#staff='+result.token});options.onRefresh()}else if(result?.reissue_required){inviteDrafts.delete(key);links.set(key,{name,email,role,roles,id:result.id,expires_at:result.expires_at});options.onNotice('Приглашение создано, но ссылка не была получена. Перевыпустите её — старая будет отменена.');options.onRefresh()}};
  if(currentLink?.url){new QRCode(el.querySelector('#qrJoin'),{text:currentLink.url,width:164,height:164,colorDark:'#152235',colorLight:'#ffffff',correctLevel:QRCode.CorrectLevel.M});el.querySelector('#staff-copy-link').onclick=async()=>{const msg=el.querySelector('#staff-copy-status');try{await navigator.clipboard.writeText(currentLink.url);msg.textContent='Ссылка скопирована';options.onNotice('Ссылка скопирована. Отправьте её сотруднику.')}catch{msg.textContent='Не удалось скопировать ссылку';options.onNotice('Не удалось скопировать ссылку. Используйте QR.') }}}
  const invites=el.querySelector('#staff-invites');invites.innerHTML=data.invites.filter(i=>!i.revoked_at&&!i.accepted_at&&Date.parse(i.expires_at)>now).map(i=>`<div class="staff-invite-row"><span>${esc(i.name)} · ${esc(i.assigned_role?roleName(i.assigned_role)+' · ':'')}${esc(i.email.startsWith('staff.')?'Персональная ссылка':i.email)}</span><button type="button" data-revoke="${i.id}">Отменить приглашение</button></div>`).join('');
  invites.querySelectorAll('[data-revoke]').forEach(b=>b.onclick=async()=>{const result=await invoke('invite_revoke',{invite_id:b.dataset.revoke});if(result?.ok&&links.get(key)?.id===b.dataset.revoke){links.delete(key);options.onRefresh()}});
 el.querySelectorAll('[data-ok]').forEach(b=>b.onclick=()=>options.onApprove(b.dataset.ok,el.querySelector(`[data-rrole="${b.dataset.ok}"]`).value));
 el.querySelectorAll('[data-rej]').forEach(b=>b.onclick=()=>invoke('reject',{pending_id:b.dataset.rej}));
 const member=(id,role,active,deleted=false)=>invoke('member_set',{user_id:id,role,active,deleted});
 el.querySelectorAll('[data-blk]').forEach(b=>b.onclick=()=>{const x=ST.staff.find(s=>s.id===b.dataset.blk);member(x.id,x.role,x.status==='blocked')});
 el.querySelectorAll('[data-del]').forEach(b=>b.onclick=()=>{if(!b.dataset.arm){b.dataset.arm='1';b.textContent='Точно удалить?';return}const x=ST.staff.find(s=>s.id===b.dataset.del);member(x.id,x.role,false,true)});
 el.querySelectorAll('[data-role-s]').forEach(b=>b.onchange=()=>{const x=ST.staff.find(s=>s.id===b.dataset.roleS);member(x.id,b.value,x.status==='active')});
 if(data.role!=='owner'){el.querySelector('.staff-invite-card')?.parentElement.remove();el.querySelectorAll('[data-blk],[data-del],[data-role-s]').forEach(n=>{if(n.tagName==='SELECT'){const text=document.createElement('span');text.textContent=n.options[n.selectedIndex]?.text||'';n.replaceWith(text)}else n.remove()})}
 if(data.role==='owner'){const printer=document.createElement('button');printer.type='button';printer.textContent='Настройки принтера';printer.onclick=()=>options.onPrinter?.();el.append(printer)}

}
function renderProfile(el,options){const {data}=options,me=data.members.find(x=>x.id===data.me);if(!me)return;el.classList.add('original-report','original-staff');const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
'''+strings+'''
 S.ru.tipQrH='Ваш банковский QR для прямых переводов чаевых.';const t=k=>S[options.lang||'ru'][k];me.tipQr=me.tip_url||'';const ST={payQr:data.settings.payment_url||'',rev:data.settings.reviews||{}};
 el.innerHTML=`<div class="card"><div class="row"><h2>${esc(me.name)}</h2><button type="button" id="staff-shift">${me.on_shift?'Закончить смену':'Начать смену'}</button></div></div><div class="card"><h3>${esc(t('tipQrT'))}</h3>
'''+tipmarkup+'''
</div>${data.role==='owner'?`'''+settings_markup+'''`:''}`;
 el.querySelector('#staff-shift').onclick=()=>options.onAction('shift',{on_shift:!me.on_shift});
 if((me.roles||[]).length>1){const box=document.createElement('section');box.className='card';box.innerHTML='<h3>Рабочая роль</h3><label>Переключить роль<select id="staff-active-role">'+me.roles.map(role=>'<option value="'+esc(role)+'" '+(role===me.role?'selected':'')+'>'+esc(({waiter:'Официант',bar:'Бар',kitchen:'Кухня',manager:'Управляющий'})[role]||role)+'</option>').join('')+'</select></label>';el.prepend(box);box.querySelector('select').onchange=e=>options.onRole?.(e.target.value)}
 if(options.headerManaged)el.querySelector('#staff-shift').remove();
 el.querySelector('#tqIn').onchange=e=>options.onUpload('tip',e.target.files[0]);
 const remove=el.querySelector('#tqDel');if(remove)remove.onclick=()=>options.onAction('asset_remove',{kind:'tip'});
 if(data.role==='owner'){el.querySelector('#revSave').onclick=()=>options.onAction('reviews',{google:el.querySelector('#revG').value.trim(),tripadvisor:el.querySelector('#revTa').value.trim()});el.querySelector('#payQrIn').onchange=e=>options.onUpload('payment',e.target.files[0]);const removePay=el.querySelector('#payQrDel');if(removePay)removePay.onclick=()=>{if(!removePay.dataset.arm){removePay.dataset.arm='1';removePay.textContent='Точно убрать QR?';return}options.onAction('asset_remove',{kind:'payment'})}}
}
return {render:renderStaff,profile:renderProfile,acceptInvite(cafe,actor,data){if(data.token)links.set(cafe+':'+actor,{name:data.name,email:data.email,role:data.role,id:data.id,expires_at:data.expires_at,url:'https://dellviktoriapro.github.io/qr-menu/app/#staff='+data.token})},reset(){links.clear()}};})();
'''
if __name__=='__main__':(HERE/'staff-ui.js').write_text(build(),encoding='utf-8')
