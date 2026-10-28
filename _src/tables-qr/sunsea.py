"""Print-safe Sun&Sea cards. Exact table QR URLs remain private to the print files."""
from pathlib import Path
import sys,json,math,zipfile,io
import os,argparse
if os.environ.get('SUNSEA_QR_LIB'):sys.path.insert(0,os.environ['SUNSEA_QR_LIB'])
import qrcode
from PIL import Image
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4,A6
from reportlab.lib.colors import HexColor
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.utils import ImageReader
parser=argparse.ArgumentParser()
parser.add_argument('--links',type=Path,required=True)
parser.add_argument('--output-dir',type=Path,required=True)
args=parser.parse_args()
output=args.output_dir
output.mkdir(parents=True,exist_ok=True)
repo=Path(__file__).resolve().parents[2]
rows=json.loads(args.links.read_text(encoding='utf-8'))
expected=sorted(t['id'] for t in json.loads((repo/'_src/sunsea/table-layout.json').read_text(encoding='utf-8'))['tables'])
assert sorted(r['table'] for r in rows)==expected
assert len({r['url'] for r in rows})==len(expected)
fonts={'Brand':'georgiab.ttf','Body':'arial.ttf','Bold':'arialbd.ttf','Korean':'malgun.ttf','Chinese':'msyh.ttc'}
for name,file in fonts.items():pdfmetrics.registerFont(TTFont(name,'C:/Windows/Fonts/'+file,subfontIndex=0))
hero=Image.open(repo/'_src/sunsea/amb/hero.webp').convert('RGB')
# Shared menu art is used as a subtle accent, kept outside the QR white field.
coast=Image.open(repo/'_src/sunsea/amb/coast-right.png').convert('RGBA')
heroReader=ImageReader(hero);coastReader=ImageReader(coast)
green=HexColor('#26401c');gold=HexColor('#c49b45');sand=HexColor('#f5dfaa');cream=HexColor('#fffbef');muted=HexColor('#626a54')
ctas=[('Чтобы заказать — отсканируй','Bold'),('Scan to order','Body'),('Quét mã để gọi món','Body'),('Zum Bestellen scannen','Body'),('주문하려면 스캔하세요','Korean'),('扫码点餐','Chinese')]
CW,CH=90*mm,130*mm
manifest=[]
def card(c,row,x,y,scale=1):
    c.saveState();c.translate(x,y);c.scale(scale,scale)
    c.setFillColor(cream);c.setStrokeColor(gold);c.setLineWidth(.7);c.roundRect(0,0,CW,CH,4*mm,fill=1,stroke=1)
    # Clip photo to the card's rounded outline.
    c.saveState();clip=c.beginPath();clip.roundRect(0,0,CW,CH,4*mm);c.clipPath(clip,stroke=0)
    c.drawImage(heroReader,0,103*mm,width=CW,height=27*mm,preserveAspectRatio=False)
    c.setFillColor(green);c.setFillAlpha(.28);c.rect(0,103*mm,CW,27*mm,stroke=0,fill=1);c.restoreState()
    # The bottom illustration echoes the site's coastal silhouettes.
    c.saveState();c.setFillAlpha(.10);c.setStrokeAlpha(.10);c.drawImage(coastReader,58*mm,0,width=32*mm,height=67*mm,mask='auto');c.restoreState()
    def label(text,y,size=9,font='Body',color=green):
        assert pdfmetrics.stringWidth(text,font,size)<CW-8*mm,text
        c.setFont(font,size);c.setFillColor(color);c.drawCentredString(CW/2,y*mm,text)
    label('Sun&Sea',115,25,'Brand',HexColor('#ffffff'))
    label('R E S T A U R A N T   ·   M Ũ I  N É',108.5,6.8,'Bold',HexColor('#ffffff'))
    label('BÀN  ·  TABLE  ·  СТОЛ  ·  TISCH',96.5,7.5,'Bold',muted)
    label(str(row['table']),82,36,'Brand')
    c.setStrokeColor(gold);c.setLineWidth(.6);c.line(10*mm,90.5*mm,26*mm,90.5*mm);c.line(64*mm,90.5*mm,80*mm,90.5*mm)
    qr=qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M,border=4);qr.add_data(row['url']);qr.make(fit=True)
    mat=qr.get_matrix();size=50*mm;module=size/len(mat);qx=(CW-size)/2;qy=30*mm
    c.setFillColor(HexColor('#ffffff'));c.rect(qx,qy,size,size,fill=1,stroke=0);c.setFillColor(green)
    for iy,line in enumerate(mat):
        for ix,dark in enumerate(line):
            if dark:c.rect(qx+ix*module,qy+(len(mat)-1-iy)*module,module+.004,module+.004,stroke=0,fill=1)
    c.linkURL(row['url'],(qx,qy,qx+size,qy+size),relative=1,thickness=0)
    for i,(text,font) in enumerate(ctas):label(text,25.7-i*4.1,8.7,font)
    c.restoreState()
    return {'table':row['table'],'modules':len(mat),'qr_rect_mm':[20,30,50,50]}

pdf=output/'sunsea-table-qr.pdf'
c=canvas.Canvas(str(pdf),pagesize=A4,pageCompression=1);c.setTitle('Sun&Sea — QR меню · 17 столов');c.setAuthor('Sun&Sea Restaurant')
PW,PH=A4;gap=8*mm;left=(PW-2*CW-gap)/2;bottom=(PH-2*CH-gap)/2
for i,row in enumerate(rows):
    if i and i%4==0:c.showPage()
    slot=i%4;x=left+(slot%2)*(CW+gap);y=bottom+(1-slot//2)*(CH+gap)
    info=card(c,row,x,y);info.update({'page':i//4,'slot':slot,'card_origin_mm':[x/mm,y/mm]});manifest.append(info)
c.save()
single=output/'sunsea-table-qr-A6.pdf'
c=canvas.Canvas(str(single),pagesize=A6,pageCompression=1);c.setTitle('Sun&Sea — индивидуальные QR-таблички A6');c.setAuthor('Sun&Sea Restaurant')
for row in rows:card(c,row,(A6[0]-CW)/2,(A6[1]-CH)/2);c.showPage()
c.save()
(output/'sunsea-table-links.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(output/'table-qr-manifest.json').write_text(json.dumps({'tables':[r['table'] for r in rows],'cards':manifest,'a4_mm':[210,297],'card_mm':[90,130],'languages':['ru','en','vi','de','ko','zh']},indent=2),encoding='utf-8')
print('Created 17 cards, 5 A4 sheets and 17 A6 pages; labels in 6 languages.')
