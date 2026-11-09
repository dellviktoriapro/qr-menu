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

# Owner report is compiled from original app renderers, not independently redesigned.
import runpy
report_builder=runpy.run_path(str(here/'build-report.py'))
(here/'report-ui.js').write_text(report_builder['build'](),encoding='utf-8')
for name in ['report-core.js','report-ui.js','report.css']:
    shutil.copyfile(here/name,out/name)

staff_builder=runpy.run_path(str(here/'build-staff.py'))
(here/'staff-ui.js').write_text(staff_builder['build'](),encoding='utf-8')
for name in ['staff-client.js','staff-invite.js','staff-ui.js','staff.css']:
    shutil.copyfile(here/name,out/name)
shutil.copyfile(here/'vendor/qrcode-1.0.0.min.js',out/'qrcode-1.0.0.min.js')

incoming_builder=runpy.run_path(str(here/'build-incoming.py'))
(here/'incoming-ui.js').write_text(incoming_builder['build'](),encoding='utf-8')
for name in ['incoming-ui.js','guest-incoming.css']:
    shutil.copyfile(here/name,out/name)
