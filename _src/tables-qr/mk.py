import qrcode,qrcode.image.svg,io,os,glob
import os
F=os.environ.get('FONTSOURCE','node_modules/@fontsource/')  # npm i @fontsource/cormorant-garamond @fontsource/be-vietnam-pro
def ff(fam,name,w):
    out=[]
    for sub in ['latin','latin-ext','vietnamese','cyrillic','cyrillic-ext']:
        p=f'{F}{fam}/files/{fam}-{sub}-{w}-normal.woff2'
        if os.path.exists(p):out.append(f"@font-face{{font-family:'{name}';font-weight:{w};src:url('file://{p}') format('woff2')}}")
    return "\n".join(out)
fonts="\n".join([ff('cormorant-garamond','Cor',600),ff('cormorant-garamond','Cor',700),ff('be-vietnam-pro','BVP',500),ff('be-vietnam-pro','BVP',700)])
BASE='https://dellviktoriapro.github.io/qr-menu/chez-oanh/?t='
N=12
def svg(url):
    q=qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M,border=0,box_size=10);q.add_data(url);q.make(fit=True)
    m=q.get_matrix();n=len(m)
    d="".join(f"M{x},{y}h1v1h-1z" for y,r in enumerate(m) for x,v in enumerate(r) if v)
    return f'<svg viewBox="0 0 {n} {n}" shape-rendering="crispEdges"><path d="{d}" fill="#1d1611"/></svg>'
cards="".join(f'''<div class="c"><div class="in">
<div class="br">Café Chez Oanh</div><div class="sub">Sofa Café · Mũi Né</div>
<div class="tn"><small>BÀN · TABLE · СТОЛ</small><b>{i}</b></div>
<div class="qr">{svg(BASE+str(i))}</div>
<div class="cta">Quét để gọi món</div>
<div class="cta2">Scan to order · <span class="ru">Сканируйте, чтобы заказать</span></div>
<div class="lg">EN · RU · VI · 한국어 · 中文</div></div></div>''' for i in range(1,N+1))
html=f'''<!doctype html><html><head><meta charset="utf-8"><style>{fonts}
@page{{size:A4;margin:0}}*{{box-sizing:border-box;margin:0}}
body{{font-family:BVP,Cor,sans-serif;color:#1d1611}}
.pg{{width:210mm;height:297mm;display:grid;grid-template-columns:1fr 1fr;grid-template-rows:1fr 1fr;page-break-after:always}}
.c{{border:.2mm dashed #c9b99c;padding:7mm;display:flex}}
.in{{flex:1;background:#fbf6ea;border:.6mm solid #c98a3a;border-radius:5mm;outline:.25mm solid #c98a3a;outline-offset:-2.2mm;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;padding:6mm 6mm}}
.br{{font-family:Cor,serif;font-weight:700;font-size:26pt;line-height:1;color:#8a4f12}}
.sub{{font-size:7.5pt;letter-spacing:.3em;text-transform:uppercase;color:#8b7c66;margin-top:2mm}}
.tn{{margin:5mm 0 3mm;display:flex;flex-direction:column;align-items:center}}
.tn small{{font-size:7pt;letter-spacing:.3em;color:#a8621a;font-weight:700}}
.tn b{{font-family:Cor,serif;font-size:44pt;line-height:.95;font-weight:700}}
.qr{{width:48mm;height:48mm;padding:3mm;background:#fff;border-radius:3mm;box-shadow:0 0 0 .3mm #e0d2bb}}
.qr svg{{width:100%;height:100%;display:block}}
.cta{{margin-top:4mm;font-weight:700;font-size:12pt}}
.cta2{{font-size:8pt;color:#5c4f3f;margin-top:1mm}}
.ru{{font-family:Cor,serif;font-weight:700;font-size:9.5pt}}
.lg{{margin-top:3mm;font-size:6.5pt;letter-spacing:.2em;color:#a8621a;font-weight:700}}
</style></head><body>'''
cs=cards.split('<div class="c">')[1:]
for p in range(0,len(cs),4):html+='<div class="pg">'+"".join('<div class="c">'+x for x in cs[p:p+4])+'</div>'
open('tables.html','w').write(html+'</body></html>')
