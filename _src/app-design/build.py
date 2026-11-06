from pathlib import Path
import shutil
source=Path(__file__).resolve().parent
target=source.parents[1]/'app/design'
target.mkdir(parents=True,exist_ok=True)
for name in ['index.html','board.css','board.js','screen.html','screen.css','screen.js','themes.js','fonts.css','compare.html']:
    shutil.copyfile(source/name,target/name)
shutil.copytree(source/'fonts',target/'fonts',dirs_exist_ok=True)
print('Built isolated design comparison:',target)
