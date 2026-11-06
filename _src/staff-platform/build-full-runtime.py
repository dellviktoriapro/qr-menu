"""Compile the ORIGINAL full UI against the server contract for isolated integration QA.
Not a published application. Production switching is blocked until action parity passes.
"""
from pathlib import Path
import argparse,json,re
HERE=Path(__file__).resolve().parent
BASE=HERE.parent

def replace_section(s,start,end,new):
    a=s.index(start);b=s.index(end,a)
    return s[:a]+new+'\n'+s[b:]

def compile_runtime():
    s=(BASE/'demo/demo.html').read_text(encoding='utf-8')
    if any(x in s for x in ['__PH__','__CO__','__SS__']):raise ValueError('Build original demo first')
    # Same original markup, styles, renderers, translations, charts, dialogs, and controls.
    s=replace_section(s,'const CAFES=','const WAITERS=', '''const CAFE={id:snapshot.cafe.id,name:snapshot.cafe.name,short:snapshot.cafe.name,mono:snapshot.cafe.name[0],sfx:'',file:snapshot.cafe.slug||'cafe'};
const CAFES={[CAFE.id]:CAFE};
const mapped=staffServerState.mapSnapshot(snapshot);
const MENU=Object.values(mapped.menu).filter(x=>x.active);
const M=mapped.menu;
const CMENU=[];''')
    s=replace_section(s,'const KEY=','/* ---------- helpers ---------- */', '''let ST=mapped.state;
let bc=null,xbc=null;const XK='';
function save(){transport.preferences?.(Object.fromEntries(['lang','theme','sound','wtab','ktab','otab','oper','mineOnly'].map(k=>[k,ST[k]])))}
function pub(){}function importInbox(){}
function readQr(){throw Error('QR_STORAGE_NOT_CONNECTED')}
''')
    a=s.index('function mutate(fn)');b=s.index('\n',a)
    s=s[:a]+'''function mutate(){throw Error('SERVER_ACTION_NOT_PORTED: integration build cannot save demo state')}'''+s[b:]
    s=replace_section(s,'/* sample history for days before today:','function periodKeys()', '''function dayAgg(k){return transport.analyticsDay(k)}
''')
    s=s.replace('const ROLES=["waiter","kitchen","owner","join"];','const ROLES=ST.serverRole==="owner"||ST.serverRole==="manager"?["waiter","kitchen","owner"]:[ST.role];')
    # Startup is controlled by the authenticated host, not by demo load/importInbox.
    marker='render();importInbox();'
    assert marker in s
    s=s.replace(marker,'''S.ru.histNote='Интеграционная проверка исходного интерфейса: только переданные серверные данные, без демонстрационной истории.';
S.vi.histNote='Dữ liệu máy chủ, không có lịch sử minh họa.';
const originalRender=render;
render=function(){originalRender();document.querySelector('.demo').hidden=true;document.getElementById('cafeBtn').hidden=true;document.getElementById('tSub').textContent=(snapshot.me.name||'')+' · '+snapshot.me.role;
const context=document.getElementById('demo-page-context');if(context)context.textContent='';
const meta=document.querySelector('.app-sidebar-meta');if(meta)meta.textContent='Серверное подключение · интеграционная проверка';};
toKitchen=id=>transport.command(staffServerState.orderCommand(ST,'send',id));
kReady=(id,station)=>transport.command(staffServerState.orderCommand(ST,'station_ready',id,{station}));
kItem=(id,index)=>{const i=ST.orders.find(o=>o.id===id)?.items[index];if(!i)throw Error('ITEM_NOT_FOUND');return transport.command(staffServerState.orderCommand(ST,'item_ready',id,{item_id:i.id,ready:!i.done}))};
served=(id,station)=>transport.command(staffServerState.orderCommand(ST,'serve',id,{station}));
render();
return {update(next){const previous=ST;const nextModel=staffServerState.mapSnapshot(next,ST);Object.keys(M).forEach(k=>delete M[k]);Object.assign(M,nextModel.menu);MENU.splice(0,MENU.length,...Object.values(M).filter(x=>x.active));ST=nextModel.state;if(['owner','manager'].includes(ST.serverRole)&&['waiter','kitchen','owner'].includes(previous.role))ST.role=previous.role;detectEvents(previous);render()},stop(){runtimeTimers.forEach(id=>window.clearInterval(id));document.body.innerHTML=''}};''')
    # Guard original demo simulators and selector-changing business roles even during isolated QA.
    s=s.replace('$("resetBtn").onclick=()=>{','$("resetBtn").onclick=()=>{throw Error("DEMO_RESET_DISABLED");')
    s=s.replace('ST.role=b.dataset.role;','if(!ROLES.includes(b.dataset.role))throw Error("ROLE_DENIED");ST.role=b.dataset.role;')
    # Wrap the single main inline program so it cannot bootstrap itself with sample data.
    a=s.index('<script>')+len('<script>');b=s.rindex('</script>')
    js=s[a:b]
    s=s[:a]+"\nwindow.startStaffRuntime=function(snapshot,transport){\nconst runtimeTimers=[];const setInterval=(fn,ms)=>{const id=window.setInterval(fn,ms);runtimeTimers.push(id);return id};\n"+js+"\n};\n"+s[b:]
    adapter=(HERE/'full-state.js').read_text(encoding='utf-8')
    s=s.replace('<script>', '<script>'+adapter+'</script><script>',1)
    # Dead demo functions may remain as source, but no generated data can run: all boot paths removed.
    for forbidden in ['ST=load()','function seedState()','function genDay(','new BroadcastChannel(','setInterval(importInbox,','co_ops_v2']:
        assert forbidden not in s,forbidden
    return '<!doctype html><html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head><body>'+s+'</body></html>'

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--output',required=True);args=p.parse_args()
    target=Path(args.output).resolve()
    if (HERE.parents[1]/'app') in target.parents:raise SystemExit('Production switch blocked: complete parity tests first')
    target.write_text(compile_runtime(),encoding='utf-8')
    print('Compiled original staff UI for isolated server integration QA:',target)
