import json
h=open('tpl.html').read().replace('__PH__',open('ph.json').read())
open('demo.html','w').write(h);print(len(h)//1024,'KB')
