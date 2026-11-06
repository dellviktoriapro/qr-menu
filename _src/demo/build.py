import json
import sys;sys.path.insert(0,'../chez');import data
CO=[[s['id'],s['n']['vi'],s['n']['ru'],[[i[1],i[2]] for i in s['items']]] for s in data.S]
import importlib.util as _u
_sp=_u.spec_from_file_location('ssdata','../sunsea/data.py');ssd=_u.module_from_spec(_sp);_sp.loader.exec_module(ssd)
SS=[[s['id'],s['n']['vi'],s['n']['ru'],[[i[1],i[2]] for i in s['items']]] for s in ssd.S]
h=open('tpl.html').read().replace('__PH__',open('ph.json').read()).replace('__CO__',json.dumps(CO,ensure_ascii=False)).replace('__SS__',json.dumps(SS,ensure_ascii=False))
from pathlib import Path
import shutil
base=Path(__file__).resolve().parents[1]
h=h.replace('</style>',(base/'app-theme/staff-theme.css').read_text(encoding='utf-8')+'\n'+(base/'app-theme/platform-shell.css').read_text(encoding='utf-8')+'</style>',1)
h=h.replace('const CAFES=',(base/'app-design/themes.js').read_text(encoding='utf-8')+'\n'+(base/'app-theme/staff-theme.js').read_text(encoding='utf-8')+'\n'+(base/'app-theme/platform-chrome.js').read_text(encoding='utf-8')+'\nconst CAFES=',1)
h=h.replace('<link rel="preconnect" href="https://fonts.googleapis.com">','').replace('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700;800&family=Cormorant+Garamond:ital,wght@0,500;0,600;0,700;1,500;1,600&display=swap">','<link rel="stylesheet" href="fonts.css">')
out=base.parent/'demo';out.mkdir(exist_ok=True)
shutil.copyfile(base/'app-design/fonts.css',out/'fonts.css');shutil.copytree(base/'app-design/fonts',out/'fonts',dirs_exist_ok=True)
open('demo.html','w').write(h);print(len(h)//1024,'KB')
