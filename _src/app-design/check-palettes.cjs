const fs=require('fs'),vm=require('vm'),assert=require('node:assert/strict');
const themes=vm.runInNewContext(fs.readFileSync(__dirname+'/themes.js','utf8')+';THEMES');
const lum=h=>{const [r,g,b]=h.match(/\w\w/g).map(x=>parseInt(x,16)/255).map(x=>x<=.04045?x/12.92:((x+.055)/1.055)**2.4);return .2126*r+.7152*g+.0722*b};
const ratio=(a,b)=>(Math.max(lum(a),lum(b))+.05)/(Math.min(lum(a),lum(b))+.05);
for(const t of themes){const v=t.vars;for(const surface of ['ground','surface','raised'])for(const text of ['ink','muted'])assert(ratio(v[text],v[surface])>=4.5,t.id+' '+text+'/'+surface);assert(ratio(v.accentInk,v.accent)>=4.5,t.id+' button text');console.log(t.id+': minimum text contrast '+Math.min(...['ground','surface','raised'].flatMap(s=>['ink','muted'].map(t=>ratio(v[t],v[s]))),ratio(v.accentInk,v.accent)).toFixed(2)+':1')}
