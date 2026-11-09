"""Attach the reviewed server adapter to Chez Oanh without regenerating photos."""
from pathlib import Path
import re,shutil
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
def attach(html,out):
 out=Path(out).resolve()
 if out!=ROOT/'chez-oanh':raise ValueError('Expected the explicit Chez Oanh output directory')
 for source,name in [(HERE.parent/'staff-platform/guest-outbox.js','guest-outbox.js'),(HERE.parent/'staff-platform/guest-api.js','guest-api.js'),(HERE.parent/'staff-platform/guest-service-core.js','guest-service-core.js'),(HERE.parent/'staff-platform/guest-line-options.js','guest-line-options.js'),(HERE/'guest-server.js','guest-server.js')]:shutil.copyfile(source,out/name)
 html=html if 'let serverPaidChecks=null;' in html else html.replace('const paidChecks=()=>', 'let serverPaidChecks=null;const paidChecks=()=>serverPaidChecks?serverPaidChecks():').replace('let serverPaidChecks=null;let serverPaidChecks=null;', 'let serverPaidChecks=null;')
 html=html.replace('function loadStop(){let p={};try{p=JSON.parse(ls.get("co_pub")||"{}")||{}}catch(e){}', 'function loadStop(){const p=PUB();')
 html=html if 'let serverIsOut=null;' in html else html.replace('const isOut=key=>', 'let serverIsOut=null;const isOut=key=>serverIsOut?serverIsOut(key):')
 html=re.sub(r'<!-- connected-guest-start -->.*?<!-- connected-guest-end -->','',html,flags=re.S)
 scripts='<!-- connected-guest-start -->'+''.join('<script src="'+n+'?v=20261109-fixes2"></script>' for n in ['guest-outbox.js','guest-api.js','guest-service-core.js','guest-line-options.js','guest-server.js'])+'<!-- connected-guest-end -->'
 return html.replace('</body>',scripts+'</body>')
if __name__=='__main__':
 out=ROOT/'chez-oanh';p=out/'index.html';p.write_text(attach(p.read_text(encoding='utf-8'),out),encoding='utf-8')
