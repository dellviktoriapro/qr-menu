"""Sun&Sea Restaurant (Mui Ne) menu.
Same engine as Chez Oanh: takes ../chez/tpl.html, applies the coastal skin in skin.css and swaps the cafe-specific texts. All features stay: language choice, table QR orders,
separate checks, bill / QR payment / tips, live status, stop list, review request.
Run from the repo root through build_all.py, or:  cd _src/sunsea && python build_web.py ../../sun-sea"""
import json, os, shutil, base64, io, sys, re
from PIL import Image
import data

OUT = sys.argv[1] if len(sys.argv) > 1 else '../../sun-sea'
shutil.rmtree(OUT, ignore_errors=True); os.makedirs(OUT)

def webp(src, maxw, q=80):
    im = Image.open(src).convert('RGBA')
    if im.width > maxw: im = im.resize((maxw, round(im.height * maxw / im.width)), Image.LANCZOS)
    b = io.BytesIO(); im.save(b, 'WEBP', quality=q, method=6); return 'data:image/webp;base64,' + base64.b64encode(b.getvalue()).decode()

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
# Short Russian navigation/title, without altering the original dish records.
next(s for s in D if s['id'] == 'ss_chef')['n'] = dict(next(s for s in D if s['id'] == 'ss_chef')['n'], ru='От шефа')
order = [k for k in CAT.values() if k] + [i[6] for s in data.S for i in s['items'] if has(i[6])]
order = list(dict.fromkeys(order))
items = [(k, webp(photo_path(k), 1000, 88)) for k in order]
chunks = []; cur = []; size = 0
for k, v in items:
    cur.append((k, v)); size += len(v)
    if size > 650_000: chunks.append(cur); cur = []; size = 0
if cur: chunks.append(cur)
for n, c in enumerate(chunks, 1):
    open(f'{OUT}/ph{n}.js', 'w').write('__ph(' + json.dumps(dict(c)) + ');')
# Hero is a separate cacheable WebP; keep the menu text light.
shutil.copyfile('amb/hero.webp', os.path.join(OUT, 'hero.webp'))
BAND = 'hero.webp'

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
    'family=Cormorant+Garamond:wght@500;600;700&family=Manrope:wght@400;500;600;700;800')
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
            abE='О ресторане', aboutL='О ресторане', addr='Где мы', foot='Цены указаны в донгах (VND). Спасибо, что выбрали Sun&Sea! See you again!', cur='Цены в донгах (VND)'),
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
 'ru': dict(chef='Фирменные блюда нашего шефа. Рыба и креветки горячего копчения — по предзаказу за 1 день, цену уточняйте у официанта.', pies='Съешь меня 😋 Фирменные пироги от шефа.', pizza='Good pizza brings good people.', oysters='Свежие — сочные — незабываемые! Цена за одну устрицу.', souvenir='Сувенир из Вьетнама: сделано во Вьетнаме, удобно взять с собой. Продаётся с 18 лет.'),
 'en': dict(chef="Our chef's signature dishes. Hot smoked fish and shrimps: pre-order 1 day in advance, please check the price with us.", pies='Eat me 😋 Signature pies by the chef.', pizza='Good pizza brings good people.', oysters='Fresh, juicy, unforgettable! Price per oyster.', souvenir='Made in Vietnam, a perfect souvenir, easy to carry. 18+ only.'),
 'vi': dict(chef='Món đặc biệt của bếp trưởng. Cá và tôm hun khói: đặt trước 1 ngày, vui lòng hỏi giá tại nhà hàng.', pies='Ăn tôi 😋 Bánh pie đặc trưng từ bếp trưởng.', pizza='Good pizza brings good people.', oysters='Tươi ngon, đậm đà, khó quên! Giá cho 1 con.', souvenir='Sản xuất tại Việt Nam, quà lưu niệm tiện mang theo. Chỉ bán cho người từ 18 tuổi.'),
 'ko': dict(chef='셰프의 시그니처 요리. 훈제 생선과 새우는 하루 전 예약, 가격은 직원에게 문의하세요.', pies='먹어 봐요 😋 셰프의 시그니처 파이.', pizza='Good pizza brings good people.', oysters='신선하고 잊을 수 없는 맛! 1개 가격.', souvenir='베트남산 기념품, 휴대하기 좋아요. 18세 이상.'),
 'zh': dict(chef='主厨招牌菜。热熏鱼和熏虾需提前1天预订，价格请向店员咨询。', pies='吃我 😋 主厨招牌馅饼。', pizza='Good pizza brings good people.', oysters='新鲜多汁，难以忘怀！单只价格。', souvenir='越南制造，伴手礼首选，方便携带。仅限18岁以上。'),
}
inj = ''.join(f'Object.assign(T.{L},{json.dumps(d, ensure_ascii=False)});Object.assign(T.{L}.notes||(T.{L}.notes={{}}),{json.dumps(NOTES[L], ensure_ascii=False)});\n' for L, d in NEW.items())
rep('\nfunction pl(n,f){', '\n' + inj + 'function pl(n,f){')
rep('$("foot").textContent=t.foot;', '$("foot").textContent=t.foot;if($("f2s"))$("f2s").textContent=t.f2s;$("fCur").textContent=t.cur;$("ftC").textContent=t.cur;')
rep('$("gI1").src=AMB.interior;$("gI2").src=AMB.terrace;$("gI3").src=AMB.impala;$("gI4").src=AMB.zebras;', '')
rep('function openState(){', 'function openState(){$("open").hidden=true;return;')

# ---- Sun&Sea-only visual layer: leave the shared Chez Oanh engine untouched.
rep('  color-scheme:dark;', '  color-scheme:light;')
rep('</style>', open('skin.css', encoding='utf-8').read() + '\n</style>')

# Lightweight category links, no circular crops of plates or initial-letter placeholders.
old_cat = '${p?`<img src="${PH[p]}" alt="">`:`<i class="ini">${esc(s.n[lang][0])}</i>`}'
rep(old_cat, '')
rep('<a class="cat" href="#${s.id}"', '<a class="cat${s.id===DATA.find(x=>x.g===group).id?" on":""}" href="#${s.id}"')
# On desktop the sidebar is below the panoramic header. Its height must not be
# subtracted from section anchors; mobile uses the real two-row sticky toolbar.
rep('$("stick").offsetHeight', '(matchMedia("(min-width:1100px)").matches?16:$("stick").offsetHeight)', cnt=2)
# Keep sidebar active link visible vertically without hijacking the document scroll.
rep('r.scrollTo({left:a.offsetLeft-r.clientWidth/2+a.clientWidth/2,behavior:"smooth"})',
    'r.scrollTo({left:a.offsetLeft-r.clientWidth/2+a.clientWidth/2,top:a.offsetTop-r.clientHeight/2+a.clientHeight/2,behavior:matchMedia("(prefers-reduced-motion: reduce)").matches?"instant":"smooth"})')

s = s.replace('__DATA__', json.dumps(D, ensure_ascii=False)).replace('__PH__', json.dumps({'amb_lion': BAND})).replace('__AMB__', json.dumps({'lion': BAND})).replace('__GEN__', json.dumps(order)).replace('__CATPH__', '{}')
s += '<script>(function n(i){if(i>%d)return;var e=document.createElement("script");e.src="ph"+i+".js";e.onload=e.onerror=function(){n(i+1)};document.body.appendChild(e)})(1)</script>' % len(chunks)
s = '<!doctype html>\n<html lang="ru">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n</head>\n<body>\n' + s + '</body></html>'
open(OUT + '/index.html', 'w', encoding='utf-8').write(s)
print('sun-sea', len(s.encode()) // 1024, 'KB;', len(items), 'photos;', [os.path.getsize(f'{OUT}/ph{n}.js') // 1024 for n in range(1, len(chunks) + 1)])
