from pathlib import Path
import sys,json
import os,argparse
if os.environ.get('SUNSEA_QR_LIB'):sys.path.insert(0,os.environ['SUNSEA_QR_LIB'])
import qrcode
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A3
from reportlab.lib.colors import HexColor
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
parser=argparse.ArgumentParser()
parser.add_argument('--art',type=Path,required=True)
parser.add_argument('--output-dir',type=Path,required=True)
args=parser.parse_args()
output=args.output_dir
output.mkdir(parents=True,exist_ok=True)
art=args.art
fonts={'Brand':'georgiab.ttf','Body':'arial.ttf','Bold':'arialbd.ttf','Korean':'malgun.ttf','KoreanBold':'malgunbd.ttf','Chinese':'msyh.ttc','ChineseBold':'msyhbd.ttc'}
for name,file in fonts.items():pdfmetrics.registerFont(TTFont(name,'C:/Windows/Fonts/'+file,subfontIndex=0))
heads=[('Меню на вашем языке','Brand',31,293),('Menu in your language','Brand',29,278),('Speisekarte in Ihrer Sprache','Brand',27,263),('Thực đơn bằng ngôn ngữ của bạn','Bold',26,248),('내 언어로 보는 메뉴','KoreanBold',27,233),('用您的语言浏览菜单','ChineseBold',29,218)]
ctas=[('Сканируйте, чтобы открыть меню','Body',11.7,102),('Scan to view the menu','Body',12.5,94),('Scannen und Speisekarte ansehen','Body',11.5,86),('Quét mã để xem thực đơn','Body',12.5,78),('스캔하고 메뉴를 확인하세요','Korean',12,70),('扫码查看菜单','Chinese',14,62)]
for text,font,size,y in heads+ctas:
 f=pdfmetrics.getFont(font);missing=[ch for ch in text if ord(ch) not in f.face.charWidths]
 assert not missing,(font,missing)
 assert pdfmetrics.stringWidth(text,font,size)<(255 if (text,font,size,y) in heads else 95)*mm,(text,'too wide')
out=output/'sunsea-menu-languages-A3.pdf'
c=canvas.Canvas(str(out),pagesize=A3,pageCompression=1)
c.setTitle('Sun&Sea - Menu in your language - A3');c.setAuthor('Sun&Sea Restaurant');c.setSubject('Russian English German Vietnamese Korean Chinese menu / QR')
W,H=A3;ink=HexColor('#24401f');gold=HexColor('#c7a044')
c.drawImage(str(art),0,0,width=W,height=H)
def line(text,font,size,y,color=ink):
 c.setFillColor(color);c.setFont(font,size);c.drawCentredString(W/2,y*mm,text)
line('Sun&Sea','Brand',59,324)
line('RESTAURANT  ·  MŨI NÉ','Bold',11.5,313)
c.setStrokeColor(gold);c.setLineWidth(.7);c.line(99*mm,306*mm,198*mm,306*mm)
for text,font,size,y in heads:line(text,font,size,y)
# Quiet, high-contrast scan area with true vector modules and four-module quiet zone.
c.setFillColor(HexColor('#fffdf7'));c.setStrokeColor(HexColor('#c9ad6d'));c.setLineWidth(.8)
c.roundRect(95*mm,57*mm,107*mm,150*mm,6*mm,stroke=1,fill=1)
line('RU  ·  EN  ·  DE  ·  VI  ·  KO  ·  ZH','Bold',9,200)
url='https://dellviktoriapro.github.io/qr-menu/sun-sea/?view=preview'
qr=qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M,border=4);qr.add_data(url);qr.make(fit=True)
mat=qr.get_matrix();size=85*mm;module=size/len(mat);qx=(W-size)/2;qy=108*mm
c.setFillColor(HexColor('#ffffff'));c.rect(qx,qy,size,size,fill=1,stroke=0);c.setFillColor(ink)
for iy,row in enumerate(mat):
 for ix,dark in enumerate(row):
  if dark:c.rect(qx+ix*module,qy+(len(mat)-1-iy)*module,module+.005,module+.005,fill=1,stroke=0)
c.linkURL(url,(qx,qy,qx+size,qy+size),relative=0,thickness=0)
for text,font,size,y in ctas:line(text,font,size,y)
c.showPage();c.save()
(output/'a3-banner-manifest.json').write_text(json.dumps({'pdf':str(out),'size_mm':[297,420],'url':url,'headlines':[x[0] for x in heads],'cta':[x[0] for x in ctas],'qr_modules':len(mat),'art':str(art)},ensure_ascii=False,indent=2),'utf8')
print(out)
