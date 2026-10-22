"""Rebuild every published page of the site from _src/.
Run from the repo root:  python _src/build_all.py
Needs: Python 3 + Pillow (pip install pillow).
Writes: demo/index.html, chez-oanh/index.html + ph1..N.js, sun-sea/index.html + ph1..N.js, lam-tong/index.html"""
import os,subprocess,sys
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC=os.path.join(ROOT,'_src')
HEAD='<!doctype html>\n<html lang="ru">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n</head>\n<body>\n'
def run(d,*a):subprocess.run([sys.executable,*a],cwd=os.path.join(SRC,d),check=True)
def wrap(src,dst):
    os.makedirs(os.path.dirname(dst),exist_ok=True)
    open(dst,'w',encoding='utf-8').write(HEAD+open(src,encoding='utf-8').read()+'</body></html>')
# 1) staff app: ops/tpl.html (base, Vietnamese UI) -> demo/mk.py (RU strings + auto language) -> demo/build.py (inject icons)
run('demo','mk.py');run('demo','build.py')
wrap(os.path.join(SRC,'demo','demo.html'),os.path.join(ROOT,'demo','index.html'))
# 2) Chez Oanh menu, light web build: text page + photo chunks
run('chez','build_web.py',os.path.join(ROOT,'chez-oanh'))
# 2b) Sun&Sea Restaurant (Mui Ne) menu: same engine as Chez Oanh (chez/tpl.html), own data, photos and look
run('sunsea','build_web.py',os.path.join(ROOT,'sun-sea'))
# 3) Lam Tong menu (single file)
run('lam-tong','build.py')
wrap(os.path.join(SRC,'lam-tong','lam-tong-menu.html'),os.path.join(ROOT,'lam-tong','index.html'))
print('ok')
