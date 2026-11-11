"""Build an idempotent staff-catalog import; never edits the public Sun&Sea menu."""
import importlib.util
import argparse
import csv
import json
from pathlib import Path
from uuid import UUID

HERE = Path(__file__).resolve().parent
SOURCE = HERE.parent / 'sunsea'
spec = importlib.util.spec_from_file_location('sunsea_data', SOURCE / 'data.py')
data = importlib.util.module_from_spec(spec)
spec.loader.exec_module(data)
german_spec = importlib.util.spec_from_file_location('sunsea_german', SOURCE / 'german.py')
german = importlib.util.module_from_spec(german_spec)
german_spec.loader.exec_module(german)
for section in data.S:
    section['items'] = [list(item) for item in section['items']]
german.localize(data.S)
layout = json.loads((SOURCE / 'table-layout.json').read_text(encoding='utf-8-sig'))

def sql(value):
    if value is None:
        return 'null'
    if isinstance(value, (dict, list)):
        return "'" + json.dumps(value, ensure_ascii=False).replace("'", "''") + "'::jsonb"
    if isinstance(value, int):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"

rows = []
for section in data.S:
    station = 'bar' if section['g'] == 'drinks' else 'kitchen'
    for index, item in enumerate(section['items']):
        en, vi, ru, ko, zh, price, photo, extra, de = item
        names = dict(en=en, vi=vi, ru=ru, ko=ko, zh=zh, de=de)
        variants = price if isinstance(price, list) else [(None, price)]
        for variant_index, (label, amount) in enumerate(variants):
            item_names = {lang: text + (' · ' + (label.get(lang) or german.TRANSLATIONS[label['en']]) if label else '') for lang, text in names.items()}
            key = f"sunsea|{section['id']}|{index}" + (f'|{variant_index}' if label else '')
            if amount is not None and (not isinstance(amount, int) or amount < 0):
                raise ValueError(key)
            rows.append((key, item_names, station, amount))

keys = [row[0] for row in rows]
assert len(keys) == len(set(keys))
tables = layout['tables']
assert len({str(table['id']) for table in tables}) == len(tables)

lines = [
    '-- Generated from _src/sunsea/data.py and table-layout.json. Staff catalog only.',
    '-- Apply after the admin creates cafe slug sun-sea. Does not activate guest ordering.',
    'begin;',
    "do $$ begin if (select count(*) from public.rp_cafes where slug='sun-sea' and active) <> 1 then raise exception 'SUNSEA_CAFE_MISSING'; end if; end $$;",
    'insert into public.rp_tables(cafe_id,label,seats) values',
    ',\n'.join("((select id from public.rp_cafes where slug='sun-sea')," + sql(str(t['id'])) + ',' + sql(t['max']) + ')' for t in tables),
    'on conflict (cafe_id,label) do update set seats=excluded.seats,active=true;',
    'insert into public.rp_menu_items(cafe_id,external_key,names,station,price_minor) values',
    ',\n'.join("((select id from public.rp_cafes where slug='sun-sea')," + ','.join(sql(value) for value in row) + ')' for row in rows),
    'on conflict (cafe_id,external_key) do update set names=excluded.names,station=excluded.station,price_minor=excluded.price_minor;',
    'commit;',
]
target = HERE / 'sunsea-import.sql'
target.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f'{len(rows)} catalog variants, {len(tables)} tables -> {target}')

parser = argparse.ArgumentParser()
parser.add_argument('--cafe-id', help='Write CSV files for Supabase Table Editor')
parser.add_argument('--csv-dir', type=Path)
args = parser.parse_args()
if args.cafe_id:
    cafe_id = str(UUID(args.cafe_id))
    if args.csv_dir is None:
        parser.error('--csv-dir is required with --cafe-id')
    args.csv_dir.mkdir(parents=True, exist_ok=True)
    with (args.csv_dir / 'sunsea-tables.csv').open('w', encoding='utf-8-sig', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(('cafe_id', 'label', 'seats'))
        writer.writerows((cafe_id, str(table['id']), table['max']) for table in tables)
    with (args.csv_dir / 'sunsea-menu.csv').open('w', encoding='utf-8-sig', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(('cafe_id', 'external_key', 'names', 'station', 'price_minor'))
        writer.writerows((cafe_id, key, json.dumps(names, ensure_ascii=False), station, '' if amount is None else amount)
                         for key, names, station, amount in rows)
    print(f'CSV files -> {args.csv_dir}')
