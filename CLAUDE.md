# QR-меню и приложение для кафе (Вьетнам, Фантьет / Муйне)
n> Полное описание проекта для любого агента (Codex и др.) — в `AGENTS.md`. Этот файл — краткая версия.

Проект Марго: многоязычные QR-меню для кафе (продаём вьетнамским владельцам) и приложение для персонала (официант / кухня / владелец), которое принимает заказы из меню.
Сайт: https://dellviktoriapro.github.io/qr-menu/ (GitHub Pages, ветка `main`, корень репозитория).

## Как работать с Марго
- Общение на русском, коротко и по делу. Без лишнего оптимизма: честно говорить, что работает, а что нет и почему.
- Она не программист. Всё, что можно сделать самому (коммит, пуш, проверка), делать самому, не просить её скачивать или переименовывать файлы.
- Старые версии не хранить: после замены удалять устаревшие файлы из репозитория.
- После каждой правки: пересобрать (`python _src/build_all.py`), проверить в браузере (Playwright) светлую и тёмную тему, телефон 390px и ПК, закоммитить и запушить.

## Структура репозитория
```
index.html              список ссылок
chez-oanh/index.html    меню Café Chez Oanh (текст ~210 КБ) + ph1.js…ph5.js (фото кусками)
sun-sea/index.html      меню Sun&Sea Restaurant (Муйне) + ph1.js…ph4.js
demo/index.html         демо приложения персонала (один файл ~215 КБ)
lam-tong/index.html     меню Lam Tong (один файл, фото внутри)
presentation.pdf        презентация для владельцев кафе (на вьетнамском)
_src/                   исходники и сборка — править ТОЛЬКО здесь, потом build_all.py
```
`demo/index.html`, `chez-oanh/*`, `lam-tong/index.html` — собранные файлы. Руками их не править.

## Сборка
`python _src/build_all.py` (Python 3 + Pillow). Собирает все три страницы в корень репозитория.
- **Приложение:** `_src/ops/tpl.html` — основной шаблон (UI по-вьетнамски, все стили и логика). `_src/demo/mk.py` накладывает русские строки и автоязык (RU/VI по языку телефона или `#ru` / `#vi` в адресе). `_src/demo/build.py` вставляет `ph.json` (иконки блюд). Каждая замена в mk.py проверяется `assert`: если шаблон изменился и строка не нашлась, сборка упадёт — поправить mk.py.
- **Меню Chez Oanh:** данные в `_src/chez/data.py` (23 раздела, 296 позиций, 5 языков: en, vi, ru, ko, zh). Шаблон `_src/chez/tpl.html`. Веб-сборка `build_web.py` пишет текстовую страницу и фото в WebP кусками по ~650 КБ (`ph1.js`…). Куски грузятся по очереди после текста через `__ph({...})`; до загрузки у картинок прозрачная заглушка `BL#ключ`. Иначе (всё в одном файле, 5 МБ) страница грузилась 44 секунды. `build.py` — однофайловая версия для артефакта на claude.ai.
- **Lam Tong:** `_src/lam-tong/` (data.py, tpl.html, build.py).
- **Sun&Sea Restaurant (Муйне):** `_src/sunsea/data.py` — 25 разделов и 179 позиций, 5 языков. `build_web.py` использует общий движок `chez/tpl.html` и отдельный слой оформления `skin.css`; данные и цены из печатного меню. Каналы Sun&Sea: `ss_inbox`, `ss_pub`; ключи корзины и сессии `ss_*`. Цена None — уточнить у официанта. Файлы PNG/WebP в `ph/` подключаются автоматически, фотографии с альфой сохраняются. Шапка копируется как отдельный кешируемый WebP.
- **Вид Sun&Sea (23.10.2026, утверждён):** современный светлый прибрежный стиль в `_src/sunsea/skin.css`, фон `#f6f3eb`, зелёный `#26401c`, панорамная морская шапка `amb/hero.webp`, текстовый логотип. Тарелки без фона, масок и рамок; PNG/WebP подхватываются по ключу блюда, RGBA сохраняется. Сейчас 4 фото: `fish_beer`, `fish_lemon`, `smoked_mash`, `fish_corn`, остальные позиции текстом. Старые JPG остаются только материалами до замены. Генерация отмечена в GEN и пояснении карточки. Телефон — 2 блюда, планшет/ПК — 3, от 1700px — 4; на ПК сверху горизонтальная навигация, слева закреплённые разделы с иконками. Три блюда в ряд на ПК; на телефоне два. Пергамент и старый декор удалены. Подробности в AGENTS.md.
- **Движок меню (общий):** правки в `chez/tpl.html` попадают и в Chez Oanh, и в Sun&Sea; `sunsea/build_web.py` проверяет каждую замену `assert` — если шаблон изменился, сборка упадёт, поправить замену.
- **QR-таблички для столов:** `_src/tables-qr/mk.py` + `pdf.js`. A4, 4 таблички на лист, ссылка `chez-oanh/?t=N`. Сейчас столы 1–12 (реальное число столов в кафе не уточнено).
- **Колесо мыши над строкой категорий** прокручивает её вбок (оба меню); у края строки страница листается дальше.
- **Тесты (Playwright):** `_src/demo/tests_*.js`. `st` — подключение сотрудников, `bt` — счета по столам, `rt` — маршрут дозаказа, `e2e2` — меню → приложение (нужен локальный http-сервер, пути внутри поправить), `tc8` и `kc` — скриншоты цветов.

## Меню (гость)
- Выбор языка (можно сменить), цены в донгах плюс пересчёт в валюту языка (курс задаётся вручную в `RATES`), фото, корзина, пожелания («без сахара», «без льда»…).
- Номер стола берётся **только из QR на столе**: `?t=5`. Хранится 5 часов. В меню полей для номера стола нет.
- «Заказать» отправляет заказ в приложение. Гость видит «Заказ отправлен», корзина очищается, можно дозаказать. После первого заказа над корзиной две кнопки: «Попросить счёт» (наличные / карта, официант несёт счёт) и «Оплатить по QR-коду» (сумма + **статичный QR владельца**, загруженный в приложении; «Я оплатил(а)» шлёт официанту отметку «проверьте перевод»). Банк и касса не подключаются — это перевод на личную карту.
- **Раздельные чеки:** при первом блюде вопрос «Счёт общий или раздельный?». Раздельный → гость называет чек («Анна»), над корзиной полоска чеков и яркая кнопка «+ Гость», блюда идут в активный чек. Заказ уходит по одному на чек (`check` в сообщении), в приложении у заказа плашка «Чек: Анна», в счёте стола блоки по чекам. «Попросить счёт» и «Оплатить по QR» дают выбрать чек. Если сначала выбрали «Один общий счёт», в корзине есть кнопка «Разделить счёт»: блюда из корзины уходят в первый названный чек. После первого чека сразу спрашивается «Кто ещё платит отдельно?» (добавить следующий или «Готово»). Очистка корзины — через окно «Отмена / Да, очистить». Разные телефоны за одним столом заводят свои чеки независимо (общего списка чеков стола без сервера нет).
- **Чаевые:** блок внизу меню + яркая кнопка в окнах оплаты. Показывает QR официанта, который принял заказ стола (или «чаевые можно оставить после того, как официант примет заказ» / «официант не добавил QR — наличными»).
- Без номера стола (общая ссылка): «Заказать» сначала просит выбрать стол (1–12, `NT` в шаблоне), дальше всё как по QR. Режима «Показать официанту» больше нет.
- Связь меню ↔ приложение сейчас идёт через localStorage `co_inbox` + BroadcastChannel. **Работает только в одном браузере** (для показа владельцу). Для реальной работы нужен сервер — это следующий этап. Обратно приложение пишет `co_pub`: QR владельца, QR чаевых официантов и кто обслуживает какой стол.
- **Компоновка меню (v2, 21.10.2026):** компактная шапка со львом (название, «Стол N», ссылка «Адрес, часы, Wi‑Fi»), под ней закреплённая полоса: поиск + «Еда / Напитки» + круглые разделы (подсвечивается текущий; плавающая кнопка языка прячется, пока полоса прилипла). Блюда с фото — плитки по 2 (на широком экране по 3), без фото и добавки — списком под плитками. Адрес, часы, Wi‑Fi, преимущества — в блоке «О кафе» внизу. Внизу одна капсула (кружки гостей / число позиций, сумма, «Заказать» или «Счёт»); нажатие на капсулу открывает шторку стола: гости (+ Гость), «Попросить счёт», «Оплатить по QR», «Чаевые». Карусель фирменных блюд убрана.
- **Карточка блюда:** нажатие на плитку или строку блюда открывает шторку: большое фото (нажатие — на весь экран), название, оригинал, пометка «иллюстрация», варианты с ценой и кнопкой. **«В корзину»:** при добавлении фото летит в капсулу, капсула подпрыгивает, лёгкая вибрация (учитывается prefers-reduced-motion).
- **Живой статус:** приложение публикует в `co_pub.ord` заказы открытых счетов по столам (№, статус, официант). Меню показывает в шторке стола «Ваш заказ #N» с шагами Отправлен → Принят → Готовится → Несём → Подано и подписью («Minh несёт заказ к столу»), а в капсуле — текущий статус. Только заказы текущего визита (с первого заказа, `co_guest.ord0`). Обновление по событию storage и раз в 3 с.
- Дизайн Chez Oanh: «сафари-лаунж ночью» — тёмный тёплый фон, золото/янтарь (`--amber #e39a3b`), шрифты Cormorant Garamond + Montserrat. Главные кнопки с переливом (sweep) и мягким свечением.

## Приложение персонала (demo)
- Роли: Официант, Кухня, Владелец, Новый сотрудник. Режим «Все экраны» показывает официанта и кухню рядом. Окна «Гость» в приложении нет — гость заказывает через меню.
- Поток: QR-заказ → официанты получают уведомление → официант принимает, уточняет у стола, правит, добавляет комментарий → «Отдать в работу» → кухня/бар отмечают блюда → «Готово» → уведомление официанту (с эскалацией на всех, настраивается владельцем).
- **Счёт на стол:** все заказы и дозаказы стола — один счёт с общей суммой, дозаказы помечены. Закрывает официант («Оплачено · закрыть стол», подтверждение повторным нажатием).
- **Вкладки официанта (порядок):** Новые · Мои · Готово · Вынесено (вынесено, счёт открыт) · Завершённые (стол оплачен и закрыт, пометка «Оплачено · способ») · Столы (в конце, по просьбе Марго).
- **«+ Устный заказ»:** круглая плавающая кнопка внизу справа на экране официанта (не на кухне); уведомления поднимаются над ней.
- **Способ оплаты при закрытии:** три крупные кнопки с иконками (Наличные / Карта / Перевод по QR), выбранная залита медью; если не выбрано — блок «Как оплатили» краснеет и встряхивается.
- **«Вынес» ≠ оплачено:** вынесенный заказ остаётся в открытом счёте стола (вкладка официанта «Вынесено», пометка «Счёт открыт», кнопки «+ Дозаказ» и «Счёт»). Дозаказ идёт в тот же счёт. Стол закрывает только официант, когда принял оплату («Оплачено · закрыть стол»), после этого у заказов пометка «Оплачено».
- **Как оплатили:** в счёте стола блок «Как оплатили» — Наличные / Карта / Перевод по QR; при раздельных чеках по строке на каждый чек. Подставляется из просьбы гостя, без отметки стол не закрывается. Хранится в `bill.pays` (по чекам) и `bill.pay` (или `mix`). У владельца в аналитике карточка «Способы оплаты». «Сбросить» в демо сохраняет QR оплаты, ссылки на отзывы и QR чаевых.
- **Дозаказ** идёт сначала официанту этого стола. Через 40 секунд (`REORDER_MS`) или если он не на смене — всем.
- **Просьба о счёте** из меню: уведомление официанту стола (или всем, если его нет на смене), красная плашка над вкладками, пульсирующая карточка стола.
- **Подключение сотрудников:** сотрудник сканирует QR кафе → вводит имя и телефон → заявка владельцу → владелец подтверждает и выбирает роль. Владелец видит список, меняет роль, блокирует, удаляет (история сохраняется), перевыпускает код кафе. Есть журнал действий. **PIN-вход не нужен** — решение Марго.
- **QR для оплаты и чаевых:** владелец загружает статичный QR своей карты во вкладке «Сотрудники» (пока не загружен — красная плашка). Официант загружает свой QR для чаевых при подключении (необязательно) или кнопкой «QR для чаевых» на своём экране (пока QR нет, кнопка медная и пульсирует, отдельной плашки нет); в списке команды видно «QR ✓/—». Фото ужимается до 640px JPEG.
- **Стоп-лист:** повар (роль «Повар / бар», экран «Кухня» → вкладка «Стоп-лист») и управляющий/владелец (экран «Владелец» → «Стоп-лист») отмечают «Закончилось» / «Вернуть» по всему меню Chez Oanh (поиск по названию). Полное меню попадает в приложение при сборке (`__CO__` в `ops/tpl.html`, подставляет `demo/build.py` из `chez/data.py`), ключ блюда `раздел|номер`. Список уходит в меню через `co_pub.stop`: у гостя блюдо приглушено с пометкой «Закончилось», кнопки «+» нет; если оно уже в корзине — убирается с уведомлением (меню проверяет раз в 10 с и по событию storage).
- **Отзывы:** владелец во вкладке «Сотрудники» вписывает ссылки на страницу кафе в Google Картах и Tripadvisor (только https://), они уходят в меню через `co_pub.rev`. Гость видит окно «Спасибо, что были у нас!» с кнопками на эти страницы: сразу после «Я оплатил(а)» по QR или когда официант закрыл стол (`co_pub.closed` — время закрытия по столам). Закрытие стола также завершает сессию гостя в меню (чеки, кнопки счёта). Окно показывается один раз за визит; без ссылок не показывается. Кнопка «Сбросить» в демо приложения очищает и сессию меню в этом браузере.
- Аналитика владельца: выручка, чеки, средний чек на стол, время принятия, время готовки, таблица официантов, топ блюд, языки гостей, выручка по часам.
- **Периоды в аналитике:** Сегодня / Вчера / 7 / 30 / 90 дней / Свой период (календарь, до 180 дней назад), сравнение с прошлым таким же периодом (▲▼%), «Выручка по дням», кнопка «Скачать для Excel» (CSV, разделитель «;», UTF-8 с BOM). Дни считаются по времени Вьетнама (UTC+7). В демо: сегодня — настоящие заказы в браузере, прошлые дни — детерминированная примерная история (`genDay`, одна и та же для одной даты); день с демо-заказами (`seed`) историей не дополняется. С сервером это заменится запросами к сохранённым заказам.
- **Заведения (21.10.2026):** приложение работает с выбранным заведением (кнопка с домиком рядом с названием): Café Chez Oanh или Sun&Sea Restaurant. Владелец «входит» в своё и видит только его: заказы, счета, сотрудников (у Sun&Sea свои имена: Tuấn, Hoa, Long, Bảo, Hải, Vy), код подключения (`CO-7F3K` / `SS-4M2Q`), стоп-лист по своему меню, QR оплаты, отзывы, аналитику. Настройки — объект `CAFES` в `ops/tpl.html` (`sfx` хранилища, `inbox`/`pub` канал меню, `mk` префикс ключей меню, блюда для устных заказов `MENU_CO` / `MENU_SS`). Выбор хранится в `ops_cafe`, переключение перезагружает приложение. Меню Sun&Sea пишет в `ss_inbox` и читает `ss_pub`, Chez Oanh — `co_inbox` / `co_pub`. С сервером это станет `cafe_id` у каждой записи.
- Данные демо: localStorage `co_ops_demo_v2` (Chez Oanh) и `co_ops_demo_v2_ss` (Sun&Sea), синхронизация вкладок через BroadcastChannel.

## Дизайн приложения
- **Карта зала:** вкладка официанта «Столы» → «Карта зала / Список». Зал — столы 1–8, терраса — 9–12 (+ столы выше 12, если есть счета). Состояние стола: свободен (пунктир), новый заказ (серебро, пульс), готовится (сталь), готово (медь, свечение), просит счёт (красный, пульс), занят (всё вынесено). Нажатие: открытый счёт → счёт стола; свободный → «Записать заказ устно» на этот стол. Расстановка условная — заменить по плану кафе.
- **Свайп:** на карточках официанта смахнуть вправо = главная кнопка карточки (Принять / Отдать в работу / Вынес); под карточкой видна подсказка.
- **Шапка экрана официанта:** строка «Я · QR для чаевых · смена» лежит на фоне, вкладки статусов — на светлой плашке (по просьбе Марго).
- **v2 (21.10.2026):** карточка заказа — слева блок в цвете стола (крупный номер, таймер м:сс, красный при опоздании), справа строка состояния (цветная точка + статус + дозаказ/чек, имя официанта справа), блюда, сумма и одна главная кнопка, мелкая строка «язык · №, итого по столу, сколько прошло». На телефоне (≤760px) тема, язык, звук и демо-кнопки спрятаны под кнопку ☰. Кухня: строки блюд высотой под палец с кружком-галочкой, «Готово» на всю ширину; телефон — одна колонка, планшет — сетка карточек (minmax 270px). Цвета кухни прежние.
Темы переключаются атрибутом `body[data-skin]`. `data-theme` не использовать — конфликтует с просмотрщиком артефактов.
- **Тёмная** (референс: графитовые панели с медью): фон `#1b1b1e`, карточки `#29292d`, медь `#e77a43`, градиент `#f7ad78 → #e77a43 → #b9512a`, серебро `#b8bbc1`.
- **Светлая — Japandi:** ivory `#EDE6DB`, stone beige `#D6CCBD`, warm taupe `#AFA091`, sage `#7F8A74`, natural wood `#B88B60`, deep brown `#4B3E33`, soft charcoal `#2D2D2D`, терракота `#b8683f`, олива `#6e7350`.
- **Без зелёных кнопок.** Главные действия выделять переливом и подсветкой (`.btn.green` на самом деле медный, с анимациями `shine` и `glow`).
- Статусы: новый — серебро (светлая: тёмно-коричневый), принят — латунь/дерево, готовится — сталь/шалфей, готово — медь/терракота, опоздание — красный.
- **Цвет стола** `--t1…--t8` (стол N → `--t((N-1)%8+1)`), один и тот же на всех экранах: шапка и левая полоска карточки официанта, шапка и верхняя полоска на кухне, фон карточки во вкладке «Столы».
  - Тёмная: медь, стальной голубой, латунь, бирюза, роза, сливовый, зелёный, персиковый — так утвердила Марго.
  - Светлая — только цвета Japandi: терракота, олива, дерево, сланцевый, тёплый серо-бежевый, тёмно-зелёный лён, светлый шалфей, тёмно-коричневый. Следить, чтобы соседние номера не были похожи (стол 1 и 5 уже были — исправлено).
- На кухне опоздание (>15 мин) — красная рамка и таймер на красном фоне; шапка остаётся в цвете стола.
- Вкладки владельца «Аналитика / Сотрудники» — крупный переключатель с иконками; выбранная вкладка медная, с переливом.

## Следующий этап (продакшен)
1. Сервер и база: Supabase (Postgres + Realtime + Auth). Таблицы: cafes, staff, tables, bills, orders, order_items, events. Политики RLS по cafe_id.
2. Меню пишет заказ и просьбу о счёте в базу; приложение подписывается через Realtime. Заменить localStorage-мост `co_inbox`.
3. Вход сотрудников: заявка по QR кафе (как в демо) плюс подтверждение телефона (OTP по SMS или через Zalo).
4. Уведомления: Web Push (Android — да; iPhone — только если приложение установлено на главный экран) и дублирование через Zalo OA-бот — основной надёжный канал во Вьетнаме.
5. Несколько кафе: своё меню, свои сотрудники и свои QR-коды у каждого.
6. Хостинг: GitHub Pages или Vercel/Netlify, свой домен.

## Прочее
- Презентация для владельцев (Slides-артефакт на claude.ai + `presentation.pdf`): на последнем слайде заглушки `[số điện thoại]`, `[Tên của bạn]`, `[email]` — ждут контакты Марго.
- Демо и меню также опубликованы как артефакты на claude.ai (не везде открываются, поэтому основной адрес — GitHub Pages).

### Sun&Sea — загрузка и уточнение макета (23.10.2026)
- Первый перенос отличался от утверждённого макета; исправлены шапка, верхняя навигация, иконки разделов, отступы и порядок первого ряда. Все блюда и цены сохранены, порядок отображения не меняет ID заказа.
- Фото больше не передаются общим base64-пакетом `ph1.js`. Сборщик пишет отдельные WebP: 480px quality 76 для меню (lazy), 960px quality 82 только по открытию блюда/фото. Прозрачность сохранена; имена включают хеш содержимого.
- Отдельные `hero.webp` (до 1600px) и `hero-mobile.webp` (до 960px); мобильная композиция хранится в `amb/hero-mobile.webp`, тени пальм — небольшой `amb/palm-shadow.svg`.
- Google Fonts CSS подключается без блокировки первого отображения; системные шрифты остаются запасным вариантом.
- Страница + мобильная шапка + все 4 миниатюры: около 485 КБ до HTTP-сжатия (прежняя страница с 3 фото: 1,31 МБ). Это вес файлов, не измеренное время загрузки на устройстве пользователя.

### Sun&Sea — правки 23.10.2026, следующая партия
- По просьбе Марго категории теперь только в боковой панели на ПК >=1100px, только сверху на телефоне/планшете. Удалён дублирующий coastNav. Ссылка «Информация о ресторане» после «Напитки» в единственной навигации.
- Декор: видимые листья справа сверху (palm-shadow.svg) и волны слева снизу (waves.svg), оба лёгкие SVG, pointer-events:none. У body::before сброшены старые inset/overlay из общего шаблона.
- Удалены скрытые medals с eager img, которые загружали фото всех разделов. IntersectionObserver с rootMargin220px активирует data-menu-src только рядом с экраном; большой960px остаётся по открытию блюда. Мобильная шапка уменьшена до640px quality72.
- Добавлены сгенерированные RGBA mimosa.png, marlin_soup.png, pz_margherita.png; smoked_mash.png заменён подачей запеканки в сковороде по присланному постеру. Всего7 изображений блюд. У заменённых mimosa/marlin_soup удалены JPG. Изображения являются иллюстрациями, не реальной съёмкой кухни.
- Повторно сверены179 цен и вариантов по присланным страницам: совпадают. Неоднозначности оригинала: две подачи тамариндовой рыбы, бетель/лотос, подпись Цезаря, повторные96/97. Не добавлять дубли блюд по повторным номерам.

### Sun&Sea — читаемость и навигация, правки Марго 23.10.2026
- Номера блюд скрыты в гостевом меню (текстовые строки и фото); исходные номера в data.py сохранены для сверки, ID заказа не менялись.
- skin.js содержит25 различных SVG для25 разделов; больше нет общей рыбы у креветок/кальмаров/устриц и общей иконки мяса у курицы.
- Боковая панель расширена до244px, поиск12px с box-sizing:border-box/min-width:0, названия разделов13px; текст поиска помещается.
- Названия блюд28px на ПК/23px у фото на телефоне, описания14px, основная цена30px/24px, рублёвая14px/13px, показана и на телефоне.
- Устранено растягивание .tile .txt и margin-top:auto у цены: цена следует за описанием с небольшим отступом. Фото-контейнеры компактнее.
- Для каждого раздела светлая тематическая полоса sage/sand/sea с крупной иконкой, границей и заметным отступом от предыдущего раздела. Без тяжёлых новых растровых фонов.

### Sun&Sea — уточнение оформления 23.10.2026
- Марго отвергла новый набор25 нарисованных иконок и цветные полосы разделов. Восстановлен исходный тонкий набор coastIcon из0a59830. Не заменять его заново без отдельного согласованного образца.
- Заголовки разделов без заливок и крупных значков: тонкая нейтральная линия и отступ.
- Карточки с фото выровнены по4 общим строкам CSS subgrid: фото, название, описание, цена. Пустой слот описания допустим, состав не придумывать. Размеры рассчитываются по текущему ряду и языку; на телефоне2 карточки, на ПК3.

- Микроанимации кнопок окна заказа (#sheet): hover160ms только мышь/трекпад, press scale.97, фокус с обводкой; prefers-reduced-motion убирает движение. Выбор нового основного шрифта и рукописных подписей пока на стадии образцов, не применять до выбора Марго.

- Марго выбрала вариант Б: Lora для заголовков, названий блюд и основных цен. Manrope для служебного текста, Cormorant сохранён в логотипе. Caveat32px/29px и лёгкий наклон для коротких подписей пирогов/пиццы рядом с названием раздела. Условия предзаказа не делать рукописными. Одобрена лёгкая морская рябь sea-ripple.svg в спокойном фоне, без заливок разделов.

- Уточнение Марго: разделительная линия под названием раздела (border-bottom), не над ним. Валюта в верхнем правом углу боковой панели, рядом с Еда/Напитки; поиск ниже. Спорные повторяющиеся иконки нужно заменить профессиональными, сохранив хорошие первые; образец Hugeicons + кальмар Streamline показан для выбора, пока не применён.

- Марго одобрила8 иконок из образца Hugeicons: лапша, рис, креветки, раковина, курица, мясо, паста, картофель. Установлены через COAST_REPLACEMENTS. Кальмар Streamline отклонён, не применять; новый вариант ещё выбирается. Первые подходящие иконки не менять. Лицензия в ICON_LICENSES.md.

- Марго просит самостоятельно отсеивать средние и явно слабые варианты: не выносить такие варианты на выбор. Для кальмара выбран естественный контур OpenMoji, с вытянутым телом, боковыми плавниками и длинными щупальцами; диагональный поворот помогает прочтению в22px. Не использовать геометрические «ракеты». Всего9 адресных замен, остальные первые иконки сохранены. Кальмар CC BY-SA4.0 с атрибуцией и отдельным squid.svg.

- Марго выбрала Б для оформления заголовков и корзины: нейтральный рельеф тон в тон, без цветных полос. Дополнительно явно попросила светлые тематические рисунки как тени возле названий. Реализованы section-shadow (approved coastIcon,88px/60px,opacity.085/.065,aria-hidden,pointer-events:none), запас справа под рисунок. Корзина: нейтральная верхняя полоса и отдельный тональный блок итога. Линия под заголовком сохранена, сверху жёсткой линии нет.


### Sun&Sea — unique category artwork and quiet scrolling scenery (2026-10-23)
- All 25 categories have distinct artwork, shared by sidebar and header shadows. Rolls use sushi-03; soups retain the steaming bowl. Nine further Hugeicons replace repeated leaves, cups and bottles; approved earlier icons remain.
- Scenery is anchored to every third rendered section: palm, caravel, flower, lighthouse. Absolute decoration scrolls with content; no fixed palm or scroll listener. Opacity .035–.045 and aria-hidden / pointer-events:none.
- Cart header has a faint serving cloche; split checks have separate rounded blocks in three neutral shades. Guest avatar palette is neutral too. Order logic, IDs, prices and translations unchanged.
- Sources only _src/sunsea; asset attribution in ICON_LICENSES.md. Local browser checks cover 25 unique SVGs, 179 dishes, mobile/desktop widths, languages, order submission, cart motion and three split-check shades.


### Sun&Sea image production and consistent dish layout — 23 Oct 2026
- User authorized ALL 113 remaining food images, based strictly on original menu pictures. Onion: omit or use tidy closed rings; never long worm-like slivers. Original pages available in D:/Users/Николай/Downloads/photo_53888141286605534*_y.jpg. Printed raw ingredient props must not become part of a plated dish.
- First verified batch adds fish_tamarind, prawns_beer, sq_fried, sq_steam (11 photos total). Corresponding obsolete JPG crops removed; menu IDs/prices unchanged. Remaining generated candidates staged in the chat workspace work/generated-food, manifest.jsonl and food-generation-jobs.json; not all published yet.
- User raised generation-limit cost. Stopped the single-image queue; no further generations until choosing individual quality vs testing two dishes per sheet. 28 new single assets plus first six generated before stop, with corrected meat/cabbage pies and onion-free garlic/sweet-sour squid replacements.
- Unified photo/text dish font, title, main/sub prices, variant labels and add buttons. Text-only rows use a shared description/price subgrid, no invented descriptions. Menu-only badges/original-language labels hidden consistently; detail sheet keeps them. Explicit inner tile minmax(0,1fr) and title wrapping prevent long seafood name overflowing 320px.
- Optional SUNSEA_WEBP_CACHE caches by source content + size + quality. Warmed from byte-identical existing built assets, no image quality change; repeated build takes seconds. Cache lives outside repo in this chat work/webp-cache.
- Verified in Chromium at 320/390/768/1440; consistent Lora price fonts 23px mobile/28px desktop; text-row title/description/price align; 179 dishes/25 sections; local order submission and staff light/dark unaffected.


### Sun&Sea — strict grid and second photo batch
- User explicitly chose economical production: two dishes on one sheet. Trial Caesar + tuna avocado mango yields 991/992px per crop; good for 960px detail delivery. Split at transparent center seam without resizing or changing pixels. Remaining paired queue in chat work/food-pairs-pending.json, sheet manifest in work/food-sheets/manifest.jsonl. Generation runs only via built-in imagegen; no API fallback.
- Published source set now contains 41 photographs (34 new plus previous7): full chef, pies, pizzas, most salads, one tuna salad, squid. Original plating references recorded in _src/sunsea/image-provenance.json. Corrected raw ingredient props on meat/cabbage pies and removed onion pieces in garlic/sweet-sour squid.
- New user priority: every spacing/axis must follow a clear grid. Final CSS grid contract at end of skin.css: same 3 columns desktop>=1100 / 2 below for tiles AND text rows; shared column gaps32/24/16; section gaps48/32; consistent card padding24/20 and inner row gaps8. Header background bleeds into page gutter so h2 and item text align on exact same x axis. No fixed-height title hacks or invented descriptions.
- Chromium checks passed70 combinations: widths320/390/768/1099/1100/1440/1920 x5 languages x2 groups. Verified exact title axes, shared row tracks, column counts, section gaps, no horizontal overflow. Full functional test passes25sections/179items/41photos and cart/order/staff checks.
- Builder encodes independent images in a 4-worker pool, deterministic dict order and identical WebP settings; optional content cache maintained outside repo. Repeated builds byte-stable for existing assets.


### Sun&Sea — completion: all120 food images and verified grid
- Added all113 previously missing food illustrations, total120 PNG sources and240 responsive WebP assets. Every food item has a photo;59 drink records remain text. All179 menu records/prices unchanged. Paired generation selected by user; sheets split without resampling, transparent center seam selected to avoid neighboring fragments. Final corrections removed unwanted onion, detached skillet handle and wrong mussel dishware.
- Final source reference/pixel audit is _src/sunsea/image-provenance.json (113 new assets). Source pages remain in user's Downloads and original scans in _src/sunsea/src; obsolete JPG crops removed only after replacement.
- Final build:268KB HTML;120 photos;5967KB total thumbnails, loaded only near viewport; detail files only on tap. All240 WebP files have genuine alpha and correct max480/960px dimensions.
- Fresh tests with full120-photo menu passed:70 grid combinations (7 widths x5 languages xfood/drinks), identical photo/text price typography,25 sections179 positions, local QR order to correct venue/table, staff light/dark, five languages, currency, search, stop list, cart motion/reduced motion, split-check shades, no page JS errors.
- No remaining generation queue. Production prompt/report artifacts saved under this chat outputs; all project assets copied into repository. Root work/generated-food retains candidates/metadata outside repository for audit only.

### Sun&Sea — right-only supplied line art and stable fonts
- Client supplied two transparent PNG borders (23 Oct,15:12), now amb/coast-right.png and botanical-edge.png. Built lossless WebP; botanical border mirrored in CSS. Every section has faint right-only absolute artwork scrolling with document, no fixed background or left decoration. Old six background SVG assets removed. Unique category header icons retained.
- All four selected fonts bundled locally with OFL licenses, hashed WOFF2 subsets and seven Latin/Cyrillic preloads; no Google Fonts runtime dependency. Real font loading verified; layout coordinates stable after loading.
- Price controls align at top on desktop; mobile main price has its own row, converted price and add/quantity share second row, variant label third. Buttons align across the row including variant dishes.
- Fresh Chromium verification passed70 width/language/group grid combinations, all120 photos/179records, order/cart/stoplist/staff checks; no page errors. Supplied art checked visually at390/1440.
- Category shadow drawings now follow the heading text in a flex row (64px desktop/44px mobile), instead of being pinned to the far right. Verified70 responsive/language/group combinations after change.
- Restaurant information link is its own first navigation row, above food/drinks; currency remains to the right of food/drinks, search below. Verified exact row positions at390/1440 and70 grid combinations.

### Sun&Sea — brighter coastal design and all drink imagery (24 Oct 2026)
- User requested stronger warmth/art based on original golden printed menu. Background now #f4e9d1, neutral warm section headers #ecdfc3, right line art .31/.24 and title art .25. No texture/grunge or left-side decoration.
- Mobile sticky navigation has a compact scenic ribbon from existing hero-mobile, with a cream fade to protect text contrast. Restaurant information block has right-side ship/coast artwork on a warm cream background.
- All59 drinks now have transparent illustrations referenced to original menu pages3430/31/32/33/34/37. Built-in imagegen in two-item sheets per user's economical preference; mapping in drink-photos.json, provenance in drink-image-provenance.json. Source records and order IDs/prices unchanged; builder applies image keys to its copied DATA only.
- Brand/container review corrected sparkling water (green glass bottle, not plastic still water), mango-passion yogurt color and removed extra glasses on peach/guava rice drinks. Asset files in ph; old generated hashes removed on rebuild.
- Permanent URL only https://dellviktoriapro.github.io/qr-menu/sun-sea/ ; do not append ?v links. Previous query suffixes were cache-busting aliases, not separate sites. Production constant URL confirmed200 and opened in Chrome; publication was successful.
- User's unsubmitted three-item cart was cleared through Chrome UI with its confirmation. Prior sent-order status135000 remains intentionally untouched.
- Final verification:179 photos/179 records;358 alpha WebP files at480/960max;290KB HTML;7737KB thumbnails loaded near viewport only. Chromium functional/order tests pass,70 responsive/language/group grid combinations pass; mobile navigation and about artwork inspected visually.
- Further user refinement24Oct: background now visibly golden #f3d68f with warm tonal gradients, heading strips #edcd88; right line art .45/.35 and heading artwork .36. User explicitly asked twice for richer brightness closer to printed menu. No food photo filters.
- Chef section note shortened in all5languages to just the chef signature introduction. Per-dish smoked fish/shrimp pre-order/price notes preserved.
- Language button moved in builder from floating hero position into nav-info next to restaurant information, above food/drinks. Single original button/event handler retained, compact language code and globe; responsive tests320/390/768/1440 confirm no overlap and same row; all5language switches pass.70 menu grid combinations pass.

### IMPORTANT: Sun&Sea standalone sales mode, 24 October 2026
- User now sells ONLY the menu, without the staff app. Default service-mode.json mode=menu_only. Show the waiter replaces send order, with bilingual RU/current-language + VI summary. The cart is retained until explicit Clear. No table prompt, split-check onboarding, order statuses, bill requests, tips, payment acknowledgement or ss_inbox/BroadcastChannel sending.
- Keep QR payment as a standalone button in cart and footer. No QR is configured yet; honest unavailable text, no fake image, no automatic paid status. Future QR setup documented in _src/sunsea/RESTORE_ORDERING.md.
- USER EXPLICITLY REQUIRES RESTORING EVERYTHING LATER. Change service-mode.json mode to full and rebuild/publish. Full JS/CSS layer omitted; original shared engine untouched, legacy storage preserved separately. Baseline full-ordering commit dba133a2e8f1fc1db9616b9c91b5d6e9bbe563c7. Read RESTORE_ORDERING.md before restoring. Do not delete the full workflow.
- User asked about5guests scanning one table QR: explained that current carts are independent and common cart requires server/database; no server/common cart implementation authorized yet.
- Performance: prior two lossless background borders totaled1245KB and loaded immediately. Delivery-only640px q80 WebP versions total454KB, original PNG retained, filenames content-hashed. Border art activated only near viewport; mobile hero URL unified to avoid duplicate download; visible food photos prioritized. Layout/design and photo sources unchanged.
- Verified both branches: standalone manual summary/VI names, QR configured/unconfigured, no inbox writes, cart after reload, legacy full-mode cart untouched, five languages and four widths. Separate full-mode build passed the original end-to-end QR order to Sun&Sea table5 plus staff light/dark, statuses, split checks, QR and motion tests.70 grid combinations pass in standalone mode.


### Sun&Sea shared table cart — implementation awaiting public access approval, 25 Oct 2026
- User explicitly changed requirement: every guest scanning the same table QR sees one shared cart; separate named checks are optional. This supersedes the earlier independent-cart decision.
- `_src/sunsea/shared-cart.js` is injected only in menu_only mode and only activates with a valid `room` capability in the table QR. Root menu remains a private local selection. The full ordering engine and full-mode restoration stay unchanged.
- Backend source is `C:/Users/Николай/Documents/Codex/2026-10-23/new-chat/work/shared-cart`, a Sites Vinext Worker with D1. Site ID appgprj_6adca4daa9c08191ad3b1da3a32d99d7. Private deployment succeeded; source commit1403b8e203bc3c227d3eedfabf28f8d9f9964d16, version appgprj_6adca4daa9c08191ad3b1da3a32d99d7~appgver_2f23b20e42988191b18d42e5ec9c36e3. API https://sunsea-table-cart.promokod4u.chatgpt.site/api/cart.
- IMPORTANT: public access was rejected by automatic approval review, which requires explicit user approval to change Sites custom/owner-only audience to public. An async approval question is pending. Do not bypass the rejection. Do not publish activation or distribute table QR codes as working until user approves public server access and real production API/CORS checks pass.
- Table QR capabilities for provisional tables1–12 are in the chat outputs/sunsea-table-links.json. Their SHA256 hashes only are configured as secret TABLE_CAPABILITIES on the server; no service/database secrets in the frontend. These are table access links, not bank payment QR codes. Do not expose one table's link to another table in the menu.
- D1 holds one cart state per table capability. CAS revision updates avoid lost concurrent changes; operation UUIDs are deduplicated within recent512 operations. Every operation includes the visit UUID; stale-visit writes are rejected. Independent common/named checks contain quantities and wishes. Six hours without a mutation expires the visit; explicit End visit confirms clearing all checks on all phones. Clear targets only the selected check, with confirmation.
- Client polls every2seconds while visible, skips unchanged revisions, queues/retries failed mutations in sessionStorage, and keeps active check per table on the device. Offline/pending status is visible; manual waiter view requires saved state. Show waiter includes all checks and Vietnamese dish names, no inbox messages or staff app integration. QR bank payment remains unconfigured and honest.
- Local real-D1 API tests passed five concurrent additions, retry deduplication, separate checks, table isolation, invalid token/item rejection, stale-visit rejection. UI passed five independent Chromium contexts, common/named totals, selected-check clear, offline recovery, reload, four widths, end visit. Normal menu-only regression passes;70 grid/language/group cases pass. Screenshots outputs/sunsea-shared-cart-390.png and sunsea-shared-waiter-390.png. Test script chat work/check_shared_cart.cjs.
- Frontend changes are deliberately not pushed/published yet: the required public backend approval is pending. Existing published ea300ce remains working. Next: get explicit approval, update site access, verify deployed backend anonymously with table tokens and real CORS, rerun shared-cart test against production, reset test tables, commit/push frontend and verify Pages. Never claim cross-phone sync is live while the backend is owner-private.


### Shared cart activation approved — 25 Oct 2026
- User explicitly approved public server access for QR guests. Sites access changed to public successfully; no ChatGPT sign-in is required. This supersedes the preceding pending-approval notes.
- Fresh tests against the deployed D1 API passed concurrent updates from five users, deduplication, check separation, table isolation, token/item validation and ended-visit rejection. Five real Chromium contexts also passed with direct cross-origin browser requests from the exact GitHub Pages origin (real CORS, no API proxy).
- Menu-only UI remains Show the waiter + payment QR; no staff order sending, bill requests or tips. Existing full-mode restore switch remains intact.
- Frontend release now authorized: push prepared ab0481b plus this release note, verify GitHub Pages and real hosted table QR flow. Source site/version IDs are unchanged. Printed QR cards for provisional tables1–12 are chat outputs/sunsea-table-qr.pdf (3 A4 pages, four codes per page), derived from existing capability links. General menu URL remains unchanged; table codes carry their own t/room query parameters.

- 25 Oct: per user request, Sun&Sea generated-photo caption ph2 now says only «Подача в кафе может отличаться.» (equivalent in all5languages). Removed the menu-description illustration wording from the visible dish/lightbox captions. Applied in the Sun&Sea builder only, including full/standalone builds; shared Chez Oanh template unchanged.


### Per-position preferences, preorder display, and waiter-entered prices — 26 Oct 2026
- User requested comments and quick wishes per dish, replacing the ambiguous whole-check wish controls. New menu-only layers item-preferences.js and item-availability.js are injected before shared-cart.js. Full-mode restore switch and original shared engine remain untouched.
- Each basket position has Preferences and an editor (comment up to300characters). Food: not spicy / spicy / very spicy plus no coriander. Drinks: with ice / no ice, no sugar, no milk. Spice levels and ice choices are mutually exclusive; strings and Vietnamese waiter summaries cover all5languages.
- When a position has multiple portions, a checked option applies edits to ONE portion. It becomes a separate line using sid|item|option|UUID. Existing three-part base IDs remain unchanged. Menu counters aggregate base/custom lines, +/- can remove a customized portion when no plain one remains. Names/prices/photos in data.py unchanged.
- Metadata is local in ss_menu_item_notes for ordinary links; QR carts store per-check notes keyed by full position key. Server itemNote operation atomically splits a portion, validates flags, length, and optional entered price, and deduplicates retries. Existing cart rows need no schema migration.
- Both preorder dishes (ss_chef|9 hot smoked fish, ss_chef|10 smoked shrimp) are moved visually to a separate Preorder only group within Chef's specials; still viewable, no cart/preference controls. Positive additions are rejected server-side. Existing preorder cart lines are removed during state normalization / local initialization.
- Unknown-price beer prawns remain addable. A strong amber notice stays with the item in menu/cart/waiter view. Enter price opens a dedicated waiter prompt for the per-portion VND price; editing preserves comment/flags. Metadata price is a whole positive integer up to100000000; totals recalculate and synchronize. Entered price is labeled as entered, not authenticated as restaurant-approved. Original fixed menu prices are never overridden.
- Source backend published commit b8837370eecdcde8000fdbc458ea8bc41eecc914, saved version appgprj_6adca4daa9c08191ad3b1da3a32d99d7~appgver_e3c56f7a56848191a26ba8f787c4d021. Same Site/API and public access preserved.
- Verified real browser local/shared adapters, split-only-one portion, reload, HTML escaping, all5languages, Vietnamese waiter notes, food/drink flag separation and exclusivity, unknown-price entry/recalculation/sync, visible unorderable preorder dishes,4widths.70 menu grid cases and menu-only regression pass. Backend state tests cover isolation, idempotency, invalid metadata/prices, preorder rejection, deletion/clear. Test scripts chat work/check_item_preferences.cjs and backend check-item-notes.cjs. Screenshots chat outputs/sunsea-item-preferences-390.png, sunsea-item-preferences-cart-390.png, sunsea-enter-item-price-390.png.

- 26 Oct: waiter-summary dish names prioritize Vietnamese:22px desktop /20px mobile, bold dark; guest-language counterpart16px /14px muted. Vietnamese-only view keeps the large primary size. Scoped to #waiterView; both local and shared check markup supported. Verified5languages x4widths.

- 26 Oct: bottom cart capsule button uses t.order (RU «Мой заказ») in local and shared table carts. Inside the cart, Show the waiter remains t.showW. Verified all5languages.

Sun&Sea analytics26Oct2026: owner approved Terms; free Metrica counter113805286 (UTC+7), goals674689017 add_to_cart and674689314 waiter_view_opened. menu_only async analytics layer only. Pageviews/actions with amount_vnd, NOT confirmed sales/revenue; different phone opens are not deduplicated orders. No Webvisor/clickmap/link tracking or comments/check names in events. Strip query secrets/hash before SDK, retain table number; tab sessionStorage preserves QR room across sanitized reloads; ordinary root private cart unchanged. Original QR URLs remain valid. See AGENTS.md analytics section. Full restore excludes layer.

27Oct2026: End visit now also exists below payment QR in ordinary standalone carts (finish-visit.js). Confirm clears local selection/preferences; QR table finish remains shared/all-checks. Five languages, cancel/confirm/reload checked; full restore unchanged.

27Oct2026: replaced19 juice/smoothie/yogurt photos with fruit props by printed-menu composition (6+7+6). Built-in generation,9pairs+1single; provenance updated, original IDs/prices unchanged. True alpha, lazy480/detail960;19sources/38WebPs and responsive display verified. See AGENTS.md.

27Oct2026: public banner ?view=preview read-only menu with native booking map/form (17 tables). User deferred contacts and authorized continuing: copy Russian request works, messenger links/Pre-order disabled until contacts supplied. Supersedes earlier pending/no-publish note.10/11/12 each10 seats, room30. Vietnam UTC+7 validation; restaurant confirms booking. Sources table-layout.json,booking-core.js,booking.js/css,public-preview.js/css. Ordinary cart/root/table flows preserved including full-mode restore. A3 QR updated to public-preview URL. See AGENTS.md.

28Oct2026: User removed Pre-order button from public banner menu. Footer now only Book a table; booking contact pending as before. WA/TG prefilled drafts; Zalo copies then opens chat, guest pastes and sends.

28Oct2026 split bills: shared-cart selector is created once; polls update status without replacing focused select/options. Bottom capsule shows active check name/neutral avatars and opens billPicker (choose/add check). Shared cart row supports420ms pointer hold/drop, desktop native drag, plus explicit Move button. Transfer moves whole row and keeps notes/flags/entered price using one idempotent backend move operation (quantity + unique targetKey). Backend Sites v3 commit3e0779e3aad25878c3285b0a8adf5043a61701a9 deployed, same URL/audience and D1 state. Tests run on isolated local fixture, never reset live guest carts. Public preview and full ordering restoration unaffected.

28Oct2026 final user clarification: EXACTLY TWO menu modes. Valid table QR(t+room, or remembered room for t) enables shared ordering and split bills. All ordinary root/banner URLs default to read-only browsing+table booking, with no cart/order. Explicit view=preview always read-only even with a table token. No private/local cart mode. Unpublished local-bill adapter experiment was removed before committing; old private selection storage retained but never activated without QR. Permanent root URL unchanged; table QR links unchanged.

28Oct2026 beer update: existing beer indices0-5 unchanged. User supplied replacement packaging references for Saigon Lager(renamed ru Сайгон зелёное Лагер,25000) and Saigon Special35000. ph/beer_1.png and beer_2.png replaced with reference-based built-in imagegen alpha product cutouts. Appended ss_beer indices6-9: Fresh Lager PET30000(no guessed volume), aluminum Fresh Lager1L70000, Gold1L80000, Black1L90000. Four new ph/beer_fresh_*.png and mapping. Paired sheets split exactly at center, original pixels/alpha retained; metadata beer-image-provenance.json. Backend catalog adds only ss_beer|6..9|0; Sites v4 commit45adc55a2fdc138f937be5d4ce805d7869635f71 deployed same audience/API. Local fixture accepted4 additions and total630000 with pre-existing2x180000; no live guest cart modifications. Compact meat-variants class only for smoked_mash/pasta: label next to price, conversion below; responsive controls remain within grid.183 photos now.

28Oct2026 restaurant booking contacts supplied by user: +84 79 707 44 86. publicContact configured WhatsApp +84797074486, Telegram phone +84797074486, Zalo https://zalo.me/84797074486. Booking links now enabled; WA/TG carry Russian draft, Zalo copies for paste. No messages sent by agent. No Pre-order button, exactly2 modes unchanged.


### 28.10.2026 — немецкий в обоих меню Sun&Sea
- Добавлен шестой язык Deutsch (de), с немецкими названиями всех 183 позиций, 25 разделов, описаниями, вариантами и пометками. Переведены корзина, пожелания, разделение/перенос чеков, завершение визита, QR-оплата, информация и бронирование.
- Переводы каталога: `_src/sunsea/german-catalog.json`, строгая проверка наличия: `german.py`; UI: `german.js` и de в словарях слоёв. В собранной позиции немецкое название находится в индексе 8; цена/фото/extra остаются в 5/6/7. ID заказов и серверный каталог неизменны. Поиск включает немецкое название.
- Deutsch доступен в обычном публичном меню с бронью и в меню QR стола с общей корзиной. Цены при выборе de — VND. Заявка на бронь остаётся на русском согласно решению Марго; в экране официанта вьетнамский остаётся крупным.
- Окно языков поднято над нижней кнопкой бронирования: шестой язык не перекрывается.
- Проверка: `node _src/sunsea/tests_german.cjs`; тесты обоих режимов, селектора чеков, долгого нажатия, бронирования и контактов. Проверены мобильный и компьютерный интерфейсы. Ссылка меню прежняя.
