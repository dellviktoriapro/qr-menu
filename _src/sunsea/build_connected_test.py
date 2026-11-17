"""Build one isolated, server-connected Sun&Sea menu beside the public menu.

The published sun-sea/index.html remains in standalone mode. This route uses the
same catalog and assets, but sends QR table orders to the staff application.
"""
from pathlib import Path
import hashlib
import os
import shutil
import subprocess
import sys
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
PUBLIC = ROOT / 'sun-sea'
STAGE = ROOT / '_build' / 'sunsea-connected-test'
assert STAGE.resolve() == (ROOT / '_build' / 'sunsea-connected-test').resolve()
assert PUBLIC.resolve() == (ROOT / 'sun-sea').resolve()

env = os.environ.copy()
env['SUNSEA_SERVICE_MODE'] = 'full'
env['SUNSEA_ASSET_SOURCE'] = str(PUBLIC)
env['PYTHONUTF8'] = '1'
subprocess.run([sys.executable, 'build_web.py', str(STAGE)], cwd=HERE, env=env, check=True)

# The full and standalone builds use the same image hashes. Reuse the public
# photo directory; copy only assets that differ so the test route remains small.
for source in STAGE.rglob('*'):
    if not source.is_file() or source.name == 'index.html':
        continue
    destination = PUBLIC / source.relative_to(STAGE)
    if not destination.exists() or hashlib.sha256(source.read_bytes()).digest() != hashlib.sha256(destination.read_bytes()).digest():
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)

html = (STAGE / 'index.html').read_text(encoding='utf-8')
# The public menu's banner-preview guard disables cart controls without its
# legacy query-string room token. This dedicated route uses a server QR token
# in the fragment, so keep the real ordering controls enabled here.
html, preview_count = re.subn(
    r'const PUBLIC_PREVIEW=\(\(\)=>\{.*?\}\)\(\);',
    'const PUBLIC_PREVIEW=false;',
    html,
    count=1,
    flags=re.S,
)
assert preview_count == 1
original = HERE.parent / 'chez' / 'guest-server.js'
adapter = original.read_text(encoding='utf-8')
adapter = adapter.replace(
    '/* Real server adapter for Chez Oanh only. Sun&Sea has its own independent cart. */',
    '/* Server-connected Sun&Sea guest orders; table QR and separate test entry QR. */',
    1,
)
assert "'chez|'+" in adapter and "ls.get('co_ck')" in adapter
adapter = adapter.replace('rp_chez_', 'rp_sunsea_test_')
adapter = adapter.replace("'chez|'+", "'sunsea|'+")
adapter = adapter.replace("i.key.slice(5)", "i.key.slice(7)")
adapter = adapter.replace("ls.get('co_ck')", "ls.get('ss_ck')")
adapter = adapter.replace(
    'STOP.has(key)||STOP.has(key.split(\'|\').slice(0,2).join(\'|\'))',
    "STOP.has('sunsea|'+key)||STOP.has('sunsea|'+key.split('|').slice(0,2).join('|'))",
)
adapter = adapter.replace("incoming=hash.get('table')", "incoming=hash.get('table'),entryIncoming=hash.get('entry')")
adapter = adapter.replace("allowNewVisit=valid(incoming);", "allowNewVisit=valid(incoming)||valid(entryIncoming);")
adapter = adapter.replace(
    "let token=valid(incoming)?incoming:sessionStorage.getItem('rp_sunsea_test_table'),testTable=!valid(incoming)&&!valid(sessionStorage.getItem('rp_sunsea_test_table'))?sessionStorage.getItem('rp_sunsea_test_test_table')||'':'',context=null,outbox=null,working=false;",
    "let token=valid(entryIncoming)?null:valid(incoming)?incoming:sessionStorage.getItem('rp_sunsea_test_table'),entryToken=valid(incoming)?null:valid(entryIncoming)?entryIncoming:sessionStorage.getItem('rp_sunsea_test_entry'),testTable=!valid(token)&&!valid(entryIncoming)?sessionStorage.getItem('rp_sunsea_test_test_table')||'':'',context=null,outbox=null,working=false;",
)
adapter = adapter.replace(
    "if(valid(incoming)){sessionStorage.setItem('rp_sunsea_test_table',incoming);history.replaceState(null,'',location.pathname+location.search)}",
    "if(valid(incoming)){sessionStorage.removeItem('rp_sunsea_test_entry');sessionStorage.setItem('rp_sunsea_test_table',incoming);history.replaceState(null,'',location.pathname+location.search)}if(valid(entryIncoming)){sessionStorage.removeItem('rp_sunsea_test_table');sessionStorage.removeItem('rp_sunsea_test_test_table');sessionStorage.setItem('rp_sunsea_test_entry',entryIncoming);history.replaceState(null,'',location.pathname+location.search)}",
)
adapter = adapter.replace(
    "if(!valid(token)&&!/^[1-9][0-9]{0,2}$/.test(testTable))throw Error('TEST_TABLE_UNAVAILABLE');const storageKey='rp_sunsea_test_visit:'+(valid(token)?token:'test:'+testTable);",
    "if(!valid(token)&&(!valid(entryToken)||!/^[1-9][0-9]{0,2}$/.test(testTable)))throw Error('TEST_TABLE_UNAVAILABLE');const storageKey='rp_sunsea_test_visit:'+(valid(token)?token:'test:'+entryToken+':'+testTable);",
)
adapter = adapter.replace("const open=()=>valid(token)?api.open(token,secret):api.testOpen(testTable,secret);", "const open=()=>valid(token)?api.open(token,secret):api.testOpen(testTable,secret,entryToken);")
adapter = adapter.replace(
    "if(!valid(token)&&!/^[1-9][0-9]{0,2}$/.test(testTable)){openPick();return}",
    "if(!valid(token)&&!valid(entryToken)){show(ui().scan);return}if(!valid(token)&&!/^[1-9][0-9]{0,2}$/.test(testTable)){openPick();return}",
)
adapter = adapter.replace("if(valid(token)||testTable)connect()", "if(valid(token)||valid(entryToken)&&testTable)connect()")
adapter = adapter.replace("openPick=()=>{const labels=", "openPick=()=>{if(!valid(entryToken)){show(ui().scan);return}const labels=")
assert "entryToken=valid(incoming)?null:valid(entryIncoming)" in adapter and "api.testOpen(testTable,secret,entryToken)" in adapter
assert "'sunsea|'+" in adapter and 'rp_sunsea_test_entry' in adapter
(PUBLIC / 'guest-server-test.js').write_text(adapter, encoding='utf-8')

html = html.replace('const paidChecks=()=>', 'let serverPaidChecks=null;const paidChecks=()=>serverPaidChecks?serverPaidChecks():')
html = html.replace('function loadStop(){let p={};try{p=JSON.parse(ls.get("ss_pub")||"{}")||{}}catch(e){}', 'function loadStop(){const p=PUB();')
html = html.replace('const isOut=key=>', 'let serverIsOut=null;const isOut=key=>serverIsOut?serverIsOut(key):')
assert 'let serverPaidChecks=null;' in html and 'function loadStop(){const p=PUB();' in html and 'let serverIsOut=null;' in html
assets = [
    (HERE.parent / 'staff-platform' / 'guest-outbox.js', 'guest-outbox.js'),
    (HERE.parent / 'staff-platform' / 'guest-api.js', 'guest-api.js'),
    (HERE.parent / 'staff-platform' / 'guest-service-core.js', 'guest-service-core.js'),
    (HERE.parent / 'staff-platform' / 'guest-line-options.js', 'guest-line-options.js'),
]
for source, name in assets:
    shutil.copyfile(source, PUBLIC / name)
api_path = PUBLIC / 'guest-api.js'
api_text = api_path.read_text(encoding='utf-8')
api_text = api_text.replace(
    "testOpen:(table_number,visit_secret)=>call('test_open',{table_number,visit_secret})",
    "testOpen:(table_number,visit_secret,entry_token)=>call('test_open',{table_number,visit_secret,entry_token})",
)
assert "entry_token)=>call('test_open'" in api_text
api_path.write_text(api_text, encoding='utf-8')
scripts = ''.join(
    '<script src="' + name + '?v=' + hashlib.sha256((PUBLIC / name).read_bytes()).hexdigest()[:12] + '"></script>'
    for _, name in assets
)
name = 'guest-server-test.js'
scripts += '<script src="' + name + '?v=' + hashlib.sha256((PUBLIC / name).read_bytes()).hexdigest()[:12] + '"></script>'
html = html.replace('</body>', '<!-- connected-test-guest -->' + scripts + '</body>')
(PUBLIC / 'test-order.html').write_text(html, encoding='utf-8')

# The stage contains only files this script generated; resolve and verify the
# target before removing the temporary full build.
assert STAGE.resolve().is_relative_to((ROOT / '_build').resolve())
shutil.rmtree(STAGE)
print('Built isolated Sun&Sea order test', PUBLIC / 'test-order.html')
