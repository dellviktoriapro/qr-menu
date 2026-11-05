const fs=require('fs'),vm=require('vm'),assert=require('assert/strict'),path=require('path');
const root=process.env.MENU_ROOT||'D:/Users/Николай/Desktop/Меню/qr-menu';
const html=fs.readFileSync(path.join(root,'sun-sea/index.html'),'utf8');
const audit=JSON.parse(fs.readFileSync(path.join(root,'_src/sunsea/printed-number-audit.json'),'utf8'));
const DATA=JSON.parse(html.match(/const DATA=(\[[^\n]+\]);/)[1]);
const esc=x=>String(x).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const context={DATA,esc};vm.createContext(context);
vm.runInContext(fs.readFileSync(path.join(root,'_src/sunsea/waiter-menu-reference.js'),'utf8'),context);
let numbered=0,none=0;
for(const section of DATA)for(const [i,it]of section.items.entries()){
 const key=section.id+'|'+i,expected=audit.items[key];assert(expected,key);
 assert.equal(it[1],expected.vi,key+' identity');if(expected.photo!==null)assert.equal(it[6],expected.photo,key+' photo identity');
 assert.equal(it[7].n??null,expected.number,key+' printed code');
 for(const suffix of ['|0','|2','|0|custom-portion']){
  const ref=context.waiterMenuRef(it,key+suffix);
  if(expected.number===null)assert.equal(ref,'',key+' must not infer a number');
  else{assert(ref.includes('data-printed-number="'+expected.number+'"'));assert(ref.includes('№ '+expected.number));assert(ref.includes(esc(section.n.vi)));}
 }
 if(expected.number===null)none++;else numbered++;
}
assert.equal(numbered,135);assert.equal(none,48);assert.equal(Object.keys(audit.items).length,183);
assert.equal(context.waiterMenuRef(DATA[0].items[0],'bad|0|0'),'');
assert.equal(context.waiterMenuRef(['','','','','',0,'',{n:'<script>'}],'ss_salads|0|0'),'');
for(const file of ['menu-only.js','shared-cart.js'])assert(fs.readFileSync(path.join(root,'_src/sunsea',file),'utf8').includes('${waiterMenuRef(l.it,l.k)}'));
for(const match of html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g))new vm.Script(match[1]);
assert(html.indexOf('function waiterMenuRef')<html.indexOf('const lines=x.L.map'));
// Special printed codes must remain strings, including leading zero and decimals.
for(const n of ['025','51.1','51.2','01','96','97'])assert(Object.values(audit.items).some(x=>x.number===n));
// Explicit user-confirmed leading-zero distinctions must never be normalized.
for(const [key,number]of Object.entries({'ss_pasta|9':'096','ss_pasta|10':'097','ss_coffee|9':'010','ss_coffee|10':'011','ss_tuna|6':'96','ss_tuna|7':'97','ss_noodles|3':'10','ss_rolls|1':'11'})){
 const [sid,index]=key.split('|'),it=DATA.find(s=>s.id===sid).items[+index];
 assert.equal(it[7].n,number,key+' user-confirmed number');
 assert(context.waiterMenuRef(it,key+'|0').includes('№ '+number));
}
console.log('PASS: 183 identities matched independently reviewed print audit; 135 exact codes, 48 unnumbered; customized/variant keys; both waiter renderers; inline JS compiles.');
