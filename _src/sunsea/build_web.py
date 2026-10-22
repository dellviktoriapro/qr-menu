"""Sun&Sea Restaurant (Mui Ne) menu.
Same engine as Chez Oanh: takes ../chez/tpl.html, re-skins it to the Sun&Sea look (parchment, deep green, red ribbons,
plumeria; their own header band) and swaps the cafe-specific texts. All features stay: language choice, table QR orders,
separate checks, bill / QR payment / tips, live status, stop list, review request.
Run from the repo root through build_all.py, or:  cd _src/sunsea && python build_web.py ../../sun-sea"""
import json, os, shutil, base64, io, sys, re
from PIL import Image
import data

OUT = sys.argv[1] if len(sys.argv) > 1 else '../../sun-sea'
shutil.rmtree(OUT, ignore_errors=True); os.makedirs(OUT)

def webp(src, maxw, q=80):
    im = Image.open(src).convert('RGB')
    if im.width > maxw: im = im.resize((maxw, round(im.height * maxw / im.width)), Image.LANCZOS)
    b = io.BytesIO(); im.save(b, 'WEBP', quality=q, method=6); return 'data:image/webp;base64,' + base64.b64encode(b.getvalue()).decode()

has = lambda k: k and os.path.exists(f'ph/{k}.jpg')
# ---- data for the page (photos only where we already have them)
D = [dict(id=s['id'], n=s['n'], note=s['note'], g=s['g'], items=[[i[0], i[1], i[2], i[3], i[4],
      ([[l, p] for l, p in i[5]] if isinstance(i[5], list) else i[5]), i[6] if has(i[6]) else None] + ([i[7]] if len(i) > 7 and i[7] else [])
      for i in s['items']]) for s in data.S]
CAT = {s['id']: next((i[6] for i in s['items'] if has(i[6])), None) for s in data.S}
order = [k for k in CAT.values() if k] + [i[6] for s in data.S for i in s['items'] if has(i[6])]
order = list(dict.fromkeys(order))
items = [(k, webp(f'ph/{k}.jpg', 900)) for k in order]
chunks = []; cur = []; size = 0
for k, v in items:
    cur.append((k, v)); size += len(v)
    if size > 650_000: chunks.append(cur); cur = []; size = 0
if cur: chunks.append(cur)
for n, c in enumerate(chunks, 1):
    open(f'{OUT}/ph{n}.js', 'w').write('__ph(' + json.dumps(dict(c)) + ');')
BAND = webp('amb/band.jpg', 1200, 84)

s = open('../chez/tpl.html', encoding='utf-8').read()
def rep(a, b, cnt=1):
    global s
    assert s.count(a) == cnt, (a[:90], s.count(a))
    s = s.replace(a, b)

# ---- identity
rep('<title>Café Chez Oanh Menu</title>', '<title>Sun&amp;Sea Restaurant · Mui Ne · Menu</title>')
rep('family=Cormorant+Garamond:ital,wght@0,500;0,600;0,700;1,500;1,600&family=Montserrat:wght@400;500;600;700',
    'family=Alegreya+SC:wght@500;700;800&family=Lobster&family=Montserrat:wght@400;500;600;700;800')
rep('    <div class="eyebrow">Phan Thiết · Hàm Tiến</div>\n    <h2>Café Chez Oanh<em>Sofa Café</em></h2>',
    '    <div class="eyebrow">Mui Ne · Phan Thiết</div>\n    <h2 class="logo">Sun&amp;Sea<em>Restaurant</em></h2>')
rep('''    <h1>Café Chez Oanh<em>Sofa Café · Hàm Tiến</em></h1>
    <div class="hmeta"><span class="tchip" id="tChip" hidden></span><a class="hlink" href="#about" id="aboutLnk"></a></div>''',
    '''    <h1 class="sr">Sun&amp;Sea Restaurant · Mui Ne</h1>''')
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

# ---- separate storage for this menu (cart, checks, table) — the bridge to the staff app (co_inbox, co_pub) stays shared
for k in ['co_cart', 'co_wish', 'co_ck', 'co_guest', 'co_tbl', 'co_lang', 'co_cur']:
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

# ---- look: parchment, deep green, red ribbons (their printed menu)
rep('''  color-scheme:dark;
  --bg:#13100c; --bg-2:#1b1611; --card:#211b15; --line:#3a2f24; --ink:#f3ead9; --muted:#b3a58f; --dim:#857862;
  --amber:#e39a3b; --amber-2:#f2b65c; --teal:#3db3ad; --teal-ink:#7fd6d0;
  --f-display:"Cormorant Garamond",Georgia,"Times New Roman",serif;''',
'''  color-scheme:light;
  --bg:#f4e7c5; --bg-2:#fbf2da; --card:#fffaee; --line:#e2cf9f; --ink:#1f2f1c; --muted:#5b5638; --dim:#8b815d;
  --amber:#1f5b37; --amber-2:#1f5b37; --teal:#9c2a1f; --teal-ink:#9c2a1f; --red:#a3201f; --gold:#c9a24a;
  --f-display:"Alegreya SC",Georgia,"Times New Roman",serif;''')
for a_, b_ in [('rgba(19,16,12,', 'rgba(251,242,218,'), ('rgba(242,182,92,', 'rgba(31,91,55,'), ('rgba(227,154,59,', 'rgba(31,91,55,'),
               ('rgba(33,27,21,', 'rgba(255,250,238,'), ('rgba(243,234,217,', 'rgba(31,47,28,'), ('rgba(255,236,200,', 'rgba(31,91,55,'),
               ('rgba(255,200,120,', 'rgba(31,91,55,'), ('rgba(255,214,150,', 'rgba(31,91,55,')]:
    s = s.replace(a_, b_)
for a_, b_ in [('#1d140a', '#fffaee'), ('#f7c978', '#2f7a4a'), ('#e8a145', '#226640'), ('#cf7f2a', '#163f27'), ('#d9852c', '#163f27'), ('#6b4115', '#163f27'),
               ('#1f1912', '#fffaee'), ('#221b14', '#fffaee'), ('#211b15', '#fffaee'), ('#1b1611', '#fbf2da'), ('#1a1510', '#f8ecd0'), ('#2a2118', '#fffaee'),
               ('#241d16', '#fffaee'), ('#211a12', '#fffaee'), ('#17130f', '#f8ecd0'), ('#1f1913', '#fffaee'), ('#2a1608', '#fffaee')]:
    s = s.replace(a_, b_)
rep('</style>', '''/* ===== Sun&Sea ===== */
body{background:var(--bg) url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='160' height='160'%3E%3Cfilter id='n'%3E%3CfeTurbulence baseFrequency='.8' numOctaves='2'/%3E%3CfeColorMatrix values='0 0 0 0 .45 0 0 0 0 .35 0 0 0 0 .15 0 0 0 .07 0'/%3E%3C/filter%3E%3Crect width='160' height='160' filter='url(%23n)'/%3E%3C/svg%3E")}
.sr{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0)}
.hero{height:auto!important;aspect-ratio:853/248;max-width:860px;margin:0 auto}
.hero .bg{background-size:cover!important;background-position:center!important;transform:none!important;filter:none!important}
.hero::before{display:none!important}
.hero .txt{display:none}
.hsub{padding-block:6px 4px}
.hsub .hmeta{justify-content:center;margin:0}
.logo{font-family:"Lobster",cursive!important;font-weight:400!important;color:var(--amber)!important;letter-spacing:0!important;text-transform:none!important}
.logo em{display:block;font-family:"Alegreya SC",serif;font-style:normal;font-size:.36em;color:var(--muted);letter-spacing:.14em;margin-top:4px}
.gate::before{background:linear-gradient(180deg,rgba(244,231,197,.15),rgba(244,231,197,.75) 45%,var(--bg) 78%)!important}
.gate .bg{background-size:contain!important;background-position:top center!important;background-repeat:no-repeat!important}
.stick{box-shadow:0 6px 16px rgba(80,60,20,.08)}
section.s h2{font-family:var(--f-display);font-weight:800;color:var(--amber);letter-spacing:.01em}
.sh .vi{background:var(--amber)!important;color:#fffaee!important}
.sh .vi::after{border-left-color:var(--amber)!important}
.tile{background:var(--card)!important;border:1px solid var(--line)!important;box-shadow:0 6px 18px rgba(80,60,20,.08)}
.tile .ph{background:#fff}
.tile .nm,li.it .nm{font-family:var(--f-display)!important;font-weight:800!important;color:var(--ink)!important;letter-spacing:.01em}
.tile .orig,li.it .orig,#dish .orig{color:var(--red)!important;font-style:normal!important;font-family:var(--f-body)!important;font-weight:600;font-size:12px}
.pv .main{color:#fffaee!important;background:var(--amber);border-radius:999px;padding:3px 10px;align-self:flex-start;font-size:13.5px!important}
.pv .sub{color:var(--muted)!important}
.pnote{color:var(--red)!important}
.nr,.num{color:var(--amber)!important}
.num{background:#fffaee!important;border-color:var(--amber)!important}
.tg{background:rgba(255,250,238,.92)!important;color:var(--amber)!important;border:1px solid var(--amber)}
.tg-special,.tg-best,.tg-must{background:var(--red)!important;color:#fff3d8!important;border-color:var(--gold)}
.tg-signature,.tg-day,.tg-premium{background:var(--amber)!important;color:#fff3d8!important;border-color:var(--gold)}
.tg-preorder{background:var(--gold)!important;color:#1f2f1c!important}
.add{border-color:var(--amber)!important;color:var(--amber)!important;background:#fffaee!important}
.step{background:var(--amber)!important}.step button{color:#fffaee!important}.step b{color:#fffaee}
.cat img,.cat .ini{border-color:var(--gold)!important}
.cat.on img,.cat.on .ini{border-color:var(--red)!important;box-shadow:0 0 0 3px rgba(163,32,31,.18)!important}
.groups button.on{background:var(--amber)!important;color:#fffaee!important}
.bar .cap{background:rgba(255,250,238,.96)!important;border-color:var(--gold)!important;box-shadow:0 14px 34px rgba(60,45,15,.25)!important}
.bar .capin .gs i.n{background:var(--amber)!important;color:#fffaee!important}
.langbtn{background:var(--amber)!important;color:#fffaee!important;box-shadow:0 6px 18px rgba(31,91,55,.35),0 0 0 3px rgba(255,250,238,.8)!important}
.about{background:linear-gradient(180deg,#fffaee,#f8ecd0)!important;border-color:var(--gold)!important}
.about h3{font-size:40px!important}
.tipb{color:#fffaee!important;background:linear-gradient(115deg,#b5332a,#a3201f 55%,#7d1715)!important}
.tipf{border-color:rgba(163,32,31,.4)!important;background:linear-gradient(180deg,rgba(163,32,31,.08),rgba(163,32,31,.02))!important}
.dcard{background:linear-gradient(180deg,#fffaee,#f6e7c3)!important;border-color:var(--gold)!important}
.toast{background:var(--amber)!important;color:#fffaee!important}
#atmo{display:none!important}
</style>''')
s = s.replace('__DATA__', json.dumps(D, ensure_ascii=False)).replace('__PH__', json.dumps({'amb_lion': BAND})).replace('__AMB__', json.dumps({'lion': BAND})).replace('__GEN__', '[]').replace('__CATPH__', json.dumps({k: v for k, v in CAT.items() if v}))
s += '<script>(function n(i){if(i>%d)return;var e=document.createElement("script");e.src="ph"+i+".js";e.onload=e.onerror=function(){n(i+1)};document.body.appendChild(e)})(1)</script>' % len(chunks)
s = '<!doctype html>\n<html lang="ru">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n</head>\n<body>\n' + s + '</body></html>'
open(OUT + '/index.html', 'w', encoding='utf-8').write(s)
print('sun-sea', len(s.encode()) // 1024, 'KB;', len(items), 'photos;', [os.path.getsize(f'{OUT}/ph{n}.js') // 1024 for n in range(1, len(chunks) + 1)])
