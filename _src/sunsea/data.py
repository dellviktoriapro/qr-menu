# Sun&Sea Restaurant, Mui Ne — menu data, transcribed from the restaurant's printed menu (pages received 22.10.2026).
# item: (en, vi, ru, ko, zh, price, photo, extra)
#   price: int | None (ask staff) | [(label dict, price), ...]
#   photo: key of ph/<key>.jpg (missing file = no photo yet)
#   extra: n = number in their menu, d = description (L), tg = tags, nt = note (L)
# The printed menu is in ru / en / vi; ko and zh are our translations.
S = []
def L(en, vi, ru, ko=None, zh=None): return dict(en=en, vi=vi, ru=ru, ko=ko or en, zh=zh or en)
def I(en, vi, ru, ko, zh, price, photo=None, **e): return (en, vi, ru, ko, zh, price, photo, e)
def sec(id, name, items, note=None, group='food'): S.append(dict(id=id, n=name, items=items, note=note, g=group))
PORK = L('Pork', 'Thịt heo', 'Свинина', '돼지고기', '猪肉')
BEEF = L('Beef', 'Thịt bò', 'Говядина', '소고기', '牛肉')
PLAIN = L('Vegetables only', 'Chỉ rau', 'Только овощи', '채소만', '纯蔬菜')
WBEEF = L('With beef', 'Với bò', 'С говядиной', '소고기 추가', '加牛肉')
WSHR = L('With shrimp', 'Với tôm', 'С креветками', '새우 추가', '加虾')
VEG3 = lambda a, b, c: [(PLAIN, a), (WBEEF, b), (WSHR, c)]
SMOKED = L('Smoked for more than 12 hours over natural charcoal: real flavor.', 'Xông khói hơn 12 giờ trên than gỗ tự nhiên: hương vị thật.',
           'Копчение более 12 часов на древесных углях: настоящий вкус.', '천연 숯으로 12시간 이상 훈연한 진짜 맛.', '天然木炭熏制超过12小时，真正的风味。')
DAY = ['day']

# ---------------------------------------------------------------- FOOD
sec('ss_chef', L("Chef's specials", 'Món đặc biệt của bếp trưởng', 'Специальные блюда от шефа', '셰프 스페셜', '主厨特色菜'), [
I('Beer battered fish fillet', 'Phi lê cá chiên bột', 'Филе рыбы в кляре', '맥주 반죽 생선 튀김', '啤酒脆炸鱼柳', 180000, 'fish_beer',
  d=L('Crispy white fish fillet in a golden beer batter, served with French fries and tartar sauce.', 'Phi lê cá trắng chiên bột giòn, dùng kèm khoai tây chiên và sốt tartar.',
      'Хрустящее филе белой рыбы в золотистом кляре, подаётся с картофелем фри и соусом тартар.', '황금빛 맥주 반죽을 입힌 바삭한 흰살생선, 감자튀김과 타르타르 소스 곁들임.', '金黄啤酒面糊脆炸白鱼柳，配薯条和塔塔酱。'), tg=['special', 'best']),
I('Fish fillet in lemon sauce', 'Phi lê cá sốt chanh', 'Филе рыбы в лимонном соусе', '레몬 소스 생선 필레', '柠檬汁鱼柳', 160000, 'fish_lemon',
  d=L('Tender white fish fillet pan-seared to golden perfection, served in a fresh lemon sauce with garlic. Served with grilled vegetables.',
      'Phi lê cá áp chảo vàng, dùng với sốt chanh tươi, tỏi thơm ngon. Dùng kèm rau củ nướng.',
      'Нежное филе белой рыбы, обжаренное до золотистой корочки, в ароматном лимонном соусе с чесноком. Подаётся с овощами гриль.',
      '노릇하게 구운 부드러운 흰살생선에 마늘 레몬 소스, 구운 채소 곁들임.', '香煎白鱼柳配蒜香鲜柠檬汁，佐烤蔬菜。'), tg=['special', 'best', 'must']),
I('Fish fillet in corn butter garlic sauce', 'Phi lê cá sốt bắp bơ tỏi', 'Филе рыбы в кукурузно-чесночном соусе', '옥수수 버터 마늘 소스 생선 필레', '玉米黄油蒜香鱼柳', 160000, 'fish_corn',
  d=L('Tender white fish fillet in a fragrant corn butter garlic sauce with garlic and spices. Served with crispy baguette.',
      'Phi lê cá trắng mềm trong sốt bắp bơ tỏi thơm ngon nấu cùng tỏi và gia vị. Dùng kèm bánh mì giòn.',
      'Нежное филе белой рыбы в ароматном кукурузном соусе с чесноком и сливочным маслом. Подаётся с хрустящим багетом.',
      '마늘과 향신료를 넣은 옥수수 버터 소스의 부드러운 흰살생선, 바삭한 바게트 곁들임.', '嫩白鱼柳配玉米黄油蒜香酱，佐脆皮法棍。'), tg=['special']),
I('Fish fillet in tamarind sauce', 'Phi lê cá sốt me', 'Филе рыбы в тамариндовом соусе', '타마린드 소스 생선 필레', '罗望子酱鱼柳', 160000, 'fish_tamarind',
  d=L('Tender white fish fillet in a fragrant tamarind sauce with a delicate sweet and sour note. Served with grilled vegetables.',
      'Phi lê cá trắng mềm trong sốt me thơm ngon, thoảng vị chua ngọt nhẹ nhàng. Dùng kèm rau củ nướng.',
      'Нежное филе белой рыбы в ароматном тамариндовом соусе с лёгкой кисло-сладкой ноткой. Подаётся с овощами гриль.',
      '은은한 새콤달콤함의 타마린드 소스 흰살생선, 구운 채소 곁들임.', '酸甜罗望子酱嫩白鱼柳，佐烤蔬菜。'), tg=['special', 'best']),
I('Smoked meat with mashed potatoes', 'Thịt xông khói với khoai tây nghiền', 'Копчёное мясо с пюре', '훈제 고기와 매시드 포테이토', '熏肉配土豆泥', [(PORK, 190000), (BEEF, 250000)], 'smoked_mash', d=SMOKED, tg=['signature']),
I('Smoked meat with pasta', 'Thịt xông khói với mì ống', 'Копчёное мясо с макаронами', '훈제 고기와 파스타', '熏肉配通心粉', [(PORK, 200000), (BEEF, 260000)], 'smoked_pasta', d=SMOKED, tg=['signature']),
I('Seafood soup with smoked marlin', 'Súp hải sản với cá cờ marlin xông khói', 'Суп с морепродуктами с копчёным марлином', '훈제 청새치 해산물 수프', '烟熏旗鱼海鲜汤', 200000, 'marlin_soup', tg=DAY),
I('Mimosa salad with smoked marlin', 'Salad mimosa với cá cờ marlin xông khói', 'Мимоза с копчёным марлином', '훈제 청새치 미모사 샐러드', '烟熏旗鱼含羞草沙拉', 150000, 'mimosa', tg=DAY),
I('Tôm hấp bia: wild big prawns cooked in beer', 'Tôm hấp bia', 'Креветки в пиве (Tôm hấp bia)', '맥주에 찐 자연산 대하', '啤酒蒸野生大虾', None, 'prawns_beer',
  d=L('Wild big prawns cooked in beer, with tamarind sauce and garlic corn sauce. 500 g, 5–6 pieces. Premium wild prawns: tender meat, rich flavor, a real treat for gourmets!',
      'Tôm hoang kích cỡ lớn, hấp bia với sốt me và sốt bắp tỏi. 500 gram, 5–6 con.',
      'Дикие креветки большого размера, приготовленные в пиве, с тамариндовым соусом и чесночно-кукурузным соусом. 500 грамм, 5–6 штук. Дикие креветки премиум качества: нежное мясо, насыщенный вкус, настоящее угощение для гурманов!',
      '맥주에 찐 자연산 대하, 타마린드 소스와 마늘 옥수수 소스. 500g, 5–6마리.', '啤酒蒸野生大虾，配罗望子酱与蒜香玉米酱。500克，5–6只。'),
  nt=L('550,000 – 600,000 VND', '550.000 – 600.000 VND', '550 000 – 600 000 ₫', '550,000 – 600,000 VND', '550,000 – 600,000 越南盾'), tg=['premium']),
I('Hot smoked fish', 'Cá hun khói nóng', 'Рыба горячего копчения', '열훈제 생선', '热熏鱼', None, 'smoked_fish',
  nt=L('Pre-order 1 day in advance. Please check the price with us.', 'Đặt trước 1 ngày. Vui lòng hỏi giá tại nhà hàng.', 'Заказ за 1 день. Цену уточняйте у нас.', '하루 전 예약. 가격은 직원에게 문의하세요.', '需提前1天预订，价格请向店员咨询。'), tg=['preorder']),
I('Grilled smoked shrimps', 'Tôm nướng hun khói', 'Креветки горячего копчения', '훈제 구이 새우', '烟熏烤虾', None, 'smoked_shrimp',
  nt=L('Pre-order 1 day in advance. Please check the price with us.', 'Đặt trước 1 ngày. Vui lòng hỏi giá tại nhà hàng.', 'Заказ за 1 день. Цену уточняйте у нас.', '하루 전 예약. 가격은 직원에게 문의하세요.', '需提前1天预订，价格请向店员咨询。'), tg=['preorder']),
], note='chef')

sec('ss_pies', L('Our signature pies', 'Bánh pie đặc trưng', 'Наши фирменные пироги', '시그니처 파이', '招牌馅饼'), [
I('Mango pie', 'Bánh pie xoài', 'Пирог с манго', '망고 파이', '芒果派', 95000, 'pie_mango'),
I('Pineapple pie', 'Bánh pie thơm', 'Пирог с ананасом', '파인애플 파이', '菠萝派', 95000, 'pie_pineapple'),
I('Cabbage pie', 'Bánh pie bắp cải', 'Пирог с капустой', '양배추 파이', '卷心菜派', 95000, 'pie_cabbage'),
I('Meat pie', 'Bánh pie thịt', 'Пирог с мясом', '고기 파이', '肉派', 95000, 'pie_meat'),
], note='pies')

PZ = lambda en, vi, ru: L(en, vi, ru)
sec('ss_pizza', L('Pizza', 'Bánh pizza', 'Пицца', '피자', '披萨'), [
I('Smoked pork BBQ pizza', 'Pizza xông khói thịt heo BBQ', 'Пицца копчёная свинина BBQ', '훈제 돼지고기 BBQ 피자', '烟熏猪肉BBQ披萨', 240000, 'pz_pork',
  d=L('Signature smoked pork, mozzarella cheese, tomato sauce, onion.', 'Thịt heo xông khói đặc biệt theo công thức bí mật của chúng tôi, phô mai mozzarella, sốt cà chua, hành tây.',
      'Фирменное копчёное мясо по нашему секретному рецепту, моцарелла, томатный соус, лук.', '시그니처 훈제 돼지고기, 모차렐라, 토마토 소스, 양파.', '招牌烟熏猪肉、马苏里拉、番茄酱、洋葱。'), tg=['signature']),
I('Smoked beef BBQ pizza', 'Pizza xông khói thịt bò BBQ', 'Пицца копчёная говядина BBQ', '훈제 소고기 BBQ 피자', '烟熏牛肉BBQ披萨', 260000, 'pz_beef',
  d=L('Signature smoked beef, mozzarella cheese, tomato sauce, onion.', 'Thịt bò xông khói đặc biệt theo công thức bí mật của chúng tôi, phô mai mozzarella, sốt cà chua, hành tây.',
      'Фирменная копчёная говядина по нашему секретному рецепту, моцарелла, томатный соус, лук.', '시그니처 훈제 소고기, 모차렐라, 토마토 소스, 양파.', '招牌烟熏牛肉、马苏里拉、番茄酱、洋葱。'), tg=['signature']),
I('4 cheese pizza', 'Pizza bốn loại phô mai', 'Пицца «Четыре сыра»', '콰트로 치즈 피자', '四芝士披萨', 210000, 'pz_4cheese'),
I('Pepperoni pizza', 'Pizza salami', 'Пицца пепперони', '페퍼로니 피자', '意式辣香肠披萨', 210000, 'pz_pepperoni',
  d=L('Mozzarella, tomato sauce, pepperoni salami.', 'Phô mai mozzarella, sốt cà chua, xúc xích pepperoni.', 'Моцарелла, томатный соус, салями пепперони.', '모차렐라, 토마토 소스, 페퍼로니.', '马苏里拉、番茄酱、意式辣香肠。')),
I('Seafood pizza', 'Pizza hải sản', 'Пицца с морепродуктами', '해산물 피자', '海鲜披萨', 240000, 'pz_seafood',
  d=L('Mozzarella cheese, tomato sauce, onion, cherry tomatoes, shrimp, squid, mussels.', 'Phô mai mozzarella, sốt cà chua, hành tây, cà chua bi, tôm, mực, vẹm.',
      'Моцарелла, томатный соус, лук, черри, креветки, кальмар, мидии.', '모차렐라, 토마토 소스, 양파, 방울토마토, 새우, 오징어, 홍합.', '马苏里拉、番茄酱、洋葱、圣女果、虾、鱿鱼、青口。')),
I('Ham pizza', 'Pizza thịt nguội', 'Пицца с ветчиной', '햄 피자', '火腿披萨', 200000, 'pz_ham',
  d=L('Mozzarella cheese, tomato sauce, cooked ham, olives, mushrooms.', 'Phô mai mozzarella, sốt cà chua, thịt nguội, ô liu, nấm.', 'Моцарелла, томатный соус, ветчина, оливки, грибы.', '모차렐라, 토마토 소스, 햄, 올리브, 버섯.', '马苏里拉、番茄酱、火腿、橄榄、蘑菇。')),
I('Margherita pizza', 'Pizza Margherita', 'Пицца «Маргарита»', '마르게리타 피자', '玛格丽特披萨', 180000, 'pz_margherita',
  d=L('Mozzarella cheese, tomato sauce, Parmigiano cheese.', 'Phô mai mozzarella, sốt cà chua, phô mai parmigiano.', 'Моцарелла, томатный соус, пармезан.', '모차렐라, 토마토 소스, 파르미지아노.', '马苏里拉、番茄酱、帕尔马干酪。')),
I('Vegetarian pizza', 'Pizza chay', 'Овощная пицца', '채식 피자', '素食披萨', 200000, 'pz_veg',
  d=L('Mozzarella cheese, tomato sauce, mushrooms, onion, olive, zucchini, peppers, eggplant, Parmigiano cheese.', 'Phô mai mozzarella, sốt cà chua, nấm, hành tây, ô liu, bí ngòi, ớt chuông, cà tím, phô mai parmigiano.',
      'Моцарелла, томатный соус, грибы, лук, оливки, цукини, перец, баклажан, пармезан.', '모차렐라, 토마토 소스, 버섯, 양파, 올리브, 주키니, 파프리카, 가지, 파르미지아노.', '马苏里拉、番茄酱、蘑菇、洋葱、橄榄、西葫芦、彩椒、茄子、帕尔马干酪。'), tg=['veg']),
I('Carbonara pizza', 'Bánh pizza Carbonara', 'Пицца «Карбонара»', '카르보나라 피자', '卡邦尼披萨', 200000, 'pz_carbonara',
  d=L('White sauce, bacon, eggs, mozzarella cheese, Parmigiano cheese, black pepper.', 'Sốt kem, thịt xông khói, trứng, phô mai mozzarella, phô mai parmigiana, tiêu đen.',
      'Белый соус, бекон, яйца, моцарелла, сыр пармиджано, чёрный перец.', '화이트 소스, 베이컨, 달걀, 모차렐라, 파르미지아노, 흑후추.', '白酱、培根、鸡蛋、马苏里拉、帕尔马干酪、黑胡椒。')),
I('Smoked salmon pizza', 'Bánh pizza cá hồi xông khói', 'Пицца с копчёным лососем', '훈제 연어 피자', '烟熏三文鱼披萨', 260000, 'pz_salmon',
  d=L('White sauce, mozzarella, cream cheese, smoked salmon.', 'Sốt kem, phô mai mozzarella, phô mai kem, cá hồi xông khói.', 'Белый соус, моцарелла, сливочный сыр, копчёный лосось.', '화이트 소스, 모차렐라, 크림치즈, 훈제 연어.', '白酱、马苏里拉、奶油奶酪、烟熏三文鱼。')),
I('Mortadella & pistachio pizza', 'Bánh pizza mortadella và hạt dẻ cười', 'Пицца с мортаделлой и фисташками', '모르타델라 피스타치오 피자', '摩泰台拉开心果披萨', 200000, 'pz_mortadella',
  d=L('White sauce, mortadella and pistachio.', 'Sốt kem, mortadella và hạt dẻ cười.', 'Белый соус, мортаделла, фисташки.', '화이트 소스, 모르타델라, 피스타치오.', '白酱、摩泰台拉香肠、开心果。')),
I('Hawaii pizza', 'Pizza Hawaii', 'Пицца «Гавайская»', '하와이안 피자', '夏威夷披萨', 200000, 'pz_hawaii',
  d=L('Mozzarella cheese, cooked ham, tomato sauce, pineapple, peppers.', 'Phô mai mozzarella, thịt jambon, sốt cà chua, dứa, ớt chuông.', 'Моцарелла, ветчина, томатный соус, ананас, перец.', '모차렐라, 햄, 토마토 소스, 파인애플, 파프리카.', '马苏里拉、火腿、番茄酱、菠萝、彩椒。')),
I('Shrimp pizza', 'Pizza tôm', 'Пицца с креветками', '새우 피자', '鲜虾披萨', 230000, 'pz_shrimp',
  d=L('White sauce, mozzarella, shrimp, broccoli.', 'Sốt kem trắng, phô mai mozzarella, tôm, bông cải xanh.', 'Белый соус, моцарелла, креветки, брокколи.', '화이트 소스, 모차렐라, 새우, 브로콜리.', '白酱、马苏里拉、虾、西兰花。')),
], note='pizza')

sec('ss_salads', L('Salads', 'Gỏi & sa lát', 'Салаты', '샐러드', '沙拉'), [
I('Squid salad', 'Gỏi mực', 'Салат с кальмаром', '오징어 샐러드', '鱿鱼沙拉', 165000, 'sl_squid', n='1',
  d=L('Squid, herbs, lime, mango, onion, carrot, sweet and sour dressing.', 'Mực, rau thơm, chanh, xoài, hành, cà rốt, nước trộn chua ngọt.', 'Кальмар, зелень, лайм, манго, лук, морковка, заправка кисло-сладкий соус.', '오징어, 허브, 라임, 망고, 양파, 당근, 새콤달콤 드레싱.', '鱿鱼、香草、青柠、芒果、洋葱、胡萝卜、酸甜酱汁。')),
I('Lotus salad', 'Gỏi ngó sen tôm thịt', 'Салат из лотоса', '연근 샐러드', '莲藕沙拉', 135000, 'sl_lotus', n='2',
  d=L('Lotus stems, shrimp, pork, onion, carrot, herbs, sweet and sour dressing.', 'Ngó sen, tôm, thịt heo, hành, cà rốt, rau thơm, nước trộn chua ngọt.', 'Лотос, креветки, свинина, лук, морковка, зелень, заправка кисло-сладкий соус.', '연줄기, 새우, 돼지고기, 양파, 당근, 허브, 새콤달콤 드레싱.', '莲藕、虾、猪肉、洋葱、胡萝卜、香草、酸甜酱汁。')),
I('Crispy beef salad', 'Gỏi bò khoai môn chiên giòn', 'Салат с говядиной', '바삭한 소고기 샐러드', '香脆牛肉沙拉', 135000, 'sl_beef', n='3',
  d=L('Beef, herbs, onion, carrot, taro, sweet and sour dressing.', 'Thịt bò, rau thơm, hành, cà rốt, khoai môn, nước trộn chua ngọt.', 'Говядина, зелень, лук, морковка, таро, заправка кисло-сладкий соус.', '소고기, 허브, 양파, 당근, 타로, 새콤달콤 드레싱.', '牛肉、香草、洋葱、胡萝卜、芋头、酸甜酱汁。')),
I('Seafood salad', 'Gỏi hải sản', 'Салат с морепродуктами', '해산물 샐러드', '海鲜沙拉', 155000, 'sl_seafood', n='4',
  d=L('Seafood, onion, carrot, green mango, lime, herbs, sweet and sour dressing.', 'Hải sản, hành, cà rốt, xoài xanh, chanh, rau thơm, nước trộn chua ngọt.', 'Морепродукты, лук, морковка, зелёный манго, лайм, зелень, заправка кисло-сладкий соус.', '해산물, 양파, 당근, 그린 망고, 라임, 허브, 새콤달콤 드레싱.', '海鲜、洋葱、胡萝卜、青芒果、青柠、香草、酸甜酱汁。')),
I('Papaya salad', 'Gỏi đu đủ tôm khô', 'Салат из папайи', '파파야 샐러드', '木瓜沙拉', 85000, 'sl_papaya', n='5',
  d=L('Papaya, long green beans, shrimp, herbs, peanuts, dressing.', 'Đu đủ, đậu đũa, tôm khô, rau thơm, đậu phộng, nước trộn.', 'Папайя, длинная зелёная фасоль, креветки, зелень, арахис, заправка соус.', '파파야, 줄콩, 새우, 허브, 땅콩, 드레싱.', '木瓜、豇豆、虾、香草、花生、酱汁。')),
I('Caesar salad with chicken', 'Sa lát Caesar gà', 'Цезарь с курицей', '치킨 시저 샐러드', '鸡肉凯撒沙拉', 140000, 'sl_caesar', n='57'),
I('Green salad', 'Sa lát rau tươi', 'Овощной салат', '그린 샐러드', '蔬菜沙拉', 85000, 'sl_green', n='58', tg=['veg']),
I('Grilled chicken green salad with honey mustard', 'Sa lát gà nướng với sốt mù tạt mật ong', 'Салат с курицей гриль и медово-горчичной заправкой', '꿀 머스터드 그릴 치킨 샐러드', '蜂蜜芥末烤鸡沙拉', 120000, 'sl_chicken', n='59'),
I('Mexican grilled sweet mango salad with shrimp', 'Mexican salat xoài tôm nướng', 'Салат из манго с креветками', '그릴 새우 망고 샐러드', '烤虾芒果沙拉', 150000, 'sl_mango', n='60'),
])

sec('ss_tuna', L('Tuna & marlin', 'Cá ngừ & cá cờ', 'Тунец и марлин', '참치 & 청새치', '金枪鱼与旗鱼'), [
I('Tuna salad', 'Gỏi cá ngừ', 'Тунец салат', '참치 샐러드', '金枪鱼沙拉', 200000, 'tu_salad', n='90'),
I('Tuna avocado mango', 'Cá ngừ bơ xoài', 'Тунец, авокадо, манго', '참치 아보카도 망고', '金枪鱼牛油果芒果', 200000, 'tu_avo', n='91'),
I('Tuna sashimi', 'Sashimi cá ngừ', 'Тунец сашими', '참치 사시미', '金枪鱼刺身', 200000, 'tu_sashimi', n='92'),
I('Tuna with potatoes in cream sauce', 'Cá ngừ kem khoai tây', 'Тунец с картошкой в сливочном соусе', '크림소스 참치와 감자', '奶油酱金枪鱼配土豆', 200000, 'tu_potato', n='93'),
I('Marlin sashimi', 'Cá cờ sashimi', 'Марлин сашими', '청새치 사시미', '旗鱼刺身', 200000, 'ma_sashimi', n='94'),
I('Marlin avocado mango', 'Cá cờ bơ xoài', 'Марлин, авокадо, манго', '청새치 아보카도 망고', '旗鱼牛油果芒果', 200000, 'ma_avo', n='95'),
I('Marlin with potatoes in cream sauce', 'Cá cờ kem khoai tây', 'Марлин с картошкой в сливочном соусе', '크림소스 청새치와 감자', '奶油酱旗鱼配土豆', 200000, 'ma_potato', n='96'),
I('Marlin salad', 'Gỏi cá cờ', 'Марлин салат', '청새치 샐러드', '旗鱼沙拉', 200000, 'ma_salad', n='97'),
])

sec('ss_rolls', L('Rolls & pho', 'Nem, cuốn & phở', 'Роллы и фо', '롤 & 쌀국수', '春卷与河粉'), [
I('Beef pho', 'Phở bò', 'Суп фо бо', '소고기 쌀국수', '牛肉河粉', 120000, 'pho_bo', n='6',
  d=L('Beef, aromatic broth, rice noodles.', 'Thịt bò, nước dùng thơm, bánh phở.', 'Говядина, зелень, рисовая лапша, бульон готовится 24 часа.', '소고기, 향긋한 육수, 쌀국수.', '牛肉、香浓汤底、米粉。')),
I('Fried spring rolls', 'Nem rán', 'Спринг-роллы', '튀김 스프링롤', '炸春卷', 120000, 'ro_spring', n='11',
  d=L('Pork, shrimp, vegetables, crispy rice wrap (mix).', 'Thịt heo, tôm, rau củ, bánh tráng giòn.', 'Свинина, креветки, овощи, хрустящая рисовая бумага (микс).', '돼지고기, 새우, 채소, 바삭한 라이스페이퍼.', '猪肉、虾、蔬菜、脆米纸。')),
I('Crab rolls', 'Nem cua bể', 'Крабовые роллы', '게살 롤', '蟹肉卷', 140000, 'ro_crab', n='12',
  d=L('Crab, pork, vegetables.', 'Cua, thịt heo, rau củ.', 'Краб, овощи, свинина.', '게살, 돼지고기, 채소.', '蟹肉、猪肉、蔬菜。')),
I('Fresh rolls', 'Cuốn xuân', 'Свежие роллы', '월남쌈', '鲜春卷', 120000, 'ro_fresh', n='14',
  d=L('Shrimp, pork, herbs, wrapped in rice paper.', 'Tôm, thịt heo, rau thơm, cuốn bánh tráng.', 'Креветки, свинина, зелень, завёрнутые в рисовую бумагу.', '새우, 돼지고기, 허브를 라이스페이퍼로 말았어요.', '虾、猪肉、香草，米纸包裹。')),
])

sec('ss_soups', L('Soups & curry', 'Súp & cà ri', 'Супы и карри', '수프 & 커리', '汤与咖喱'), [
I('Borscht', 'Súp borscht', 'Борщ', '보르시', '罗宋汤', 120000, 'borscht'),
I('Tom yum kung', 'Tom yum kung', 'Том ям', '똠얌꿍', '冬阴功汤', 139000, 'tomyum',
  d=L('Shrimp, lemongrass, chili, lime, Thai milk.', 'Tôm, sả, ớt, chanh, sữa Thái.', 'Тайский суп с креветками: креветки, лемонграсс, чили, лайм, тайское молоко.', '새우, 레몬그라스, 고추, 라임, 태국식 밀크.', '虾、香茅、辣椒、青柠、泰式奶。'), tg=['hot']),
I('Chicken green curry', 'Green curry gà', 'Карри с курицей', '치킨 그린 커리', '青咖喱鸡', 125000, 'curry_chicken',
  d=L('Chicken, green curry, coconut milk.', 'Gà, cà ri xanh, nước cốt dừa.', 'Курица, зелёный карри, кокосовое молоко.', '닭고기, 그린 커리, 코코넛 밀크.', '鸡肉、青咖喱、椰奶。')),
I('Coconut soup with chicken (tom kha gà)', 'Tom kha gà', 'Том кха с курицей', '닭고기 똠카', '椰汁鸡汤', 125000, 'tomkha_chicken',
  d=L('Coconut milk, chicken, herbs.', 'Nước cốt dừa, gà, rau thơm.', 'Кокосовое молоко, курица, зелень. Почти как том ям, только на кокосовом молоке. Очень вкусно 😉', '코코넛 밀크, 닭고기, 허브.', '椰奶、鸡肉、香草。')),
I('Coconut soup with shrimp (tom kha tôm)', 'Tom kha tôm', 'Том кха с креветками', '새우 똠카', '椰汁虾汤', 145000, 'tomkha_shrimp',
  d=L('Coconut milk, shrimp, herbs.', 'Nước cốt dừa, tôm, rau thơm.', 'Кокосовое молоко, креветки, зелень. Почти как том ям, только на кокосовом молоке. Очень вкусно 😉', '코코넛 밀크, 새우, 허브.', '椰奶、虾、香草。')),
I('Shrimp green curry', 'Tôm xanh cà ri', 'Креветки в зелёном карри', '새우 그린 커리', '青咖喱虾', 150000, 'curry_shrimp', n='025',
  d=L('Shrimp, green curry, coconut milk.', 'Tôm, cà ri xanh, nước cốt dừa.', 'Креветки, зелёный карри, кокосовое молоко.', '새우, 그린 커리, 코코넛 밀크.', '虾、青咖喱、椰奶。')),
I('Seafood chowder soup', 'Súp kem hải sản', 'Сливочный суп с морепродуктами', '해산물 크림 차우더', '奶油海鲜浓汤', 180000, 'chowder', n='65'),
])

sec('ss_noodles', L('Noodles & pad thai', 'Phở xào, bún & pad thai', 'Лапша и пад тай', '면 & 팟타이', '炒粉与泰式炒河粉'), [
I('Fried pho with beef', 'Phở xào bò', 'Жареная рисовая лапша с говядиной', '소고기 볶음 쌀국수', '牛肉炒河粉', 135000, 'nd_pho_beef', n='7',
  d=L('Beef, rice noodles, vegetables, secret sauce.', 'Thịt bò, bánh phở, rau củ, sốt bí truyền.', 'Говядина, рисовая лапша, овощи, секретный соус.', '소고기, 쌀국수, 채소, 비법 소스.', '牛肉、河粉、蔬菜、秘制酱汁。')),
I('Fried pho with seafood', 'Phở xào hải sản', 'Рисовая лапша с морепродуктами', '해산물 볶음 쌀국수', '海鲜炒河粉', 155000, 'nd_pho_sea', n='8',
  d=L('Seafood, rice noodles, vegetables, secret sauce.', 'Hải sản, bánh phở, rau củ, sốt bí truyền.', 'Рисовая лапша, морепродукты, овощи, секретный соус.', '해산물, 쌀국수, 채소, 비법 소스.', '海鲜、河粉、蔬菜、秘制酱汁。')),
I('Grilled pork noodles (bún chả Hà Nội)', 'Bún chả Hà Nội', 'Бун ча', '분짜 (하노이식)', '河内烤肉米线', 120000, 'bun_cha', n='9',
  d=L('Hanoi style: traditional Vietnamese grilled pork patties with rice noodles.', 'Món truyền thống Hà Nội: chả nướng than với bún.', 'Ханой: традиционные вьетнамские котлеты, приготовленные на гриле.', '하노이 전통 숯불 돼지고기 완자와 쌀국수.', '河内传统炭烤肉饼配米线。')),
I('Stir-fried noodles with beef', 'Bún bò xào', 'Лапша с говядиной', '소고기 볶음 분', '牛肉炒米线', 120000, 'bun_bo', n='10',
  d=L('Beef, noodles, vegetables and herbs, secret sauce.', 'Thịt bò, bún, rau củ và rau thơm, sốt bí truyền.', 'Рисовая лапша, зелень, овощи, жареная говядина, секретный соус.', '소고기, 쌀국수, 채소와 허브, 비법 소스.', '牛肉、米线、蔬菜香草、秘制酱汁。')),
I('Grilled beef in betel leaves', 'Bò lá lốt', 'Говядина в листьях бетеля (бо ла лот)', '라롯 잎 소고기 구이', '假蒌叶烤牛肉', 135000, 'bo_la_lot', n='15',
  d=L('Beef wrapped in betel leaves, served with noodles and herbs.', 'Thịt bò cuốn lá lốt, dùng kèm bún và rau thơm.', 'Говядина, листья бетеля, подаётся с лапшой и зеленью.', '라롯 잎에 싼 소고기, 쌀국수와 허브 곁들임.', '假蒌叶包牛肉，配米线和香草。')),
I('Chicken pad thai', 'Pad thai gà', 'Пад тай с курицей', '치킨 팟타이', '鸡肉泰式炒河粉', 110000, 'padthai_chicken', n='17',
  d=L("Chicken, rice noodles, egg, peanuts, tamarind sauce.", 'Gà, bánh phở, trứng, đậu phộng, sốt me.', 'Жареная курица, рисовая лапша, яйцо, арахис, специальный соус от шефа.', '닭고기, 쌀국수, 달걀, 땅콩, 타마린드 소스.', '鸡肉、河粉、鸡蛋、花生、罗望子酱。')),
I('Shrimp pad thai', 'Pad thai tôm', 'Пад тай с креветками', '새우 팟타이', '鲜虾泰式炒河粉', 135000, 'padthai_shrimp', n='18',
  d=L("Fried shrimp, rice noodles, egg, peanuts, chef's special sauce.", 'Tôm, bánh phở, trứng, đậu phộng, sốt đặc biệt của bếp trưởng.', 'Жареные креветки, рисовая лапша, яйцо, арахис, специальный соус от шефа.', '새우, 쌀국수, 달걀, 땅콩, 셰프 특제 소스.', '炸虾、河粉、鸡蛋、花生、主厨特制酱汁。')),
])

sec('ss_rice', L('Fried rice', 'Cơm chiên', 'Жареный рис', '볶음밥', '炒饭'), [
I('Beef fried rice', 'Cơm chiên dưa bò', 'Жареный рис с говядиной', '소고기 볶음밥', '牛肉炒饭', 135000, 'ri_beef', n='23'),
I('Garlic eggs fried rice', 'Cơm chiên tỏi trứng', 'Жареный рис с чесноком и яйцом', '마늘 달걀 볶음밥', '蒜香蛋炒饭', 70000, 'ri_garlic', n='24'),
I('Shrimp fried rice with an egg blanket', 'Cơm chiên tôm phủ trứng', 'Жареный рис с креветками, покрытый яйцом', '달걀 덮은 새우 볶음밥', '蛋皮虾仁炒饭', 140000, 'ri_shrimp', n='25'),
I('Chicken fried rice', 'Cơm chiên gà', 'Жареный рис с курицей', '닭고기 볶음밥', '鸡肉炒饭', 130000, 'ri_chicken', n='26'),
I('Seafood fried rice', 'Cơm chiên hải sản', 'Жареный рис с морепродуктами', '해산물 볶음밥', '海鲜炒饭', 140000, 'ri_seafood', n='27',
  d=L('Seafood, egg, rice.', 'Hải sản, trứng, cơm.', 'Морепродукты, яйцо, рис.', '해산물, 달걀, 밥.', '海鲜、鸡蛋、米饭。')),
I('Pineapple fried rice', 'Cơm chiên thơm', 'Рис в ананасе', '파인애플 볶음밥', '菠萝炒饭', 145000, 'ri_pineapple', n='28'),
])

sec('ss_shrimp', L('Shrimp', 'Tôm', 'Креветки', '새우', '虾'), [
I('Grilled shrimp with salt and chili', 'Tôm nướng muối ớt', 'Креветки гриль', '소금 고추 새우구이', '椒盐烤虾', 150000, 'sh_saltchili', n='29',
  d=L('Shrimp, chili, salt.', 'Tôm, ớt, muối.', 'Креветки, чили, соль.', '새우, 고추, 소금.', '虾、辣椒、盐。')),
I('Garlic butter shrimp', 'Tôm bơ tỏi', 'Креветки гриль с чесноком и маслом', '갈릭 버터 새우', '蒜香黄油虾', 165000, 'sh_garlic', n='30',
  d=L('Shrimp, butter, garlic.', 'Tôm, bơ, tỏi.', 'Креветки, сливочное масло, чеснок.', '새우, 버터, 마늘.', '虾、黄油、大蒜。')),
I('Tamarind shrimp', 'Tôm sốt me', 'Креветки в тамариндовом соусе', '타마린드 새우', '罗望子酱虾', 155000, 'sh_tamarind', n='31',
  d=L('Shrimp, tamarind sauce.', 'Tôm, sốt me.', 'Креветки, тамариндовый соус.', '새우, 타마린드 소스.', '虾、罗望子酱。')),
I('Fresh shrimp with Thai green chili sauce', 'Tôm sống sốt Thái', 'Сырые креветки с тайским соусом', '태국식 그린 칠리 소스 생새우', '泰式青辣椒酱生虾', 150000, 'sh_raw', n='32'),
I('Shrimp cooked in beer', 'Tôm hấp bia', 'Креветки, приготовленные в пиве', '맥주 찐 새우', '啤酒蒸虾', 150000, 'sh_beer', n='33'),
I('Grilled shrimp with cheese sauce', 'Tôm nướng phô mai', 'Креветки гриль с сырным соусом', '치즈 소스 새우구이', '芝士焗虾', 165000, 'sh_cheese', n='34',
  d=L('Shrimp, cheese sauce.', 'Tôm, sốt phô mai.', 'Креветки, сырный соус.', '새우, 치즈 소스.', '虾、芝士酱。')),
I('Sweet and sour shrimp', 'Tôm xào chua ngọt', 'Креветки в кисло-сладком соусе', '새콤달콤 새우볶음', '糖醋虾', 155000, 'sh_sweetsour', n='35'),
I('Deep fried shrimp', 'Tôm chiên bột', 'Креветки в кляре', '새우 튀김', '炸虾', 180000, 'sh_fried', n='80'),
])

sec('ss_squid', L('Squid', 'Mực', 'Кальмары', '오징어', '鱿鱼'), [
I('Deep fried squid', 'Mực chiên', 'Кальмар в кляре', '오징어 튀김', '炸鱿鱼', 180000, 'sq_fried', n='37',
  d=L('Squid, crispy batter.', 'Mực, bột chiên giòn.', 'Кальмар, хрустящий кляр.', '오징어, 바삭한 튀김옷.', '鱿鱼、脆面糊。')),
I('Sweet and sour squid', 'Mực xào chua ngọt', 'Кальмар в кисло-сладком соусе', '새콤달콤 오징어볶음', '糖醋鱿鱼', 160000, 'sq_sweetsour', n='38'),
I('Steamed squid with spring onion', 'Mực hấp hành', 'Кальмар на пару', '파 오징어찜', '葱蒸鱿鱼', 160000, 'sq_steam', n='39'),
I('Fried squid with garlic fish sauce', 'Mực chiên mắm tỏi', 'Жареный кальмар с чесноком', '마늘 피시소스 오징어 튀김', '蒜香鱼露炸鱿鱼', 160000, 'sq_garlic', n='40'),
])

sec('ss_oysters', L('Oysters & mussels', 'Hàu & vẹm', 'Устрицы и мидии', '굴 & 홍합', '生蚝与青口'), [
I('Raw oysters', 'Hàu sống', 'Устрицы сырые', '생굴', '生蚝', 30000, 'oy_raw', n='85', nt=L('per oyster', '1 con', 'за штуку', '1개', '每只')),
I('Oysters in cheese sauce', 'Hàu sốt phô mai', 'Устрицы в сырном соусе', '치즈 소스 굴', '芝士焗生蚝', 40000, 'oy_cheese', n='86', nt=L('per oyster', '1 con', 'за штуку', '1개', '每只')),
I('Oysters in garlic corn sauce', 'Hàu sốt bắp tỏi', 'Устрицы в чесночно-кукурузном соусе', '마늘 옥수수 소스 굴', '蒜香玉米生蚝', 40000, 'oy_corn', n='87', nt=L('per oyster', '1 con', 'за штуку', '1개', '每只')),
I('Mussels in cream sauce', 'Vẹm xanh trong sốt kem tỏi và rau thơm', 'Мидии в сливочном соусе', '크림소스 홍합', '奶油青口', 180000, 'mussels', n='79'),
I('Seafood assortment with vegetables and herbs', 'Hải sản tổng hợp với rau củ và thảo mộc thơm', 'Ассорти из морепродуктов', '채소 허브 모둠 해산물', '香草蔬菜海鲜拼盘', 250000, 'sea_assort', n='81'),
], note='oysters')

sec('ss_chicken', L('Chicken', 'Gà', 'Курица', '닭고기', '鸡肉'), [
I('Chicken breast in mushroom cream sauce', 'Ức gà sốt kem nấm', 'Куриная грудка в грибном соусе с пюре', '버섯 크림소스 닭가슴살', '奶油蘑菇鸡胸', 135000, 'ck_breast', n='42',
  d=L('Chicken, mushroom, cream sauce, mashed potatoes.', 'Gà, nấm, sốt kem, khoai tây nghiền.', 'Куриная грудка, грибной соус, картофельное пюре.', '닭고기, 버섯, 크림소스, 매시드 포테이토.', '鸡肉、蘑菇、奶油酱、土豆泥。')),
I('Deep fried chicken wings with fish sauce', 'Cánh gà chiên mắm', 'Куриные крылья', '피시소스 닭날개 튀김', '鱼露炸鸡翅', 110000, 'ck_wings', n='43',
  d=L('Chicken wings, fish sauce.', 'Cánh gà, nước mắm.', 'Жареные куриные крылья в соусе.', '닭날개, 피시소스.', '鸡翅、鱼露。')),
I('Sweet and sour chicken', 'Gà xào chua ngọt', 'Курица в кисло-сладком соусе', '새콤달콤 치킨', '糖醋鸡', 110000, 'ck_sweetsour', n='47'),
I('Chicken satay with peanut sauce', 'Gà sate que với sốt bơ đậu phộng', 'Куриные мини-шашлычки с арахисовым соусом', '땅콩 소스 치킨 사테', '花生酱鸡肉沙爹', 110000, 'ck_satay', n='49'),
])

sec('ss_meat', L('Meat, grill & burgers', 'Thịt, nướng & burger', 'Мясо, гриль и бургеры', '고기, 그릴 & 버거', '肉类、烧烤与汉堡'), [
I('Grilled pork neck skewers', 'Thịt nạc heo nướng xiên', 'Шашлык из свиной шеи', '돼지 목살 꼬치', '烤猪颈肉串', 180000, 'mt_skewers', n='44',
  d=L('Pork neck, herbs, spices.', 'Thịt cổ heo, rau thơm, gia vị.', 'Свиная шея, зелень, специи.', '돼지 목살, 허브, 향신료.', '猪颈肉、香草、香料。')),
I('Sun and Sea BBQ ribs', 'Sun and Sea sườn BBQ', 'Рёбра на гриле', '선앤씨 BBQ 립', '招牌烧烤肋排', 180000, 'mt_ribs', n='46',
  d=L('Pork ribs, BBQ sauce, served with fries and pickles.', 'Sườn heo, sốt BBQ, khoai tây chiên và dưa chua.', 'С нашим фирменным соусом: свиные рёбра, соус BBQ, с картофелем фри и пикулями.', '돼지갈비, BBQ 소스, 감자튀김과 피클.', '猪肋排、烧烤酱，配薯条和酸黄瓜。'), tg=['signature']),
I('Smoked sausages with mashed potatoes', 'Xúc xích xông khói và khoai nghiền', 'Копчёные колбаски с картофельным пюре', '훈제 소시지와 매시드 포테이토', '烟熏香肠配土豆泥', 180000, 'mt_sausage', n='48'),
I('Pork ribs in sweet and sour sauce', 'Sườn xào chua ngọt', 'Свиные рёбра в кисло-сладком соусе', '새콤달콤 돼지갈비', '糖醋排骨', 135000, 'mt_ribs_ss', n='73'),
I('Beef burger with French fries', 'Hamburger bò với khoai chiên', 'Гамбургер с говядиной и картофелем фри', '소고기 버거와 감자튀김', '牛肉汉堡配薯条', 160000, 'mt_burger_beef', n='76'),
I('Chicken burger with French fries', 'Hamburger gà với khoai chiên', 'Гамбургер с курицей и картофелем фри', '치킨 버거와 감자튀김', '鸡肉汉堡配薯条', 150000, 'mt_burger_chicken', n='77'),
I('Crocodile grill', 'Cá sấu nướng', 'Крокодил', '악어 구이', '烤鳄鱼肉', 120000, 'mt_croc', n='99'),
])

sec('ss_pasta', L('Pasta & risotto', 'Mì Ý & risotto', 'Паста и ризотто', '파스타 & 리조또', '意面与烩饭'), [
I('Tomato pasta', 'Spaghetti cà chua', 'Томатная паста', '토마토 파스타', '番茄意面', 120000, 'pa_tomato', n='50', d=L('Tomato sauce.', 'Sốt cà chua.', 'Томатный соус.', '토마토 소스.', '番茄酱。')),
I('Seafood pasta, tomato sauce', 'Spaghetti hải sản sốt cà chua', 'Паста с морепродуктами в томатном соусе', '토마토 해산물 파스타', '番茄海鲜意面', 170000, 'pa_sea_tomato', n='51.1'),
I('Seafood pasta, cream sauce', 'Spaghetti hải sản sốt kem', 'Паста с морепродуктами в сливочном соусе', '크림 해산물 파스타', '奶油海鲜意面', 170000, 'pa_sea_cream', n='51.2'),
I('Spaghetti carbonara', 'Spaghetti carbonara', 'Карбонара', '카르보나라', '卡邦尼意面', 150000, 'pa_carbonara', n='52', d=L('Cream, bacon, cheese.', 'Kem, thịt xông khói, phô mai.', 'Сливки, бекон, сыр.', '크림, 베이컨, 치즈.', '奶油、培根、芝士。')),
I('Spaghetti mushroom cream', 'Spaghetti sốt kem nấm', 'Паста в сливочном соусе с грибами', '버섯 크림 파스타', '奶油蘑菇意面', 120000, 'pa_mushroom', n='53', d=L('Cream, mushroom.', 'Kem, nấm.', 'Сливки, грибы.', '크림, 버섯.', '奶油、蘑菇。')),
I('Spaghetti seafood tom yum sauce', 'Spaghetti hải sản tomyum', 'Паста в соусе том ям', '똠얌 해산물 파스타', '冬阴功海鲜意面', 170000, 'pa_tomyum', n='54', d=L('Tom yum sauce.', 'Sốt tomyum.', 'Соус том ям.', '똠얌 소스.', '冬阴功酱。'), tg=['hot']),
I('Spaghetti with grilled shrimp in pink sauce', 'Spaghetti tôm nướng sốt kem cà chua', 'Паста с креветками на гриле в розовом соусе', '로제 소스 새우 파스타', '粉红酱烤虾意面', 160000, 'pa_pink', n='55', d=L('Pink sauce.', 'Sốt kem cà chua.', 'Розовый соус.', '로제 소스.', '粉红酱。')),
I('Spaghetti aglio e olio', 'Spaghetti sốt tỏi', 'Паста в чесночно-масляном соусе', '알리오 올리오', '蒜香橄榄油意面', 110000, 'pa_aglio', n='56', d=L('Garlic, olive oil, chili.', 'Tỏi, dầu ô liu, ớt.', 'Чеснок, оливковое масло, чили.', '마늘, 올리브오일, 고추.', '大蒜、橄榄油、辣椒。')),
I('Spaghetti bolognese', 'Mì spaghetti bò bằm sốt cà chua', 'Спагетти болоньезе', '볼로네제 스파게티', '肉酱意面', 170000, 'pa_bolognese', n='98'),
I('Risotto with shrimp', 'Cơm risotto tôm', 'Ризотто с креветками', '새우 리조또', '鲜虾烩饭', 210000, 'rs_shrimp', n='96'),
I('Risotto with seafood', 'Cơm risotto hải sản', 'Ризотто с морепродуктами', '해산물 리조또', '海鲜烩饭', 210000, 'rs_seafood', n='97'),
])

sec('ss_veg', L('Vegetables', 'Rau củ xào', 'Овощи', '채소 볶음', '炒蔬菜'), [
I('Mixed vegetable stir fry', 'Rau củ xào thập cẩm', 'Жареные овощи', '모둠 채소 볶음', '什锦炒蔬菜', VEG3(80000, 135000, 135000), 'vg_mix', n='66'),
I('Young pumpkin shoots stir fry', 'Nụ bí xào tỏi', 'Жареная молодая тыква, стручки', '어린 호박순 볶음', '蒜炒南瓜苗', VEG3(80000, 135000, 135000), 'vg_pumpkin', n='67'),
I('Water spinach stir fry with garlic', 'Rau muống xào tỏi', 'Жареный шпинат (водяной)', '마늘 공심채 볶음', '蒜炒空心菜', VEG3(60000, 115000, 115000), 'vg_spinach', n='68'),
I('Broccoli stir fry with garlic', 'Bông cải xào tỏi', 'Жареная брокколи с чесноком', '마늘 브로콜리 볶음', '蒜炒西兰花', VEG3(80000, 135000, 135000), 'vg_broccoli', n='70'),
I('Long green beans stir fry', 'Đậu que xào tôm khô', 'Жареная зелёная фасоль', '줄콩 볶음', '炒豇豆', 80000, 'vg_beans', n='71'),
I('Bitter gourd stir fry with eggs', 'Khổ qua xào trứng', 'Жареный горький огурец с яйцом', '여주 달걀 볶음', '苦瓜炒蛋', 70000, 'vg_gourd', n='72',
  d=L('Bitter, but very tasty 😊', 'Đắng nhưng rất ngon 😊', 'Вкус горький, но очень вкусно 😊', '쓰지만 정말 맛있어요 😊', '虽苦但很好吃 😊')),
])

sec('ss_sides', L('Potatoes, sides & bread', 'Khoai tây, món phụ & bánh mì', 'Картофель, гарниры и хлеб', '감자, 사이드 & 빵', '土豆、配菜与面包'), [
I('French fries', 'Khoai tây chiên', 'Картофель фри', '감자튀김', '薯条', 55000, 'sd_fries', n='61'),
I('Mashed potatoes', 'Khoai tây nghiền', 'Картофельное пюре', '매시드 포테이토', '土豆泥', 60000, 'sd_mash', n='62'),
I('Baked cheese mashed potatoes', 'Khoai tây nghiền phô mai đút lò', 'Запечённое картофельное пюре с сыром', '치즈 매시드 포테이토 오븐구이', '芝士焗土豆泥', 80000, 'sd_mash_cheese', n='63'),
I('Cheese potato croquettes', 'Khoai nghiền viên phô mai chiên', 'Картофельные шарики с сыром (крокеты)', '치즈 감자 크로켓', '芝士土豆可乐饼', 70000, 'sd_croquettes', n='64'),
I('Potatoes in creamy mushroom sauce', 'Khoai tây sốt kem nấm', 'Картофель в сливочно-грибном соусе', '크림 버섯 소스 감자', '奶油蘑菇土豆', 70000, 'sd_pot_mush', n='75'),
I('Black bread with garlic', 'Bánh mì đen nướng tỏi', 'Хлеб чёрный с чесноком', '마늘 흑빵', '蒜香黑面包', 45000, 'sd_bread', n='89'),
])

# ---------------------------------------------------------------- DRINKS
sec('ss_coffee', L('Coffee & more', 'Cà phê & thức uống', 'Кофе и не только', '커피 & 음료', '咖啡及其他'), [
I('Black coffee', 'Cà phê đen', 'Чёрный кофе', '블랙 커피', '越南黑咖啡', 30000, 'cf_black', n='01', d=L('Strong and rich Vietnamese black coffee.', 'Cà phê đen Việt Nam đậm đà.', 'Крепкий и насыщенный вьетнамский чёрный кофе.', '진하고 깊은 베트남 블랙 커피.', '浓郁的越南黑咖啡。')),
I('Vietnamese milk coffee (iced / hot)', 'Cà phê sữa đá / nóng', 'Вьетнамский кофе с молоком (со льдом / горячий)', '베트남 연유 커피 (아이스/핫)', '越南炼乳咖啡（冰/热）', 30000, 'cf_milk', n='02', d=L('Classic Vietnamese coffee with condensed milk.', 'Cà phê Việt Nam truyền thống với sữa đặc.', 'Классический вьетнамский кофе со сгущённым молоком.', '연유를 넣은 클래식 베트남 커피.', '经典越南炼乳咖啡。')),
I('Coffee with milk (bạc xỉu)', 'Bạc xỉu', 'Кофе с молоком (баксыу)', '박씨우 (밀크 커피)', '白咖啡（Bạc xỉu）', 40000, 'cf_bacxiu', n='03', d=L('Smooth and gentle coffee with condensed milk.', 'Cà phê nhẹ, êm với sữa đặc.', 'Нежный и мягкий кофе со сгущённым молоком.', '연유를 넣은 부드러운 커피.', '顺滑温和的炼乳咖啡。')),
I('Salted coffee', 'Cà phê muối', 'Солёный кофе', '소금 커피', '咸咖啡', 45000, 'cf_salted', n='04', d=L('Unique combination of coffee, creamy foam and sea salt.', 'Sự kết hợp độc đáo giữa cà phê, kem béo và muối biển.', 'Уникальное сочетание кофе, сливочной пены и морской соли.', '커피, 크림 폼, 바다소금의 특별한 조합.', '咖啡、奶油泡与海盐的独特组合。')),
I('Salted caramel coffee', 'Cà phê caramel muối', 'Кофе с солёной карамелью', '솔티드 캐러멜 커피', '咸焦糖咖啡', 50000, 'cf_caramel', n='05', d=L('Sweet caramel, creamy foam and a touch of salt.', 'Caramel ngọt, kem mịn và chút muối.', 'Сладкая карамель, мягкая пена и лёгкая солёная нота.', '달콤한 캐러멜, 크림 폼, 약간의 소금.', '甜焦糖、绵密奶泡与一丝咸味。')),
I('Americano (hot / cold)', 'Cà phê Americano (nóng / lạnh)', 'Американо (горячий / холодный)', '아메리카노 (핫/아이스)', '美式咖啡（热/冰）', 30000, 'cf_americano', n='06', d=L('Light and refreshing American style coffee.', 'Cà phê kiểu Mỹ nhẹ và sảng khoái.', 'Лёгкий и освежающий кофе в американском стиле.', '가볍고 상쾌한 아메리칸 스타일 커피.', '清爽的美式咖啡。')),
I('Coconut milk coffee', 'Cà phê dừa', 'Кофе с кокосовым молоком', '코코넛 밀크 커피', '椰奶咖啡', 50000, 'cf_coconut', n='07', d=L('Aromatic coffee with smooth coconut milk.', 'Cà phê thơm với nước cốt dừa béo mịn.', 'Ароматный кофе с нежным кокосовым молоком.', '부드러운 코코넛 밀크를 더한 향긋한 커피.', '香浓咖啡配顺滑椰奶。')),
I('Matcha green tea (blended)', 'Matcha đá xay', 'Матча зелёный чай (фраппе)', '말차 프라페', '抹茶冰沙', 55000, 'cf_matcha', n='08', d=L('Refreshing matcha green tea blended with ice and cream.', 'Trà xanh matcha xay đá với kem.', 'Освежающий зелёный чай матча со льдом и сливками.', '얼음과 크림을 갈아 넣은 상쾌한 말차.', '抹茶加冰与奶油打制，清爽。')),
I('Cacao (hot / iced)', 'Cacao (nóng / đá)', 'Какао (горячее / со льдом)', '카카오 (핫/아이스)', '可可（热/冰）', 50000, 'cf_cacao', n='09', d=L('Rich and chocolatey drink for cacao lovers.', 'Thức uống cacao đậm vị cho người yêu sô cô la.', 'Насыщенный шоколадный вкус для любителей какао.', '카카오 애호가를 위한 진한 초콜릿 음료.', '浓郁巧克力风味，可可爱好者之选。')),
I('Cacao latte', 'Cacao latte', 'Какао латте', '카카오 라떼', '可可拿铁', 45000, 'cf_cacaolatte', n='10', d=L('Chocolate latte with milk and soft foam.', 'Latte sô cô la với sữa và bọt mịn.', 'Шоколадный латте с молоком и нежной пеной.', '우유와 부드러운 폼의 초콜릿 라떼.', '牛奶与绵密奶泡的巧克力拿铁。')),
I('Matcha coconut', 'Matcha sữa dừa', 'Матча с кокосовым молоком', '말차 코코넛', '椰奶抹茶', 55000, 'cf_matchacoco', n='11', d=L('Matcha with coconut milk: smooth, tropical and refreshing.', 'Matcha với sữa dừa: êm, nhiệt đới và sảng khoái.', 'Матча с кокосовым молоком: нежно, освежающе, по-вьетнамски.', '코코넛 밀크 말차: 부드럽고 상쾌해요.', '椰奶抹茶：顺滑、热带、清爽。')),
], group='drinks')

sec('ss_juice', L('Fresh juice', 'Nước ép tươi', 'Свежие соки', '생과일 주스', '鲜榨果汁'), [
I('Orange juice', 'Nước cam', 'Апельсиновый сок', '오렌지 주스', '橙汁', 40000, 'ju_orange', n='01'),
I('Passion fruit juice', 'Nước chanh dây', 'Сок маракуйи', '패션프루트 주스', '百香果汁', 40000, 'ju_passion', n='02'),
I('Pineapple juice', 'Nước thơm', 'Ананасовый сок', '파인애플 주스', '菠萝汁', 40000, 'ju_pineapple', n='03'),
I('Watermelon juice', 'Dưa hấu', 'Арбузный сок', '수박 주스', '西瓜汁', 40000, 'ju_watermelon', n='04'),
I('Mix juice: orange, pineapple, carrot', 'Mix juice cam, thơm, cà rốt', 'Смесь соков: апельсин, ананас, морковь', '믹스 주스: 오렌지·파인애플·당근', '混合果汁：橙·菠萝·胡萝卜', 50000, 'ju_mix', n='05'),
I('Carrot juice', 'Cà rốt', 'Морковный сок', '당근 주스', '胡萝卜汁', 50000, 'ju_carrot', n='06'),
], group='drinks')

sec('ss_tea', L('Fruit tea', 'Trà trái cây', 'Фруктовый чай', '과일 티', '水果茶'), [
I('Mango tea', 'Trà xoài', 'Чай с манго', '망고 티', '芒果茶', 35000, 'te_mango', n='01'),
I('Peach tea', 'Trà đào', 'Чай с персиком', '복숭아 티', '桃子茶', 35000, 'te_peach', n='02'),
I('Lychee tea', 'Trà vải', 'Чай с личи', '리치 티', '荔枝茶', 35000, 'te_lychee', n='03'),
I('Kumquat tea', 'Trà tắc', 'Чай с кумкватом', '금귤 티', '金桔茶', 35000, 'te_kumquat', n='04'),
I('Mango & passion fruit tea', 'Trà xoài chanh dây', 'Чай с манго и маракуйей', '망고 패션프루트 티', '芒果百香果茶', 35000, 'te_mangopassion', n='05'),
], group='drinks')

sec('ss_smoothie', L('Smoothies', 'Sinh tố', 'Смузи', '스무디', '冰沙'), [
I('Mango', 'Xoài', 'Манго', '망고', '芒果', 45000, 'sm_mango', n='01'),
I('Banana with cacao and peanut butter', 'Chuối xay cacao, bơ đậu phộng', 'Банан с какао и арахисовым маслом', '바나나 카카오 땅콩버터', '香蕉可可花生酱', 50000, 'sm_banana', n='02'),
I('Strawberry', 'Dâu tây', 'Клубника', '딸기', '草莓', 50000, 'sm_strawberry', n='03'),
I('Strawberry, mulberry, blueberry', 'Dâu tây, dâu tằm, việt quất', 'Клубника, шелковица, черника', '딸기·오디·블루베리', '草莓·桑葚·蓝莓', 50000, 'sm_berry', n='04'),
I('Mango & passion fruit', 'Mix xoài, chanh leo', 'Манго и маракуйя', '망고 패션프루트', '芒果百香果', 50000, 'sm_mangopassion', n='05'),
I('Avocado', 'Bơ', 'Авокадо', '아보카도', '牛油果', 50000, 'sm_avocado', n='06'),
I('Pineapple & mint', 'Thơm, dứa, bạc hà', 'Ананас с мятой', '파인애플 민트', '菠萝薄荷', 50000, 'sm_pineapple', n='07'),
], group='drinks')

sec('ss_yogurt', L('Yogurt shakes', 'Sữa chua lắc', 'Йогуртовые шейки', '요거트 쉐이크', '酸奶奶昔'), [
I('Blueberry', 'Việt quất', 'Черника', '블루베리', '蓝莓', 45000, 'yg_blueberry', n='01'),
I('Mulberry', 'Dâu tằm', 'Шелковица', '오디', '桑葚', 45000, 'yg_mulberry', n='02'),
I('Mango', 'Xoài', 'Манго', '망고', '芒果', 45000, 'yg_mango', n='03'),
I('Passion fruit', 'Chanh dây', 'Маракуйя', '패션프루트', '百香果', 45000, 'yg_passion', n='04'),
I('Mango & passion fruit', 'Xoài chanh dây', 'Манго и маракуйя', '망고 패션프루트', '芒果百香果', 45000, 'yg_mangopassion', n='05'),
I('Mixed berry', 'Mix berry', 'Ягодный микс', '믹스 베리', '混合莓果', 45000, 'yg_berry', n='06'),
], group='drinks')

sec('ss_beer', L('Beer', 'Bia', 'Пиво', '맥주', '啤酒'), [
I('Saigon green', 'Sài Gòn xanh', 'Сайгон зелёное', '사이공 그린', '西贡绿', 25000, None, n='01'),
I('Saigon Special', 'Sài Gòn Special', 'Сайгон Спешл', '사이공 스페셜', '西贡特级', 35000, None, n='02'),
I('Tiger', 'Tiger', 'Тайгер', '타이거', '虎牌', 35000, None, n='03'),
I('Tiger Gold', 'Tiger Gold', 'Тайгер Голд', '타이거 골드', '虎牌金', 35000, None, n='04'),
I('Heineken', 'Heineken', 'Хайнекен', '하이네켄', '喜力', 40000, None, n='05'),
I('Corona', 'Corona', 'Корона', '코로나', '科罗娜', 60000, None, n='06'),
], group='drinks')

sec('ss_soft', L('Soft drinks', 'Nước ngọt', 'Безалкогольные напитки', '청량음료', '软饮'), [
I('Coca-Cola', 'Coca-Cola', 'Кока-кола', '코카콜라', '可口可乐', 20000, None, n='01'),
I('Coca-Cola light', 'Coca-Cola light', 'Кока-кола лайт', '코카콜라 라이트', '健怡可乐', 20000, None, n='02'),
I('Soda', 'Soda', 'Сода', '소다', '苏打水', 20000, None, n='03'),
I('Sprite', 'Sprite', 'Спрайт', '스프라이트', '雪碧', 20000, None, n='04'),
I('Lavie still water', 'Lavie (nước suối)', 'Лави (питьевая вода)', '라비 생수', 'Lavie 矿泉水', 20000, None, n='05'),
I('Sparkling water', 'Nước suối có gas', 'Газированная вода', '탄산수', '气泡水', 20000, None, n='06'),
I('Tonic', 'Tonic', 'Тоник', '토닉', '汤力水', 20000, None, n='07'),
], group='drinks')

RUM = lambda en, ru, vi: L(en, vi, ru)
V175 = 'Volume 175 ml'
sec('ss_souvenir', L('Souvenir spirits from Vietnam', 'Rượu lưu niệm Việt Nam', 'Сувенирный алкоголь из Вьетнама', '베트남 기념 주류', '越南纪念酒'), [
I('Caravelle citrus rum', 'Rượu rum Caravelle cam chanh', 'Цитрусовый ром Caravelle', '카라벨 시트러스 럼', 'Caravelle 柑橘朗姆', 100000, None,
  d=L('Fresh & zesty with natural citrus flavors. 175 ml.', 'Tươi mát với hương cam chanh tự nhiên. 175 ml.', 'Свежий и яркий вкус с натуральными цитрусовыми нотами. Объём 175 мл.', '천연 시트러스 향의 상큼한 맛. 175ml.', '清新柑橘风味。175毫升。')),
I('Caravelle mango rum', 'Rượu rum Caravelle xoài', 'Манговый ром Caravelle', '카라벨 망고 럼', 'Caravelle 芒果朗姆', 100000, None,
  d=L('Sweet & tropical mango flavor, smooth finish. 175 ml.', 'Vị xoài ngọt nhiệt đới, hậu vị êm. 175 ml.', 'Сладкий и тропический вкус спелого манго, мягкое послевкусие. Объём 175 мл.', '달콤한 열대 망고 향, 부드러운 끝맛. 175ml.', '香甜热带芒果风味，余味顺滑。175毫升。')),
I('Caravelle red rhum', 'Rượu rum Caravelle đỏ', 'Красный ром Caravelle', '카라벨 레드 럼', 'Caravelle 红朗姆', 100000, None,
  d=L('Rich & bold with a classic rum taste. 175 ml.', 'Đậm đà với vị rum cổ điển. 175 ml.', 'Насыщенный и классический вкус настоящего рома. Объём 175 мл.', '진하고 클래식한 럼의 맛. 175ml.', '浓郁经典的朗姆风味。175毫升。')),
I('Caravelle pineapple rum', 'Rượu rum Caravelle thơm', 'Ананасовый ром Caravelle', '카라벨 파인애플 럼', 'Caravelle 菠萝朗姆', 100000, None,
  d=L('Tropical pineapple aroma with a perfect balance. 175 ml.', 'Hương thơm nhiệt đới, cân bằng hoàn hảo. 175 ml.', 'Тропический аромат ананаса и идеальный баланс вкуса. Объём 175 мл.', '파인애플의 열대 향과 완벽한 균형. 175ml.', '热带菠萝香气，平衡完美。175毫升。')),
I('Caravelle passion fruit rum', 'Rượu rum Caravelle chanh dây', 'Ром маракуйя Caravelle', '카라벨 패션프루트 럼', 'Caravelle 百香果朗姆', 100000, None,
  d=L('Rich passion fruit taste with a smooth sugarcane aroma. 175 ml.', 'Vị chanh dây đậm, thoảng hương mía êm. 175 ml.', 'Насыщенный фруктовый вкус маракуйи и мягкий аромат сахарного тростника. Объём 175 мл.', '진한 패션프루트 맛과 사탕수수 향. 175ml.', '浓郁百香果味，甘蔗香顺滑。175毫升。')),
I('Napoleon brandy XO', 'Rượu brandy Napoleon XO', 'Бренди XO «Наполеон»', '나폴레옹 브랜디 XO', '拿破仑白兰地 XO', 120000, None,
  d=L('French style brandy XO, rich aroma & long finish. 175 ml.', 'Brandy XO kiểu Pháp, hương thơm đậm, hậu vị dài. 175 ml.', 'Французский бренди XO, богатый аромат и долгое послевкусие. Объём 175 мл.', '프랑스식 브랜디 XO, 풍부한 향과 긴 여운. 175ml.', '法式白兰地XO，香气浓郁，余韵悠长。175毫升。')),
I('Premium rice sake, original', 'Rượu gạo cao cấp, nguyên bản', 'Рисовый напиток «Оригинал»', '프리미엄 쌀술 오리지널', '优质米酒（原味）', 120000, None,
  d=L('Smooth & clean taste with a light aroma. 365 ml, 16% vol.', 'Vị êm và trong, hương nhẹ. 365 ml, 16%.', 'Мягкий и чистый вкус рисового напитка, лёгкий аромат и мягкое послевкусие. Объём 365 мл, крепость 16%.', '부드럽고 깔끔한 맛, 은은한 향. 365ml, 16%.', '口感顺滑干净，香气轻盈。365毫升，16%。')),
I('Premium rice sake, melon', 'Rượu gạo cao cấp, dưa lưới', 'Рисовый напиток «Дыня»', '프리미엄 쌀술 멜론', '优质米酒（蜜瓜）', 120000, None,
  d=L('Light & refreshing melon flavor. 365 ml, 13.5% vol.', 'Vị dưa lưới nhẹ, sảng khoái. 365 ml, 13,5%.', 'Лёгкий и освежающий вкус дыни, приятная сладость и фруктовый аромат. Объём 365 мл, крепость 13,5%.', '가볍고 상쾌한 멜론 맛. 365ml, 13.5%.', '清爽蜜瓜风味。365毫升，13.5%。')),
I('Premium rice sake, peach', 'Rượu gạo cao cấp, đào', 'Рисовый напиток «Персик»', '프리미엄 쌀술 복숭아', '优质米酒（蜜桃）', 120000, None,
  d=L('Sweet & delicate peach flavor. 365 ml, 12.5% vol.', 'Vị đào ngọt dịu. 365 ml, 12,5%.', 'Нежный и сладкий вкус спелого персика, фруктовый аромат и мягкое послевкусие. Объём 365 мл, крепость 12,5%.', '달콤하고 섬세한 복숭아 맛. 365ml, 12.5%.', '香甜细腻的蜜桃风味。365毫升，12.5%。')),
I('Premium rice sake, guava', 'Rượu gạo cao cấp, ổi', 'Рисовый напиток «Гуава»', '프리미엄 쌀술 구아바', '优质米酒（番石榴）', 120000, None,
  d=L('Tropical & fruity guava flavor. 365 ml, 12.5% vol.', 'Vị ổi nhiệt đới, thơm trái cây. 365 ml, 12,5%.', 'Тропический и фруктовый вкус гуавы, яркий аромат и освежающее послевкусие. Объём 365 мл, крепость 12,5%.', '열대 과일 구아바 맛. 365ml, 12.5%.', '热带番石榴果香。365毫升，12.5%。')),
I("Tequila 1902's collection", "Tequila 1902's collection", 'Текила 1902', '테킬라 1902', '1902 龙舌兰', 120000, None,
  d=L('Premium tequila from 1902, smooth & authentic. 175 ml, 39.5% vol.', 'Tequila cao cấp 1902, êm và chuẩn vị. 175 ml, 39,5%.', 'Премиальная текила 1902 года, мягкая и аутентичная. Объём 175 мл, крепость 39,5%.', '부드럽고 정통적인 프리미엄 테킬라. 175ml, 39.5%.', '优质龙舌兰，顺滑正宗。175毫升，39.5%。')),
], note='souvenir', group='drinks')
