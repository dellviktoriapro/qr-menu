import json,os,shutil,base64,io
from PIL import Image
import data
exec(open('build.py').read().split("PH={k:b64")[0].split("import data",1)[1])  # CAT, used
import sys
OUT=sys.argv[1] if len(sys.argv)>1 else '../../chez-oanh'
shutil.rmtree(OUT,ignore_errors=True);os.makedirs(OUT)
def webp(src,maxw,q=74):
    im=Image.open(src).convert('RGB')
    if im.width>maxw:im=im.resize((maxw,round(im.height*maxw/im.width)),Image.LANCZOS)
    b=io.BytesIO();im.save(b,'WEBP',quality=q,method=6);return 'data:image/webp;base64,'+base64.b64encode(b.getvalue()).decode()
# order: category covers, signature (GEN), then dishes in menu order, then gallery
gen=open('gen.txt').read().split()
order=[]
for k in [v for v in CAT.values() if v]+gen+[i[6] for s in data.S for i in s['items'] if i[6]]:
    if k in used and k not in order:order.append(k)
for k in sorted(used):
    if k not in order:order.append(k)
items=[(k,webp(f'ph/{k}.jpg',720)) for k in order]+[('amb_'+k,webp(f'amb/{k}.jpg',1400)) for k in ['interior','terrace','impala','zebras']]
chunks=[];cur=[];size=0
for k,v in items:
    cur.append((k,v));size+=len(v)
    if size>650_000:chunks.append(cur);cur=[];size=0
if cur:chunks.append(cur)
for n,c in enumerate(chunks,1):
    open(f'{OUT}/ph{n}.js','w').write('__ph('+json.dumps(dict(c))+');')
D=[dict(id=s['id'],n=s['n'],note=s['note'],g=s['g'],items=[[i[0],i[1],i[2],i[3],i[4],([[l,p] for l,p in i[5]] if isinstance(i[5],list) else i[5]),i[6]]+([i[7]] if len(i)>7 and i[7] else []) for i in s['items']]) for s in data.S]
AMB={'lion':webp('amb/lion.jpg',1100,70)}
h=open('tpl.html').read().replace('__DATA__',json.dumps(D,ensure_ascii=False)).replace('__PH__','{}').replace('__AMB__',json.dumps(AMB)).replace('__GEN__',json.dumps(gen)).replace('__CATPH__',json.dumps({k:v for k,v in CAT.items() if v}))
h+='<script>(function n(i){if(i>%d)return;var s=document.createElement("script");s.src="ph"+i+".js";s.onload=s.onerror=function(){n(i+1)};document.body.appendChild(s)})(1)</script>'%len(chunks)
h='<!doctype html>\n<html lang="ru">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n</head>\n<body>\n'+h+'</body></html>'
open(OUT+'/index.html','w').write(h)
print('html',len(h.encode())//1024,'KB;',[os.path.getsize(f'{OUT}/ph{n}.js')//1024 for n in range(1,len(chunks)+1)])
