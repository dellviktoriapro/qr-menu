"""Attach the reviewed server adapter to Chez Oanh without regenerating photos."""
from pathlib import Path
import re,shutil
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
def attach(html,out):
 out=Path(out).resolve()
 if out!=ROOT/'chez-oanh':raise ValueError('Expected the explicit Chez Oanh output directory')
 for source,name in [(HERE.parent/'staff-platform/guest-outbox.js','guest-outbox.js'),(HERE.parent/'staff-platform/guest-api.js','guest-api.js'),(HERE/'guest-server.js','guest-server.js')]:shutil.copyfile(source,out/name)
 html=re.sub(r'<!-- connected-guest-start -->.*?<!-- connected-guest-end -->','',html,flags=re.S)
 scripts='<!-- connected-guest-start -->'+''.join('<script src="'+n+'?v=20261109-guest1"></script>' for n in ['guest-outbox.js','guest-api.js','guest-server.js'])+'<!-- connected-guest-end -->'
 return html.replace('</body>',scripts+'</body>')
if __name__=='__main__':
 out=ROOT/'chez-oanh';p=out/'index.html';p.write_text(attach(p.read_text(encoding='utf-8'),out),encoding='utf-8')
