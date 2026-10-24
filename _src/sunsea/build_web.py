"""Sun&Sea Restaurant (Mui Ne) menu.
Same engine as Chez Oanh: takes ../chez/tpl.html, applies the coastal skin in skin.css and swaps the cafe-specific texts. All features stay: language choice, table QR orders,
separate checks, bill / QR payment / tips, live status, stop list, review request.
Run from the repo root through build_all.py, or:  cd _src/sunsea && python build_web.py ../../sun-sea"""
import json, os, shutil, hashlib, sys, re
from PIL import Image
from concurrent.futures import ThreadPoolExecutor
import data

SERVICE_CONFIG=json.load(open('service-mode.json',encoding='utf-8-sig'))
SERVICE_MODE=os.environ.get('SUNSEA_SERVICE_MODE',SERVICE_CONFIG['mode'])
assert SERVICE_MODE in ('menu_only','full'), SERVICE_MODE
MENU_ONLY=SERVICE_MODE=='menu_only'

OUT = sys.argv[1] if len(sys.argv) > 1 else '../../sun-sea'
shutil.rmtree(OUT, ignore_errors=True); os.makedirs(OUT)

def save_webp(src, maxw, quality, name, fingerprint=False):
    cache_root = os.environ.get('SUNSEA_WEBP_CACHE')
    cache_key = hashlib.sha256(open(src, 'rb').read() + f'|{maxw}|{quality}|webp6'.encode()).hexdigest()
    cache_file = os.path.join(cache_root, cache_key + '.webp') if cache_root else None
    if cache_root:
        os.makedirs(cache_root, exist_ok=True)
    im = Image.open(src)
    im = im.convert('RGBA' if 'A' in im.getbands() else 'RGB')
    im.thumbnail((maxw, maxw), Image.Resampling.LANCZOS)
    path = os.path.join(OUT, name)
    if cache_file and os.path.isfile(cache_file):
        shutil.copyfile(cache_file, path)
    else:
        im.save(path, 'WEBP', quality=quality, method=6)
        if cache_file:
            shutil.copyfile(path, cache_file)
    if fingerprint:
        stem, ext = os.path.splitext(name)
        final = stem + '-' + hashlib.sha256(open(path, 'rb').read()).hexdigest()[:10] + ext
        os.replace(path, os.path.join(OUT, final))
        return final
    return name

# Only approved cutouts enter the new menu; original JPG scans remain source material.
# New PNG/WebP cutouts are picked up automatically without changing menu IDs or prices.
def photo_path(k):
    if k:
        for ext in ('png', 'webp'):
            path = f'ph/{k}.{ext}'
            if os.path.isfile(path):
                return path
    return None

has = lambda k: bool(photo_path(k))
# ---- data for the page (photos only where we already have them)
D = [dict(id=s['id'], n=s['n'], note=s['note'], g=s['g'], items=[[i[0], i[1], i[2], i[3], i[4],
      ([[l, p] for l, p in i[5]] if isinstance(i[5], list) else i[5]), i[6] if has(i[6]) else None] + ([i[7]] if len(i) > 7 and i[7] else [])
      for i in s['items']]) for s in data.S]
CAT = {s['id']: next((i[6] for i in s['items'] if has(i[6])), None) for s in data.S}
# Drink photograph mapping preserves the source records and order keys.
drink_photos=json.load(open('drink-photos.json',encoding='utf-8'))
for section in D:
    for index,item in enumerate(section['items']):
        key=drink_photos.get(f"{section['id']}|{index}")
        if key and has(key): item[6]=key
CAT={section['id']:next((item[6] for item in section['items'] if item[6]),None) for section in D}
# Short Russian navigation/title, without altering the original dish records.
next(s for s in D if s['id'] == 'ss_chef')['n'] = dict(next(s for s in D if s['id'] == 'ss_chef')['n'], ru='От шефа')
order = [k for k in CAT.values() if k] + [i[6] for s in D for i in s['items'] if has(i[6])]
order = list(dict.fromkeys(order))
# Independent cacheable images: thumbnails load lazily, full-size only on tap.
os.makedirs(os.path.join(OUT, 'images'))
# Independent files encode concurrently; preserve stable data order in the final maps.
with ThreadPoolExecutor(max_workers=4) as pool:
    thumbs = {k: pool.submit(save_webp, photo_path(k), 480, 76, f'images/{k}-480.webp', True) for k in order}
    details = {k: pool.submit(save_webp, photo_path(k), 960, 82, f'images/{k}-960.webp', True) for k in order}
    photos = {k: job.result() for k, job in thumbs.items()}
    full = {k: job.result() for k, job in details.items()}
save_webp('amb/hero.webp', 1600, 76, 'hero.webp')
save_webp('amb/hero-mobile.webp' if os.path.isfile('amb/hero-mobile.webp') else 'amb/hero.webp', 640, 72, 'hero-mobile.webp')
BAND = 'hero.webp?v=' + hashlib.sha256(open(os.path.join(OUT, 'hero.webp'), 'rb').read()).hexdigest()[:10]
MOBILE = 'hero-mobile.webp?v=' + hashlib.sha256(open(os.path.join(OUT, 'hero-mobile.webp'), 'rb').read()).hexdigest()[:10]
shutil.copyfile('ICON_LICENSES.md', os.path.join(OUT, 'ICON_LICENSES.md'))
shutil.copyfile('amb/squid.svg', os.path.join(OUT, 'squid.svg'))
shutil.copytree('fonts', os.path.join(OUT, 'fonts'))
COAST={}
for asset in ['coast-right','botanical-edge']:
    source='amb/' + asset + '.png'
    key=hashlib.sha256(open(source,'rb').read()+b'|coast640q80webp6').hexdigest()
    cache_root=os.environ.get('SUNSEA_WEBP_CACHE')
    cached=os.path.join(cache_root,key+'.webp') if cache_root else None
    target=os.path.join(OUT,asset+'.webp')
    if cached and os.path.isfile(cached):
        shutil.copyfile(cached,target)
    else:
        art=Image.open(source).convert('RGBA')
        art.thumbnail((640,1280),Image.Resampling.LANCZOS)
        art.save(target,'WEBP',quality=80,method=6)
        if cached: shutil.copyfile(target,cached)
    name=asset+'-'+hashlib.sha256(open(target,'rb').read()).hexdigest()[:10]+'.webp'
    os.replace(target,os.path.join(OUT,name));COAST[asset+'.webp']=name

s = open('../chez/tpl.html', encoding='utf-8').read()
def rep(a, b, cnt=1):
    global s
    assert s.count(a) == cnt, (a[:90], s.count(a))
    s = s.replace(a, b)

# ---- section header: title, then a ribbon "СУПЫ • SOUPS • SÚP"
rep('<span class="vi">${esc(lang==="vi"?s.n.en:s.n.vi)}</span><h2>${esc(title)}</h2>', '<h2>${esc(title)}</h2><span class="vi">${esc([...new Set(["ru","en","vi"].filter(k=>k!==lang).map(k=>s.n[k]))].join(" • "))}</span>')
# ---- identity
rep('<title>Café Chez Oanh Menu</title>', '<title>Sun&amp;Sea Restaurant · Mui Ne · Menu</title>')
rep('family=Cormorant+Garamond:ital,wght@0,500;0,600;0,700;1,500;1,600&family=Montserrat:wght@400;500;600;700',
    'family=Cormorant+Garamond:wght@600&family=Lora:wght@500;600&family=Caveat:wght@600&family=Manrope:wght@400;500;600;700;800')
rep('    <div class="eyebrow">Phan Thiết · Hàm Tiến</div>\n    <h2>Café Chez Oanh<em>Sofa Café</em></h2>',
    '    <div class="eyebrow">Mui Ne · Phan Thiết</div>\n    <h2 class="logo">Sun&amp;Sea<em>Mũi Né</em></h2>')
rep('''    <h1>Café Chez Oanh<em>Sofa Café · Hàm Tiến</em></h1>
    <div class="hmeta"><span class="tchip" id="tChip" hidden></span><a class="hlink" href="#about" id="aboutLnk"></a></div>''',
    '''    <h1 class="logo">Sun&amp;Sea<em>Mũi Né</em></h1>''')
rep('<!-- search, food / drinks', '<div class="wrap hsub"><div class="hmeta"><span class="tchip" id="tChip" hidden></span><a class="hlink" href="#about" id="aboutLnk"></a></div></div>\n<!-- search, food / drinks')
rep('<h3 id="abH">Café Chez Oanh</h3>', '<h3 id="abH" class="logo">Sun&amp;Sea<em>Restaurant · Mui Ne</em></h3>')
a = s.index('  <div class="facts">'); b = s.index('  <div class="feat">')
s = s[:a] + '''  <div class="facts">
      <div class="fact"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 21s-7-6.2-7-11.5A7 7 0 0119 9.5C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/></svg><div><small id="fAddr"></small>Mũi Né, Phan Thiết</div></div>
      <div class="fact"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M8 12h8M12 8v8"/></svg><div><small id="fHours"></small><span id="fCur"></span></div></div>
      <span hidden id="wifiBtn"></span>
    </div>
''' + s[b:]
rep('<b id="f2t"></b><span>7:00 – 22:00</span>', '<b id="f2t"></b><span id="f2s"></span>')
a = s.index('  <div class="cols">'); b = s.index('  <div class="small" id="foot"></div>')
s = s[:a] + '  <div class="cols"><div><b>Sun&amp;Sea Restaurant</b><br>Mũi Né, Phan Thiết</div><div><b id="ftH"></b><br><span id="ftC"></span></div></div>\n' + s[b:]

# ---- separate storage for this menu (cart, checks, table) and its own channel to the staff app's Sun&Sea venue (ss_inbox, ss_pub)
for k in ['co_cart', 'co_wish', 'co_ck', 'co_guest', 'co_tbl', 'co_lang', 'co_cur', 'co_inbox', 'co_pub']:
    s = s.replace(f'"{k}"', f'"ss_{k[3:]}"')

# ---- texts
NEW = {
 'ru': dict(tag='Sun&Sea Restaurant в Муйне: морепродукты, вьетнамская и тайская кухня, пицца, паста и фирменные блюда от шефа. Закажите прямо с телефона — официант подтвердит заказ у стола.',
            hours='Цены', f1t='От шеф-повара', f1s='Фирменные блюда', f2t='Свежесть и качество', f2s='Морепродукты каждый день', f3t='Копчение 12 часов', f3s='На древесных углях',
            abE='О ресторане', aboutL='Информация о ресторане', addr='Где мы', foot='Цены указаны в донгах (VND). Спасибо, что выбрали Sun&Sea! See you again!', cur='Цены в донгах (VND)'),
 'en': dict(tag='Sun&Sea Restaurant in Mui Ne: seafood, Vietnamese and Thai cuisine, pizza, pasta and chef’s specials. Order right from your phone; the waiter confirms it at your table.',
            hours='Prices', f1t='From the chef', f1s='Signature dishes', f2t='Fresh & quality', f2s='Seafood every day', f3t='Smoked 12 hours', f3s='Over natural charcoal',
            abE='About us', aboutL='About the restaurant', addr='Where we are', foot='Prices are in Vietnamese dong (VND). Thank you for choosing Sun&Sea. See you again!', cur='Prices in VND'),
 'vi': dict(tag='Nhà hàng Sun&Sea ở Mũi Né: hải sản, món Việt và Thái, pizza, mì Ý và món đặc biệt của bếp trưởng. Gọi món ngay trên điện thoại, nhân viên sẽ xác nhận tại bàn.',
            hours='Giá', f1t='Từ bếp trưởng', f1s='Món đặc trưng', f2t='Tươi ngon & chất lượng', f2s='Hải sản mỗi ngày', f3t='Xông khói 12 giờ', f3s='Trên than gỗ tự nhiên',
            abE='Về nhà hàng', aboutL='Về nhà hàng', addr='Địa chỉ', foot='Giá tính bằng đồng (VND). Cảm ơn bạn đã chọn Sun&Sea. Hẹn gặp lại!', cur='Giá tính bằng VND'),
 'ko': dict(tag='무이네의 Sun&Sea 레스토랑: 해산물, 베트남·태국 요리, 피자, 파스타, 셰프 스페셜. 휴대폰으로 바로 주문하면 직원이 테이블에서 확인합니다.',
            hours='가격', f1t='셰프 추천', f1s='시그니처 요리', f2t='신선함과 품질', f2s='매일 해산물', f3t='12시간 훈연', f3s='천연 숯불',
            abE='레스토랑 소개', aboutL='레스토랑 소개', addr='위치', foot='가격은 베트남 동(VND) 기준입니다. Sun&Sea를 찾아 주셔서 감사합니다!', cur='가격 단위 VND'),
 'zh': dict(tag='美奈 Sun&Sea 餐厅：海鲜、越南与泰国菜、披萨、意面和主厨特色菜。用手机直接下单，服务员会到桌确认。',
            hours='价格', f1t='主厨推荐', f1s='招牌菜', f2t='新鲜与品质', f2s='每日海鲜', f3t='熏制12小时', f3s='天然木炭',
            abE='关于我们', aboutL='关于餐厅', addr='位置', foot='价格以越南盾（VND）计。感谢选择 Sun&Sea，期待再见！', cur='价格单位 VND'),
}
NOTES = {
 'ru': dict(chef='Фирменные блюда нашего шефа.', pies='Съешь меня 😋', pizza='Good pizza brings good people.', oysters='Свежие — сочные — незабываемые! Цена за одну устрицу.', souvenir='Сувенир из Вьетнама: сделано во Вьетнаме, удобно взять с собой. Продаётся с 18 лет.'),
 'en': dict(chef="Our chef's signature dishes.", pies='Eat me 😋', pizza='Good pizza brings good people.', oysters='Fresh, juicy, unforgettable! Price per oyster.', souvenir='Made in Vietnam, a perfect souvenir, easy to carry. 18+ only.'),
 'vi': dict(chef='Món đặc biệt của bếp trưởng.', pies='Ăn tôi 😋', pizza='Good pizza brings good people.', oysters='Tươi ngon, đậm đà, khó quên! Giá cho 1 con.', souvenir='Sản xuất tại Việt Nam, quà lưu niệm tiện mang theo. Chỉ bán cho người từ 18 tuổi.'),
 'ko': dict(chef='셰프의 시그니처 요리.', pies='먹어 봐요 😋', pizza='Good pizza brings good people.', oysters='신선하고 잊을 수 없는 맛! 1개 가격.', souvenir='베트남산 기념품, 휴대하기 좋아요. 18세 이상.'),
 'zh': dict(chef='主厨招牌菜。', pies='吃我 😋', pizza='Good pizza brings good people.', oysters='新鲜多汁，难以忘怀！单只价格。', souvenir='越南制造，伴手礼首选，方便携带。仅限18岁以上。'),
}
inj = ''.join(f'Object.assign(T.{L},{json.dumps(d, ensure_ascii=False)});Object.assign(T.{L}.notes||(T.{L}.notes={{}}),{json.dumps(NOTES[L], ensure_ascii=False)});\n' for L, d in NEW.items())
rep('\nfunction pl(n,f){', '\n' + inj + 'function pl(n,f){')
rep('$("foot").textContent=t.foot;', '$("foot").textContent=t.foot;if($("f2s"))$("f2s").textContent=t.f2s;$("fCur").textContent=t.cur;$("ftC").textContent=t.cur;')
rep('$("gI1").src=AMB.interior;$("gI2").src=AMB.terrace;$("gI3").src=AMB.impala;$("gI4").src=AMB.zebras;', '')
rep('function openState(){', 'function openState(){$("open").hidden=true;return;')

# ---- Sun&Sea-only visual layer: leave the shared Chez Oanh engine untouched.
rep('  color-scheme:dark;', '  color-scheme:light;')
font_css = open('fonts/fonts.css', encoding='utf-8').read()
skin_css=open('skin.css',encoding='utf-8').read()
for original,optimized in COAST.items(): skin_css=skin_css.replace(original,optimized)
skin_css=skin_css.replace('url(hero-mobile.webp)','url('+MOBILE+')')
rep('</style>', font_css + '\n' + skin_css + '\n</style>')

rep('<h3 id="sheetH"></h3>', '<h3 id="sheetH"></h3><span class="cart-shadow" aria-hidden="true"><svg viewBox="0 0 24 24"><g fill="none" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" d="M2 17h20"/><path stroke-linejoin="round" d="M12 7s1.5-1.034 1.5-2.309c0-2.255-3-2.255-3 0C10.5 5.966 12 7 12 7Z"/><path stroke-linecap="round" d="m3 17l.621 2.485A2 2 0 0 0 5.561 21h12.877a2 2 0 0 0 1.94-1.515L21 17m-.5-2.5C20.002 10.277 16.386 7 12 7s-8.002 3.277-8.5 7.5"/></g></svg></span>')
rep('const GC=["#f2b65c","#7fd6d0","#e9846f","#b9a1e6","#9fd49a","#f0c3a0"];', 'const GC=["#dfded4","#cbcbbf","#b8baad","#e9e7df","#d4d3c8","#c1c2b6"];')
# Decorative section artwork uses the approved thin icon shapes, without extra downloads.
rep('<h2>${esc(title)}</h2>', '<div class="section-heading-line"><h2>${esc(title)}</h2><span class="section-shadow" aria-hidden="true">${coastIcon(s.id)}</span></div>')
# Lightweight category links, no circular crops of plates or initial-letter placeholders.
old_cat = '${p?`<img src="${PH[p]}" alt="">`:`<i class="ini">${esc(s.n[lang][0])}</i>`}'
rep(old_cat, '${coastIcon(s.id)}')
rep('<a class="cat" href="#${s.id}"', '<a class="cat${s.id===DATA.find(x=>x.g===group).id?" on":""}" href="#${s.id}"')
# On desktop the sidebar is below the panoramic header. Its height must not be
# subtracted from section anchors; mobile uses the real two-row sticky toolbar.
rep('$("stick").offsetHeight', '(matchMedia("(min-width:1100px)").matches?16:$("stick").offsetHeight)', cnt=2)
# Keep sidebar active link visible vertically without hijacking the document scroll.
rep('r.scrollTo({left:a.offsetLeft-r.clientWidth/2+a.clientWidth/2,behavior:"smooth"})',
    'r.scrollTo({left:a.offsetLeft-r.clientWidth/2+a.clientWidth/2,top:a.offsetTop-r.clientHeight/2+a.clientHeight/2,behavior:matchMedia("(prefers-reduced-motion: reduce)").matches?"instant":"smooth"})')

# One responsive navigation: sidebar on desktop, top toolbar on phones.
rep('function renderCats(){', open('skin.js', encoding='utf-8').read() + '\nfunction renderCats(){')
# The existing currency selector remains available in the search toolbar.
rate='<div class="rate"><select class="cur" id="cur" aria-label="Currency"></select><span id="rate"></span></div>'
rep('  ' + rate + '\n', '')
language_button=re.search(r'<button class="langbtn".*?</button>', s).group(0)
rep(language_button, '')
rep('<div class="srow">', '<div class="srow"><div class="nav-info"><a class="restaurant-info" href="#about" id="aboutLnk"></a>' + language_button + '</div>' + rate)
rep('<a class="hlink" href="#about" id="aboutLnk"></a>', '')
# Hidden section medals were still requesting images, despite display:none.
rep('<div class="medals">${md.map(p=>`<img src="${PH[p]}" alt="">`).join("")}</div>', '')
rep('<img loading="lazy" src="${PH[ph]}" alt="${esc(name)}">', '<img loading="lazy" decoding="async" src="${BL}" data-menu-src="${PH[ph]}" alt="${esc(name)}">')
rep('  $("menu").innerHTML=html||`<div class="empty">${esc(t.none)}</div>`;', '  $("menu").innerHTML=html||`<div class="empty">${esc(t.none)}</div>`;observeMenuPhotos();')

# Always provide a description slot; shared rows align without inventing ingredients.
rep('${descHTML(it)}${noteHTML(it)}${optsHTML(s,i,it,t)}</div></article>', '<div class="dish-description">${descHTML(it)}${noteHTML(it)}</div>${optsHTML(s,i,it,t)}</div></article>')
# Text-only dishes share the same description slot and price rhythm as photo dishes.
rep('${descHTML(it)}${noteHTML(it)}${optsHTML(s,i,it,t)}</div></li>', '<div class="dish-description">${descHTML(it)}${noteHTML(it)}</div>${optsHTML(s,i,it,t)}</div></li>')
# Keep order IDs stable: sort the display tuples, never the underlying dish data.
rep('items.forEach(([it,i])=>{', 'items.sort(([a],[b])=>{const rank=k=>({fish_beer:0,fish_lemon:1,smoked_mash:2,fish_corn:3})[k]??99;return rank(a[6])-rank(b[6])}).forEach(([it,i])=>{')
# Three large dishes per row as in the approved preview, even on wide screens.
# Full-resolution images are requested only from the dish sheet/lightbox.
rep('const PH=new Proxy', 'const FULL=' + json.dumps(full) + ';\nconst PH=new Proxy')
rep('$("dImg").src=PH[ph]', '$("dImg").src=FULL[ph]||PH[ph]')
rep('$("lbImg").src=PH[it[6]]', '$("lbImg").src=FULL[it[6]]||PH[it[6]]')
rep('$("lbImg").src=PH[b.dataset.ph]', '$("lbImg").src=FULL[b.dataset.ph]||PH[b.dataset.ph]')
# Local font subsets load directly from the site, without a late external stylesheet.
font_link = re.search(r'<link rel="stylesheet" href="https://fonts.googleapis.com/[^"]+">', s).group(0)
preloads = []
for subset, block in re.findall(r'/\* ([^*]+) \*/\s*(@font-face\s*\{[^}]+\})', font_css):
    family = re.search(r"font-family: '([^']+)'", block).group(1)
    if subset in ['latin', 'cyrillic'] and (family != 'Cormorant Garamond' or subset == 'latin'):
        url = re.search(r'url\(([^)]+)\)', block).group(1)
        preloads.append(f'<link rel="preload" href="{url}" as="font" type="font/woff2" crossorigin>')
rep(font_link, '\n'.join(preloads))
s = re.sub(r'<link rel="preconnect" href="https://fonts\.(?:googleapis|gstatic)\.com"[^>]*>', '', s)
# Select the correct hero before the first background request, avoiding two downloads.
rep('$("heroBg").style.backgroundImage=`url(${AMB.lion})`;$("gateBg").style.backgroundImage=`url(${AMB.lion})`;',
    'const heroMedia=matchMedia("(max-width:699px)");function updateHero(){const heroURL=heroMedia.matches?' + json.dumps(MOBILE) + ':AMB.lion;$("heroBg").style.backgroundImage=`url(${heroURL})`;$("gateBg").style.backgroundImage=`url(${heroURL})`;}updateHero();heroMedia.addEventListener("change",updateHero);')

# Standalone sales mode is a reversible layer; the shared engine stays intact.
if MENU_ONLY:
    for key in ['cart','wish','ck','guest','tbl']:
        s=s.replace('ss_'+key,'ss_menu_'+key)
    rep('loadStop();\n','STOP=new Set();\n')
    rep('</style>',open('menu-only.css',encoding='utf-8-sig').read()+'\n</style>')
    config=dict(SERVICE_CONFIG)
    qr=config.get('paymentQr')
    if qr and not qr.startswith(('https://','data:image/')):
        assert re.fullmatch(r'[\w.-]+',qr), 'Use a QR image filename in amb/ or an HTTPS URL'
        shutil.copyfile('amb/'+qr,os.path.join(OUT,qr))
    mode_js='const SERVICE_CONFIG='+json.dumps(config,ensure_ascii=False).replace('<','\\u003c')+';\n'+open('menu-only.js',encoding='utf-8-sig').read()
    rep('(function init(){',mode_js+'\n(function init(){')

s = s.replace('__DATA__', json.dumps(D, ensure_ascii=False)).replace('__PH__', json.dumps(dict(photos, amb_lion=BAND))).replace('__AMB__', json.dumps({'lion': BAND})).replace('__GEN__', json.dumps(order)).replace('__CATPH__', '{}')

s = '<!doctype html>\n<html lang="ru">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n</head>\n<body>\n' + s + '</body></html>'
if MENU_ONLY: s=s.replace('<body>','<body class="menu-only">',1)
open(OUT + '/index.html', 'w', encoding='utf-8').write(s)
print('sun-sea', len(s.encode()) // 1024, 'KB HTML;', len(photos), 'photos;', sum(os.path.getsize(os.path.join(OUT, x)) for x in photos.values()) // 1024, 'KB thumbnails')
