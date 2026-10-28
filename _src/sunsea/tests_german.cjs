const fs=require('fs'),vm=require('vm'),assert=require('assert');
const root=require('path').resolve(__dirname,'../..')+'/';
const html=fs.readFileSync(root+'sun-sea/index.html','utf8');
for(const match of html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g))new vm.Script(match[1]);
const ctx={};let text=fs.readFileSync(root+'_src/chez/tpl.html','utf8');
vm.runInNewContext(text.slice(text.indexOf('const WISH='),text.indexOf('function pl(n,f)'))+'\n'+fs.readFileSync(root+'_src/sunsea/german.js','utf8')+'\nresult={T,WISH};',ctx);
for(const key of Object.keys(ctx.result.T.en))assert(key in ctx.result.T.de,'Missing core: '+key);
for(const w of ctx.result.WISH)assert(w.de,'Missing wish: '+w.k);
assert.equal(ctx.result.T.de.items(1),'1 Position');assert.equal(ctx.result.T.de.items(2),'2 Positionen');
const data=JSON.parse(html.match(/const DATA=(\[[^\n]+\]);/)[1]);
let count=0;for(const s of data){assert(s.n.de,s.id);for(const it of s.items){assert.equal(it.length,9);assert(it[8],s.id+'|'+count);assert(typeof it[7]==='object');count++;} }
assert.equal(count,183);assert.equal(data.length,25);
const walk=x=>{if(Array.isArray(x))x.forEach(walk);else if(x&&typeof x==='object'){if('en'in x)assert(x.de,'Missing catalog '+x.en);else Object.values(x).forEach(walk)}};
walk(data);
for(const name of ['menu-only','item-preferences','item-availability','shared-cart','public-preview','booking','finish-visit']){
 const s=fs.readFileSync(root+'_src/sunsea/'+name+'.js','utf8');let en=[...s.matchAll(/^ en:(.*),$/gm)],de=[...s.matchAll(/^ de:(.*),$/gm)];assert.equal(en.length,de.length,name);
 en.forEach((e,i)=>{const a=vm.runInNewContext('('+e[1]+')'),b=JSON.parse(de[i][1]);for(const k of Object.keys(a))assert(k in b,name+':'+k)});
}
assert(html.includes('[...it.slice(0,5),it[8]].join'));assert(html.includes('de:8'));assert(html.includes('n:"Deutsch",c:"VND"'));assert(html.includes('de:"🇩🇪"'));
assert(!fs.readFileSync(root+'_src/chez/tpl.html','utf8').includes('T.de='));
console.log('PASS: German core/layers complete, 25 sections + 183 items translated, inline JS compiles, original tuple indices preserved.');
