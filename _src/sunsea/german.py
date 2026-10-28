"""Strict German catalog localization without changing cart IDs or tuple fields."""
import json
from pathlib import Path
TRANSLATIONS = json.loads(Path(__file__).with_name('german-catalog.json').read_text(encoding='utf-8'))

def localize(sections):
    def translated(text):
        return TRANSLATIONS[text]  # Missing translations must fail the build.
    def walk(value):
        if isinstance(value, dict):
            if 'en' in value:
                value['de'] = translated(value['en'])
            else:
                for child in value.values():
                    walk(child)
        elif isinstance(value, list):
            for child in value:
                walk(child)
    for section in sections:
        walk(section['n'])
        walk(section['note'])
        for item in section['items']:
            while len(item) < 8:
                item.append({})
            walk(item[5])
            walk(item[7])
            item.append(translated(item[0]))  # Name at index 8; price/photo/extra stay at 5/6/7.
