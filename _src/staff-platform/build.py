"""Build the dedicated server app entry. Does not modify restaurant menus/demo."""
from pathlib import Path
import shutil
here=Path(__file__).resolve().parent
out=here.parents[1]/'app'
out.mkdir(exist_ok=True)
for src,dest in [('login.html','index.html'),('login.js','login.js'),('admin.js','admin.js'),('admin-inbox.js','admin-inbox.js'),('manual-ui.js','manual-ui.js'),('admin.css','admin.css'),('supabase-client.js','supabase-client.js')]:
    shutil.copyfile(here/src,out/dest)
print('Built app login',out)
