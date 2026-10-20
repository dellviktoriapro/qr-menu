import json
import sys;sys.path.insert(0,'../chez');import data
CO=[[s['id'],s['n']['vi'],s['n']['ru'],[[i[1],i[2]] for i in s['items']]] for s in data.S]
h=open('tpl.html').read().replace('__PH__',open('ph.json').read()).replace('__CO__',json.dumps(CO,ensure_ascii=False))
open('demo.html','w').write(h);print(len(h)//1024,'KB')
