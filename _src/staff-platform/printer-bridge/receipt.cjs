'use strict';
const numbers=require('./numbers.json');
const title=n=>typeof n==='string'?n:n?.vi||n?.ru||n?.en||'—';
function lines(job){
 const p=job.payload;if(job.is_test)return ['ТЕСТ ПЕЧАТИ — НЕ ЗАКАЗ',p.destination||'',...p.lines.slice(1),'TEST PRINT — NOT AN ORDER'];
 const result=[p.title,p.cafe||'',`Стол / Ban: ${p.table||'—'}`];if(p.order_number)result.push(`Заказ / Order: ${p.order_number}`);
 if(p.comment)result.push(p.comment);if(p.wishes?.length)result.push(p.wishes.join('; '));let total=0;
 for(const i of p.items||[]){const key=String(i.key||'').split('|').slice(1).join('|'),num=numbers[key],name=title(i.name);result.push(`${i.qty} x ${num&&!name.startsWith('№ ')?'№ '+num+' · ':''}${name}`);if(i.name?.ru&&i.name?.ru!==name)result.push(i.name.ru);if(i.note)result.push('  '+i.note);if(job.purpose==='receipt'){const sum=i.qty*i.price;total+=sum;result.push(sum.toLocaleString('vi-VN')+' '+(p.currency||'VND'))}}
 if(job.purpose==='receipt')result.push('------------------------','ИТОГО / TONG: '+total.toLocaleString('vi-VN')+' '+(p.currency||'VND'));
 return result.filter(Boolean);
}
function raster(job,canvasLib){
 const width=job.printer.paper_width===58?384:576,font=24,lineHeight=34,margin=16,measure=canvasLib.createCanvas(width,1).getContext('2d');measure.font=`${font}px Arial`;const rows=[];
 for(const line of lines(job)){let row='';for(const word of String(line).split(/\s+/)){const next=row?row+' '+word:word;if(measure.measureText(next).width>width-margin*2&&row){rows.push(row);row=word}else row=next}rows.push(row)}
 const canvas=canvasLib.createCanvas(width,rows.length*lineHeight+margin*2),ctx=canvas.getContext('2d');ctx.fillStyle='white';ctx.fillRect(0,0,width,canvas.height);ctx.fillStyle='black';ctx.font=`${font}px Arial`;rows.forEach((r,i)=>ctx.fillText(r,margin,margin+font+i*lineHeight));
 const data=ctx.getImageData(0,0,width,canvas.height).data,rowBytes=width/8,bitmap=Buffer.alloc(rowBytes*canvas.height);
 for(let y=0;y<canvas.height;y++)for(let x=0;x<width;x++){const at=(y*width+x)*4;if(data[at]*.299+data[at+1]*.587+data[at+2]*.114<150)bitmap[y*rowBytes+(x>>3)]|=0x80>>(x&7)}
 return Buffer.concat([Buffer.from([0x1b,0x40,0x1d,0x76,0x30,0,rowBytes&255,rowBytes>>8,canvas.height&255,canvas.height>>8]),bitmap,Buffer.from([10,10,10,0x1d,0x56,0])]);
}
module.exports={lines,raster};
