// Shared palette engine: visual settings only, never order or payment state.
function staffThemeApply(){
 if(!ST.design){ST.design="atelier";ST.theme="dark";save()}document.body.dataset.skin=ST.theme||"dark";
 const selected=THEMES.find(t=>t.id===(ST.design||'atelier'))||THEMES.find(t=>t.id==='atelier'),v={...selected.vars};
 if(ST.theme==='light'){v.ground=v.block3;v.surface='#FFF9F2';v.raised='#E9E2D6';v.ink=v.block3Ink;v.muted=v.block3Ink;v.line='#A9ADAF';v.soft='#DDE3E8';v.navBlue='#4D6080';v.signalText='#A44308'}
 document.body.dataset.design=selected.id;
 const aliases={bg:'ground',bg2:'surface',card:'surface',card2:'raised',ink:'ink',muted:'muted',dim:'muted',line:'line',line2:'line',acc:'accent',acc2:'secondary','acc-ink':'accentInk',paper:'surface',paper2:'raised','paper-ink':'ink','paper-dim':'muted','paper-line':'line'};
 for(const [k,x] of Object.entries(v))document.body.style.setProperty('--design-'+k,x);
 for(const [k,x] of Object.entries(aliases))document.body.style.setProperty('--'+k,v[x]);
 document.body.style.setProperty('--f','Manrope,system-ui,sans-serif');document.body.style.setProperty('--fd','Lora,Georgia,serif');
 document.body.style.setProperty('--grad',v.accent);document.body.style.setProperty('--glow','none');document.body.style.setProperty('--glass',v.frame);document.body.style.setProperty('--new',v.signalText);document.body.style.setProperty('--cook','#A6C7ED');document.body.style.setProperty('--ready','#F4721E');document.body.style.setProperty('--hot','#F4721E');document.body.style.setProperty('--hot-glow','transparent');
 document.documentElement.style.background=v.ground;
}
function staffDesignPicker(el){
 const host=document.createElement('section');host.className='card palette-settings';host.innerHTML=`<h3>${ST.lang==='ru'?'Оформление приложения':'Giao diện ứng dụng'}</h3><p class="muted">${ST.lang==='ru'?'Меняется только палитра. Функции, навигация и статусы одинаковые. В демо выбор хранится в этом браузере.':'Chỉ thay đổi màu sắc. Chức năng và trạng thái giữ nguyên. Bản demo lưu lựa chọn trên trình duyệt này.'}</p><div class="palette-options">${THEMES.map(t=>`<button type="button" data-design="${t.id}" aria-pressed="${(ST.design||'atelier')===t.id}"><strong>${esc(t.letter+' · '+t.name)}</strong><span aria-hidden="true">${t.colors.map(c=>`<i style="background:${c}"></i>`).join('')}</span></button>`).join('')}</div>`;
 el.prepend(host);host.querySelectorAll('[data-design]').forEach(b=>b.onclick=()=>mutate(()=>{ST.design=b.dataset.design;ST.theme='dark'}));
}
