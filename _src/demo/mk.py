import sys
s=open('../ops/tpl.html').read()
def rep(a,b):
    global s
    assert a in s,a[:80]; s=s.replace(a,b,1)
rep('<title>Chez Oanh Order Flow</title>','<title>Chez Oanh Order Flow RU</title>')
rep('const KEY="co_ops_v2";','const KEY="co_ops_ru_v3";')
rep('BroadcastChannel("co_ops")','BroadcastChannel("co_ops_ru")')
rep('lang:"vi",glang:"en"','lang:"ru",glang:"ru"')
rep('note:"1 trứng chín kỹ"','note:"одно яйцо полной прожарки"')
rep('comment:"Khách vội, ra đồ uống trước"','comment:"Гости спешат, сначала напитки"')
rep('const nm=(mid,l)=>M[mid][l]||M[mid].vi;','const nm=(mid,l)=>M[mid][l]||M[mid].vi;\nconst pn=mid=>nm(mid,ST.lang);\nconst sn=mid=>ST.lang==="ru"?M[mid].vi:"";')
rep('''<span class="n"><b>${esc(nm(i.mid,"vi"))}</b>${i.added?`<span class="badge-new">+</span>`:""}${ST.lang==="ru"?`<span class="tr">${esc(nm(i.mid,"ru"))}</span>`:o.lang!=="vi"?`<span class="tr">${esc(nm(i.mid,"en"))}</span>`:""}''',
'''<span class="n"><b>${esc(pn(i.mid))}</b>${i.added?`<span class="badge-new">+</span>`:""}${sn(i.mid)?`<span class="tr">${esc(sn(i.mid))}</span>`:o.lang!=="vi"&&ST.lang==="vi"?`<span class="tr">${esc(nm(i.mid,"en"))}</span>`:""}''')
rep('''<span><b>${esc(nm(i.mid,"vi"))}</b>${f==="all"''','''<span><b>${esc(pn(i.mid))}</b>${f==="all"''')
rep('''${ST.lang==="ru"?`<span class="sub">${esc(nm(i.mid,"ru"))}</span>`:""}''','''${sn(i.mid)?`<span class="sub">${esc(sn(i.mid))}</span>`:""}''')
rep('''return w?esc(w.vi)+(ST.lang==="ru"?" ("+esc(w.ru)+")":""):""''','''return w?esc(w[ST.lang]):""''')
rep('''<span class="nm">${esc(nm(i.mid,"vi"))}${ST.lang==="ru"?` <span class="dim">· ${esc(nm(i.mid,"ru"))}</span>`:""}</span>''','''<span class="nm">${esc(pn(i.mid))}${sn(i.mid)?` <span class="dim">· ${esc(sn(i.mid))}</span>`:""}</span>''')
rep('''<span>${esc(m.vi)}<br><span class="dim">${short(m.p)}</span></span>''','''<span>${esc(m[ST.lang])}<br><span class="dim">${short(m.p)}</span></span>''')
rep('const LANGNAME={en:"English",ru:"Русский",vi:"Tiếng Việt",ko:"한국어",zh:"中文"};','const LANGNAMES={vi:{en:"English",ru:"Русский",vi:"Tiếng Việt",ko:"한국어",zh:"中文"},ru:{en:"Английский",ru:"Русский",vi:"Вьетнамский",ko:"Корейский",zh:"Китайский"}};\nconst LANGNAME=new Proxy({},{get:(_,k)=>LANGNAMES[(typeof ST!=="undefined"&&ST)?ST.lang:"ru"][k]});')
rep('$("langBtn").textContent=ST.lang==="vi"?"VI → RU":"RU → VI";','$("langBtn").textContent=ST.lang==="ru"?"RU → VI":"VI → RU";')
rep('<button class="chipbtn" type="button" id="langBtn">VI</button>','<button class="chipbtn" type="button" id="langBtn">RU</button>')
rep('<b>Café Chez Oanh</b><small','<b>Кафе Chez Oanh</b><small')
rep('sub:"Демо процесса · QR-меню"','sub:"Демо: заказ → официант → кухня"')
open('tpl.html','w').write(s)
s=open('tpl.html').read()
def rp(a,b):
    global s
    assert a in s,a[:60]; s=s.replace(a,b,1)
rp('<title>Chez Oanh Order Flow RU</title>','<title>Chez Oanh Order Flow</title>')
rp('const KEY="co_ops_ru_v3";','const KEY="co_ops_demo_v2";')
rp('BroadcastChannel("co_ops_ru")','BroadcastChannel("co_ops_demo")')
rp('<b>Кафе Chez Oanh</b>','<b>Café Chez Oanh</b>')
rp('ST=load();','''const FRESH=!ls.get(KEY);ST=load();
(function(){const h=(location.hash||"").slice(1).toLowerCase();
  const pick=h==="vi"||h==="ru"?h:(FRESH?((navigator.language||"").toLowerCase().startsWith("vi")?"vi":"ru"):null);
  if(pick){ST.lang=pick;ST.glang=pick==="vi"?"en":"ru"}})();''')
open('tpl.html','w').write(s)
