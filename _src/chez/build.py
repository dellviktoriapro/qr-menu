import json,base64
import data
b64=lambda p:'data:image/jpeg;base64,'+base64.b64encode(open(p,'rb').read()).decode()
CAT=dict(breakfast='english',waffles='cr_banana',muesli='mu_mango',starters='sc_cheese',salads='br_salmon',burgers='burger_beef',pasta='pa_seafood',
 panseared='ps_passion',soups='cs_tomyum',vietnam='vn_luclac',rice='ri_pine',lunch='lu_bo',veg='vg_tofu_bbq',desserts='sw_mango_tira',
 coffee='hd_capp',cold='cd_salted',juices='ju_water',healthy='healthy_b',smoothies='yo_straw',frappe='fr_caramel',cocktails='ck_mojito_s',beer=None,wine='wi_red')
used={i[6] for s in data.S for i in s['items'] if i[6]}|{v for v in CAT.values() if v}
PH={k:b64(f'ph/{k}.jpg') for k in used}
AMB={k:b64(f'amb/{k}.jpg') for k in ['lion','zebras','terrace','interior','impala']}
D=[dict(id=s['id'],n=s['n'],note=s['note'],g=s['g'],items=[[i[0],i[1],i[2],i[3],i[4],([[l,p] for l,p in i[5]] if isinstance(i[5],list) else i[5]),i[6]] for i in s['items']]) for s in data.S]
h=open('tpl.html').read().replace('__DATA__',json.dumps(D,ensure_ascii=False)).replace('__PH__',json.dumps(PH)).replace('__AMB__',json.dumps(AMB)).replace('__GEN__',json.dumps(open('gen.txt').read().split())).replace('__CATPH__',json.dumps({k:v for k,v in CAT.items() if v}))
open('chez-oanh-menu.html','w').write(h);print(len(h)//1024,'KB',len(PH))
