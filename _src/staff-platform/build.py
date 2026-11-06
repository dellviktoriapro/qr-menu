"""Build the dedicated server app entry. Does not modify restaurant menus/demo."""
from pathlib import Path
import shutil
here=Path(__file__).resolve().parent
out=here.parents[1]/'app'
out.mkdir(exist_ok=True)
for src,dest in [('login.html','index.html'),('login.js','login.js'),('admin.js','admin.js'),('admin-inbox.js','admin-inbox.js'),('manual-ui.js','manual-ui.js'),('admin.css','admin.css'),('operations.js','operations.js'),('operations-core.js','operations-core.js'),('operations.css','operations.css'),('supabase-client.js','supabase-client.js')]:
    shutil.copyfile(here/src,out/dest)
print('Built app login',out)

shutil.copyfile(here.parent/'app-design/themes.js',out/'palettes.js')
shutil.copyfile(here.parent/'app-design/fonts.css',out/'fonts.css')
shutil.copytree(here.parent/'app-design/fonts',out/'fonts',dirs_exist_ok=True)

shutil.copyfile(here.parent/'app-theme/platform-shell.css',out/'platform-shell.css')
shutil.copyfile(here.parent/'app-theme/platform-chrome.js',out/'platform-chrome.js')
