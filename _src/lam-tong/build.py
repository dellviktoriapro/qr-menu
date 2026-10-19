import json,base64,io
from PIL import Image
import data
CAT=dict(soup='soup_sour',rice='rice_yz',noodle='nd_sing',porridge='por_sea',rolls='roll_2',fish='fs_1',shrimp='sh_6',squid='sq_2',crab='crab_2',lobster='lob_1',hotpot='hp_2',salad='sal_fries',bread='br_sand',breakfast='bf_omelet',pancake='pc_mango',takeaway='ff_curry',juice='dr_passion',fruit='fr_plate')
used={it[6] for s in data.S for it in s['items'] if it[6]}|set(CAT.values())
PH={}
for k in used:
    im=Image.open(f'ph/{k}.jpg');im.thumbnail((360,360),Image.LANCZOS)
    b=io.BytesIO();im.save(b,'JPEG',quality=76,optimize=True,progressive=True)
    PH[k]='data:image/jpeg;base64,'+base64.b64encode(b.getvalue()).decode()
O='soup rice noodle porridge rolls fish shrimp squid crab lobster hotpot salad bread breakfast pancake takeaway coffee juice fruit soft alco'.split()
data.S.sort(key=lambda x:O.index(x['id']))
D=[dict(id=s['id'],n=s['n'],note=s['note'],items=[list(i) for i in s['items']]) for s in data.S]
h=open('tpl.html').read().replace('__DATA__',json.dumps(D,ensure_ascii=False)).replace('__PH__',json.dumps(PH)).replace('__CATPH__',json.dumps(CAT))
open('lam-tong-menu.html','w').write(h);print(len(h)//1024,'KB',len(PH),'photos')
