// Generated from the original ops/tpl.html. Do not edit generated UI.
window.staffFlow=(()=>{const SUNSEA_LAYOUT={"source":"photo_5406799248377978753_y.jpg","width":600,"height":900,"groups":[{"id":"banquet","tables":[10,11,12],"capacity":30,"sourceCapacity":"10–30","needsConfirmation":false}],"tables":[{"id":15,"min":4,"max":10,"x":62,"y":115,"w":165,"h":66},{"id":14,"min":4,"max":10,"x":368,"y":115,"w":165,"h":66},{"id":6,"min":4,"max":4,"x":62,"y":245,"w":90,"h":72},{"id":7,"min":2,"max":2,"x":202,"y":245,"w":62,"h":72},{"id":4,"min":4,"max":4,"x":62,"y":363,"w":90,"h":72},{"id":5,"min":4,"max":4,"x":190,"y":363,"w":86,"h":72},{"id":23,"min":4,"max":4,"x":62,"y":481,"w":90,"h":72},{"id":8,"min":2,"max":2,"x":202,"y":481,"w":62,"h":72},{"id":1,"min":10,"max":15,"x":374,"y":242,"w":158,"h":106,"kind":"booth"},{"id":2,"min":10,"max":15,"x":374,"y":403,"w":158,"h":106,"kind":"booth"},{"id":3,"min":10,"max":15,"x":374,"y":564,"w":158,"h":106,"kind":"booth"},{"id":10,"min":10,"max":10,"x":68,"y":619,"w":168,"h":44,"group":"banquet"},{"id":11,"min":10,"max":10,"x":68,"y":680,"w":168,"h":44,"group":"banquet"},{"id":12,"min":10,"max":10,"x":68,"y":741,"w":168,"h":44,"group":"banquet"},{"id":18,"min":4,"max":6,"x":55,"y":825,"w":119,"h":57},{"id":19,"min":4,"max":4,"x":246,"y":825,"w":90,"h":57},{"id":22,"min":4,"max":4,"x":409,"y":787,"w":90,"h":70}]};const preferences=new Map();let overlay=null;
function renderFlow(el,options){
const {snapshot,cafe}=options,mapped=staffServerState.mapSnapshot(snapshot),M=mapped.menu;let ST=mapped.state;const pref=preferences.get(cafe.id+':'+ST.me)||{};Object.assign(ST,pref);if(options.lang)ST.lang=options.lang;ST.role=options.screen==='prep'?'kitchen':'waiter';ST.split=options.screen==='workbench';ST.ktab=ST.ktab==='stop'?'all':ST.ktab||'all';ST.shift[ST.me]=snapshot.shifts?.[ST.me]||false;
let accept,toKitchen,kReady,kItem,served,closeBill;
const stopMenu=snapshot.menu.filter(i=>['owner','manager','waiter'].includes(snapshot.me.role)||i.station===snapshot.me.role),CMENU=[['menu','Thực đơn','Меню',stopMenu.map(i=>[i.names?.vi||i.names?.ru||'',i.names?.ru||i.names?.vi||''])]];
const MENU=Object.values(M).filter(m=>m.active&&m.p!==null&&!snapshot.menu.find(i=>i.id===m.id)?.stopped),PH={},NEW_LATE_MS=45000,READY_ESC_MS=30000,REORDER_MS=40000;
const WAITERS=()=>ST.staff.filter(x=>x.status==='active'&&(['owner','manager','waiter'].includes(x.role)||x.id===ST.me));
if(!overlay){overlay=document.createElement('div');overlay.className='original-flow flow-overlay';overlay.innerHTML='<section id="flow-sheet" class="sheet" hidden><div class="sheetin" id="flow-sheetIn"></div></section><div id="flow-toasts"></div>';document.body.append(overlay)}
const $=id=>overlay.querySelector('#flow-'+id)||overlay.querySelector('#'+id)||el.querySelector('#'+id);
overlay.querySelector('#flow-sheet').onclick=e=>{if(e.target===e.currentTarget){e.currentTarget.hidden=true}};
const save=()=>preferences.set(cafe.id+':'+ST.me,Object.fromEntries(['lang','wtab','ktab','mineOnly','tview','stopQ'].map(k=>[k,ST[k]]))),render=()=>{save();options.onRender()},toast=(msg,sub)=>options.onNotice(msg+(sub?' · '+sub:''));
const mutate=()=>{throw Error('LOCAL_BUSINESS_MUTATION_FORBIDDEN')},staffBy=id=>ST.staff.find(x=>x.id===id),readyTargets=o=>['owner','manager'].includes(snapshot.me.role)?[ST.me]:[o.waiter],showsForMe=()=>true;
const WISH=[
 {k:"noice",vi:"Không đá",ru:"Без льда",en:"No ice"},{k:"nosugar",vi:"Không đường",ru:"Без сахара",en:"No sugar"},
 {k:"nospicy",vi:"Không cay",ru:"Не остро",en:"Not spicy"},{k:"nocil",vi:"Không rau mùi",ru:"Без кинзы",en:"No coriander"},
 {k:"together",vi:"Ra món cùng lúc",ru:"Подать всё вместе",en:"Serve together"},{k:"kid",vi:"Có trẻ em",ru:"С ребёнком",en:"With a child"}];
const LANGNAME={en:"English",ru:"Русский",vi:"Tiếng Việt",ko:"한국어",zh:"中文"};

/* staff UI strings */
const S={
 vi:{billReq:"Khách gọi thanh toán",billReqS:"Khách muốn thanh toán",pay_cash:"Tiền mặt",pay_card:"Thẻ",pay_qr:"Chuyển khoản QR",openBill:"Mở hóa đơn",sim3:"+ Bàn gọi thanh toán",join:"Nhân viên mới",oStats:"Thống kê",oStaff:"Nhân viên",newReq:"Yêu cầu mới",r_waiter:"Phục vụ",r_kitchen:"Bếp / bar",r_manager:"Quản lý",r_owner:"Chủ quán",qrTitle:"Mã QR kết nối nhân viên",qrHint:"Nhân viên quét mã này để gửi yêu cầu. Mã cũ ngừng hoạt động khi tạo mã mới.",reissue:"Tạo mã mới",reqs:"Yêu cầu chờ duyệt",noReqs:"Không có yêu cầu mới",approveB:"Duyệt",rejectB:"Từ chối",team:"Nhân viên",phone:"Điện thoại",role:"Vai trò",status:"Trạng thái",stBlocked:"Đã khóa",stActive:"Hoạt động",blockB:"Khóa",unblockB:"Mở khóa",deleteB:"Xóa",deleteSure:"Xác nhận xóa?",thisPhone:"máy này",journal:"Nhật ký",noLog:"Chưa có thao tác",blockedMsg:"Tài khoản {w} đã bị chủ quán khóa. Chọn nhân viên khác.",lg_req:"{w} gửi yêu cầu kết nối",lg_ok:"Đã duyệt {w} · {x}",lg_no:"Đã từ chối {w}",lg_block:"Đã khóa {w}",lg_unblock:"Đã mở khóa {w}",lg_del:"Đã xóa {w}",lg_role:"Đổi vai trò {w} → {x}",lg_code:"Tạo mã QR mới {x}",jTitle:"Kết nối với quán",jScanned:"Bạn đã quét mã QR của quán. Nhập thông tin để gửi yêu cầu cho chủ quán.",jName:"Họ tên",jSend:"Gửi yêu cầu",jNote:"Chủ quán sẽ kiểm tra và duyệt. Sau đó máy này tự đăng nhập.",jWait:"Đang chờ chủ quán duyệt",jCancel:"Hủy yêu cầu",jOk:"Đã được duyệt",jOpen:"Mở màn hình làm việc",jBlocked:"Truy cập đã bị khóa",jRejected:"Yêu cầu bị từ chối",jAgain:"Gửi lại",jErr:"Nhập họ tên và số điện thoại",jDemo:"Demo: đây là màn hình trên điện thoại của nhân viên mới.",yourTable:"Bàn của bạn",toAll:"Chuyển cho tất cả",waitFor:"Chờ {w} nhận",reEscT:"{w} chưa nhận, chuyển cho tất cả",tTables:"Bàn",bill:"Hóa đơn",billT:"Hóa đơn bàn",billTotal:"Tổng bàn",addMore:"Gọi thêm",rounds:"lượt",closeBill:"Thanh toán · đóng bàn",closeSure:"Xác nhận đóng bàn?",closed:"Đã đóng bàn",unserved:"Chưa mang ra",noBills:"Không có bàn đang mở",oBills:"Hóa đơn",oOpen:"Bàn đang mở",dark:"Tối",light:"Sáng",sub:"Demo vận hành · menu QR",guest:"Khách",waiter:"Phục vụ",kitchen:"Bếp",owner:"Chủ quán",split:"Xem cùng lúc",single:"Một màn hình",
  soundOn:"Âm thanh: bật",soundOff:"Âm thanh: tắt",demo:"Demo:",sim:"+ Bàn mới gọi món (QR)",sim2:"+ Bàn gọi thêm (QR)",reset:"Làm lại",hint:"Dữ liệu chỉ lưu trên trình duyệt này. Mở thêm tab để thử nhiều vai trò.",
  me:"Tôi là",onShift:"Đang trong ca",offShift:"Ngoài ca",startShift:"Vào ca",endShift:"Kết ca",offNote:"Bạn đang ngoài ca: không nhận thông báo đơn mới.",
  tNew:"Đơn mới",tMine:"Của tôi",tReady:"Sẵn sàng",tAll:"Tất cả",tDone:"Đã mang ra",accept:"Nhận đơn",edit:"Sửa đơn",toKitchen:"Chuyển bếp",served:"Đã mang ra",more:"Gọi thêm",
  table:"Bàn",min:"ph",sec:"giây",ago:"trước",sNew:"Mới",sAccepted:"Đã nhận",sCooking:"Đang nấu",sReady:"Sẵn sàng",sServed:"Đã phục vụ",late:"Chưa ai nhận",
  by:"Phục vụ",guestLang:"Khách nói",none:"Không có đơn",readyAlert:"Món đã xong, mang ra bàn",readyAll:"Không ai mang ra: báo cho tất cả",newAlert:"Đơn mới",
  editT:"Đơn bàn",addItem:"Thêm món",comment:"Ghi chú cho bếp",commentPh:"Ví dụ: khách dị ứng đậu phộng, làm món chay trước…",notePh:"Ghi chú món (ít cay, không hành…)",
  wishes:"Yêu cầu của khách",save:"Lưu",saveSend:"Lưu và chuyển bếp",cancel:"Đóng",remove:"Xóa",total:"Tổng",manual:"+ Ghi đơn tại bàn",manualT:"Đơn mới tại bàn",pickTable:"Bàn số",create:"Tạo đơn",
  kAll:"Tất cả",kKitchen:"Bếp",kBar:"Quầy bar",kTitle:"Màn hình bếp",kDone:"Xong · báo phục vụ",kNone:"Bếp đang trống",kTap:"Chạm vào món để đánh dấu đã làm xong",kReady:"Chờ mang ra",kNew:"Đơn mới vào bếp",
  bar:"bar",kit:"bếp",
  oToday:"Hôm nay",oRev:"Doanh thu",oOrders:"Đơn",oAvg:"Trung bình / đơn",oAccept:"Nhận đơn",oCook:"Bếp làm",oWaiters:"Nhân viên",oName:"Tên",oShift:"Ca",oOrd:"Đơn",oRevS:"Doanh thu",oAvgS:"TB/đơn",oAcc:"TB nhận",oLate:"Trễ",
  oTop:"Món bán chạy",oLang:"Khách theo ngôn ngữ",oHours:"Doanh thu theo giờ",oSettings:"Cài đặt thông báo",oSeed:"Dữ liệu mẫu cho demo + các đơn bạn tạo.",
  nTaker:"Chỉ người nhận đơn",nAll:"Tất cả nhân viên trong ca",nEsc:"Người nhận đơn, sau 30 giây chưa mang ra thì báo tất cả",nTakerD:"Ít thông báo nhất.",nAllD:"Nhanh nhất, nhưng mọi người đều bị làm phiền.",nEscD:"Khuyên dùng.",
  oLive:"Đang hoạt động",oNow:"Đơn đang mở",yes:"có",no:"không"},
 ru:{billReq:"Просит счёт",billReqS:"Гость просит рассчитать",pay_cash:"Наличные",pay_card:"Карта",pay_qr:"Перевод по QR",openBill:"Открыть счёт",sim3:"+ Стол просит счёт",join:"Новый сотрудник",oStats:"Аналитика",oStaff:"Сотрудники",newReq:"Новая заявка",r_waiter:"Официант",r_kitchen:"Повар / бар",r_manager:"Управляющий",r_owner:"Владелец",qrTitle:"QR для подключения сотрудников",qrHint:"Сотрудник сканирует код и отправляет заявку. После перевыпуска старый код перестаёт работать.",reissue:"Перевыпустить код",reqs:"Заявки на доступ",noReqs:"Новых заявок нет",approveB:"Подтвердить",rejectB:"Отклонить",team:"Команда",phone:"Телефон",role:"Роль",status:"Статус",stBlocked:"Заблокирован",stActive:"Активен",blockB:"Заблокировать",unblockB:"Разблокировать",deleteB:"Удалить",deleteSure:"Точно удалить?",thisPhone:"этот телефон",journal:"Журнал действий",noLog:"Пока пусто",blockedMsg:"Доступ {w} заблокирован руководителем. Выберите другого сотрудника.",lg_req:"{w} отправил(а) заявку",lg_ok:"Подтверждён(а) {w} · {x}",lg_no:"Отклонена заявка {w}",lg_block:"Заблокирован(а) {w}",lg_unblock:"Разблокирован(а) {w}",lg_del:"Удалён(а) {w}",lg_role:"Роль {w} → {x}",lg_code:"Перевыпущен код {x}",jTitle:"Подключение к кафе",jScanned:"Вы отсканировали QR кафе. Заполните данные, заявка уйдёт руководителю.",jName:"Имя",jSend:"Отправить заявку",jNote:"Руководитель проверит и подтвердит. Дальше этот телефон входит сам.",jWait:"Ожидает подтверждения руководителя",jCancel:"Отменить заявку",jOk:"Доступ подтверждён",jOpen:"Открыть рабочий экран",jBlocked:"Доступ закрыт руководителем",jRejected:"Заявка отклонена",jAgain:"Подать заново",jErr:"Введите имя и телефон",jDemo:"Демо: так выглядит экран на телефоне нового сотрудника.",yourTable:"Ваш стол",toAll:"Передан всем",waitFor:"Ждёт {w}",reEscT:"{w} не принял — передано всем",tTables:"Столы",bill:"Счёт",billT:"Счёт, стол",billTotal:"Итого по столу",addMore:"Дозаказ",rounds:"заказ(а)",closeBill:"Оплачено · закрыть стол",closeSure:"Точно закрыть счёт?",closed:"Стол закрыт",unserved:"Ещё не вынесено",noBills:"Нет открытых столов",oBills:"Чеки",oOpen:"Открыто столов",dark:"Тёмная",light:"Светлая",sub:"Демо процесса · QR-меню",guest:"Гость",waiter:"Официант",kitchen:"Кухня",owner:"Владелец",split:"Все экраны",single:"Один экран",
  soundOn:"Звук: вкл",soundOff:"Звук: выкл",demo:"Демо:",sim:"+ Новый стол заказал по QR",sim2:"+ Стол дозаказал по QR",reset:"Сбросить",hint:"Данные хранятся только в этом браузере. Откройте ещё вкладку, чтобы играть разные роли.",
  me:"Я",onShift:"На смене",offShift:"Не на смене",startShift:"Начать смену",endShift:"Закончить смену",offNote:"Вы не на смене: уведомления о новых заказах не приходят.",
  tNew:"Новые",tMine:"Мои",tReady:"Готово",tAll:"Все",tDone:"Вынесено",accept:"Принять",edit:"Изменить",toKitchen:"Отдать в работу",served:"Вынес",more:"Дозаказ",
  table:"Стол",min:"мин",sec:"сек",ago:"назад",sNew:"Новый",sAccepted:"Принят",sCooking:"Готовится",sReady:"Готов",sServed:"Подан",late:"Никто не принял",
  by:"Официант",guestLang:"Язык гостя",none:"Заказов нет",readyAlert:"Заказ готов, несите к столу",readyAll:"Никто не забрал: сообщили всем",newAlert:"Новый заказ",
  editT:"Заказ, стол",addItem:"Добавить блюдо",comment:"Комментарий для кухни",commentPh:"Например: у гостя аллергия на арахис, сначала вегетарианское…",notePh:"Комментарий к блюду (менее остро, без лука…)",
  wishes:"Пожелания гостя",save:"Сохранить",saveSend:"Сохранить и отдать в работу",cancel:"Закрыть",remove:"Убрать",total:"Итого",manual:"+ Записать заказ устно",manualT:"Новый заказ у стола",pickTable:"Стол",create:"Создать",
  kAll:"Всё",kKitchen:"Кухня",kBar:"Бар",kTitle:"Экран кухни",kDone:"Готово · позвать официанта",kNone:"На кухне пусто",kTap:"Нажмите на блюдо, чтобы отметить его готовым",kReady:"Ждут официанта",kNew:"Новый заказ на кухне",
  bar:"бар",kit:"кухня",
  oToday:"Сегодня",oRev:"Выручка",oOrders:"Заказы",oAvg:"Средний чек",oAccept:"Принятие",oCook:"Готовка",oWaiters:"Официанты",oName:"Имя",oShift:"Смена",oOrd:"Заказы",oRevS:"Выручка",oAvgS:"Ср. чек",oAcc:"Ср. принятие",oLate:"Опоздания",
  oTop:"Топ блюд",oLang:"Гости по языкам",oHours:"Выручка по часам",oSettings:"Кому сообщать о готовом заказе",oSeed:"Примерные данные для демо + ваши заказы.",
  nTaker:"Только официанту, который принял",nAll:"Всем на смене",nEsc:"Сначала тому, кто принял; через 30 сек всем",nTakerD:"Меньше всего уведомлений.",nAllD:"Быстрее, но дёргает всех.",nEscD:"Рекомендуем.",
  oLive:"Сейчас",oNow:"Открытых заказов",yes:"да",no:"нет"}
};
Object.assign(S.vi,{cafeT:"Quán của bạn",cafeH:"Chủ quán đăng nhập vào quán của mình: mỗi quán chỉ thấy đơn, thực đơn, danh sách hết món, nhân viên và thống kê của mình. Trong demo có thể chuyển giữa các quán.",cafeNow:"Đang mở",cafeGo:"Đăng nhập vào quán này",fabT:"Ghi đơn",tPaid:"Đã thanh toán",tvMap:"Sơ đồ",tvList:"Danh sách",zHall:"Trong nhà",zTerr:"Sân hiên",hs_free:"trống",hs_new:"đơn mới",hs_cook:"đang làm",hs_ready:"xong, mang ra",hs_bill:"gọi thanh toán",hs_eat:"có khách",swHint:"Vuốt phải để thực hiện",kSentW:"Đã báo cho {w}: món đã xong",noToday:"Ở Việt Nam bây giờ là {h}, hôm nay chưa có đơn đã phục vụ.",pToday:"Hôm nay",pYest:"Hôm qua",p7:"7 ngày",p30:"30 ngày",p90:"90 ngày",pCustom:"Tùy chọn",pFrom:"Từ",pTo:"Đến",vsPrev:"so với kỳ trước",oByDay:"Doanh thu theo ngày",csv:"Tải CSV (Excel)",csvDate:"Ngày",histNote:"Demo: hôm nay là đơn thật trong trình duyệt này, các ngày trước là dữ liệu mẫu.",payHow:"Khách đã thanh toán bằng",pickPay:"Chọn cách khách đã thanh toán",oPay:"Hình thức thanh toán",pay_mix:"Kết hợp",payNone:"chưa ghi",billOpenP:"Chưa thanh toán",paidP:"Đã thanh toán",revT:"Đánh giá của khách",revH:"Sau khi thanh toán, khách thấy lời mời đánh giá và nút mở trang của quán. Dán đường dẫn trang quán trên Google Maps và Tripadvisor.",revG:"Google Maps",revTa:"Tripadvisor",revSave:"Lưu",revOk:"Đã lưu đường dẫn",revBad:"Đường dẫn phải bắt đầu bằng https://",revMiss:"Chưa có đường dẫn đánh giá",kStop:"Hết món",stopT:"Món đã hết",stopH:"Đánh dấu món đã hết: khách thấy “Hết món” trong thực đơn và không thể gọi. Khi có lại, bấm “Có lại”.",stopNone:"Tất cả món đều còn",stopOut:"Hết món",stopBack:"Có lại",stopQ:"Tìm món…",stopAll:"Tất cả món",stopOk:"Đã báo hết món",stopRet:"Món đã có lại",ckCommon:"chung",payQrT:"Mã QR nhận thanh toán",payQrH:"Khách quét mã này trong thực đơn để chuyển khoản vào tài khoản của bạn. Không cần kết nối ngân hàng hay máy POS.",payQrNo:"Chưa có mã QR",upQr:"Tải ảnh mã QR",repQr:"Thay ảnh",delQr:"Xóa",payQrMiss:"Chưa tải mã QR thanh toán: khách chưa thể chuyển khoản. Vào Nhân viên → Mã QR nhận thanh toán.",tipQr:"QR tiền tip",tipQrT:"Mã QR nhận tip của bạn",tipQrH:"Khách bàn bạn phục vụ có thể quét mã này để gửi tip trực tiếp vào tài khoản của bạn. Lấy mã QR trong ứng dụng ngân hàng.",tipMiss:"Bạn chưa tải mã QR nhận tip, khách không thể gửi tip qua QR.",jTip:"Mã QR nhận tip (từ ứng dụng ngân hàng)",jTipOpt:"Có thể thêm sau",check:"Hóa đơn",paidQr:"Khách báo đã chuyển khoản QR, hãy kiểm tra",allChecks:"tất cả",qrOk:"Đã lưu mã QR",imgErr:"Không đọc được ảnh"});
Object.assign(S.ru,{cafeT:"Ваше заведение",cafeH:"Владелец входит в своё заведение и видит только его: заказы, меню и стоп-лист, сотрудников, QR оплаты, отзывы и аналитику. В демо между заведениями можно переключаться.",cafeNow:"Сейчас открыто",cafeGo:"Войти в это заведение",fabT:"Устный заказ",tPaid:"Завершённые",tvMap:"Карта зала",tvList:"Список",zHall:"Зал",zTerr:"Терраса",hs_free:"свободен",hs_new:"новый заказ",hs_cook:"готовится",hs_ready:"готово, нести",hs_bill:"просит счёт",hs_eat:"занят",swHint:"Смахните вправо",kSentW:"Официант {w} получил уведомление: заказ готов",noToday:"Во Вьетнаме сейчас {h}, сегодня ещё нет вынесенных заказов.",pToday:"Сегодня",pYest:"Вчера",p7:"7 дней",p30:"30 дней",p90:"90 дней",pCustom:"Свой период",pFrom:"С",pTo:"по",vsPrev:"к прошлому периоду",oByDay:"Выручка по дням",csv:"Скачать для Excel",csvDate:"Дата",histNote:"Демо: сегодня — настоящие заказы в этом браузере, прошлые дни — примерные данные для показа.",payHow:"Как оплатили",pickPay:"Отметьте, как оплатили",oPay:"Способы оплаты",pay_mix:"Смешанная",payNone:"не отмечено",billOpenP:"Счёт открыт",paidP:"Оплачено",revT:"Отзывы гостей",revH:"После оплаты гость увидит просьбу оставить отзыв и кнопки, которые откроют страницу кафе. Вставьте ссылки на страницу кафе в Google Картах и Tripadvisor.",revG:"Google Карты",revTa:"Tripadvisor",revSave:"Сохранить",revOk:"Ссылки сохранены",revBad:"Ссылка должна начинаться с https://",revMiss:"Ссылки на отзывы не добавлены",kStop:"Стоп-лист",stopT:"Закончилось",stopH:"Отметьте, что закончилось: гость сразу видит «Закончилось» в меню и не может это заказать. Когда снова есть — «Вернуть».",stopNone:"Всё в наличии",stopOut:"Закончилось",stopBack:"Вернуть",stopQ:"Найти блюдо…",stopAll:"Всё меню",stopOk:"Снято из меню",stopRet:"Снова в меню",ckCommon:"общее",payQrT:"QR для оплаты гостями",payQrH:"Гость видит этот QR в меню и переводит деньги на ваш счёт или карту. Банк и касса не подключаются.",payQrNo:"QR не загружен",upQr:"Загрузить фото QR",repQr:"Заменить",delQr:"Удалить",payQrMiss:"Не загружен QR для оплаты: гости не смогут заплатить переводом. Сотрудники → QR для оплаты гостями.",tipQr:"QR для чаевых",tipQrT:"Ваш QR для чаевых",tipQrH:"Гости ваших столов смогут отсканировать его и перевести чаевые прямо вам. QR берётся в приложении вашего банка.",tipMiss:"Вы не загрузили QR для чаевых: гости не смогут оставить их переводом.",jTip:"QR для чаевых (из приложения банка)",jTipOpt:"Можно добавить позже",check:"Чек",paidQr:"Гость отметил перевод по QR — проверьте",allChecks:"все",qrOk:"QR сохранён",imgErr:"Не удалось прочитать фото"});
/* guest UI strings */
const esc=s=>String(s??"").replace(/[&<>"]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]));
const t=k=>S[ST.lang][k];
const vnd=v=>Math.round(v).toLocaleString("vi-VN")+" ₫";
const short=v=>v>=1e6?(v/1e6).toLocaleString("vi-VN",{maximumFractionDigits:1})+(ST&&ST.lang==="ru"?" млн":" tr"):Math.round(v/1000)+"k";
const tot=o=>o.items.reduce((s,i)=>s+M[i.mid].p*i.qty,0);
const nm=(mid,l)=>M[mid][l]||M[mid].vi;
const wname=id=>((ST&&ST.staff||[]).find(w=>w.id===id)||{name:"—"}).name;
function since(ts){const s=Math.max(0,Math.floor((Date.now()-ts)/1000));return s<60?s+" "+t("sec"):Math.floor(s/60)+" "+t("min")+" "+String(s%60).padStart(2,"0")}
function mmss(ts){const s=Math.max(0,Math.floor((Date.now()-ts)/1000));return Math.floor(s/60)+":"+String(s%60).padStart(2,"0")}
const live=()=>ST.orders.filter(o=>!o.seed);
const stLabel=s=>({new:t("sNew"),accepted:t("sAccepted"),cooking:t("sCooking"),ready:t("sReady"),served:t("sServed")})[s];
function reqTxt(r){return t("pay_"+r.pay)+(r.check?" · "+t("check")+" "+r.check:"")+(r.paid?" · "+t("paidQr"):"")}
function openBill(table){return Object.values(ST.bills).find(b=>!b.closed&&b.table===table)}
function forMe(o){if(o.status!=="new"||!o.owner)return true;return o.owner===ST.me||!ST.shift[o.owner]||!!o.reEsc}
function billOrders(bid){return ST.orders.filter(o=>o.bill===bid)}
function billTotal(bid){return billOrders(bid).reduce((s,o)=>s+tot(o),0)}
function serveActions(o){return ["kitchen","bar"].filter(scope=>stationReady(o,scope)&&!o.stationServedAt?.[scope]).map(scope=>`<button class="btn green sm" type="button" data-a="served" data-id="${o.id}" data-scope="${scope}">${esc(t(scope==="bar"?"kBar":"kKitchen"))} · ${esc(t("served"))}</button>`).join("")}
function pendingServe(o,scope){return stationReady(o,scope)&&!o.stationServedAt?.[scope]}
function stationItems(o,scope){return o.items.filter(i=>scope==="all"||(M[i.mid]?.st==="b"?"bar":"kitchen")===scope)}
function stationReady(o,scope){const items=stationItems(o,scope);return items.length>0&&items.every(i=>i.done)}
function syncPrep(o){const now=Date.now();o.stationReadyAt=o.stationReadyAt||{};for(const scope of ["bar","kitchen"]){if(stationReady(o,scope)){if(!o.stationReadyAt[scope])o.stationReadyAt[scope]=now}else delete o.stationReadyAt[scope]}if(stationReady(o,"all")){o.status="ready";o.readyAt=now}}
function prepSummary(o){if(!["cooking","ready"].includes(o.status))return "";return `<div class="prep-status">${["kitchen","bar"].filter(scope=>stationItems(o,scope).length).map(scope=>`<span class="pill ${o.stationServedAt?.[scope]?"st-served":stationReady(o,scope)?"st-ready":"st-cooking"}">${esc(t(scope==="bar"?"kBar":"kKitchen"))}: ${esc(t(o.stationServedAt?.[scope]?"served":stationReady(o,scope)?"sReady":"sCooking"))}</span>`).join("")}</div>`}
function readyBanner(o){const full=o.status==="ready",label=full?t("readyAlert"):["kitchen","bar"].filter(scope=>stationReady(o,scope)).map(scope=>t(scope==="bar"?"kBar":"kKitchen")+": "+t("sReady")).join(" · ");return `<div class="alert"><span>✓ ${esc(label)} · <b>${esc(t("table"))} ${esc(o.table)}</b> #${o.no}${o.waiter!==ST.me?` (${esc(wname(o.waiter))})`:""}</span><span class="sp"></span>${serveActions(o)}</div>`}
function orderLines(o,opts={}){const l=opts.lang||ST.lang;return `<ul class="lines">`+o.items.map(i=>`<li><span class="q">${i.qty}×</span><span class="n"><b>${esc(nm(i.mid,"vi"))}</b>${i.added?`<span class="badge-new">+</span>`:""}${ST.lang==="ru"?`<span class="tr">${esc(nm(i.mid,"ru"))}</span>`:o.lang!=="vi"?`<span class="tr">${esc(nm(i.mid,"en"))}</span>`:""}${i.note?`<span class="note">${esc(i.note)}</span>`:""}</span><span class="p">${vnd(M[i.mid].p*i.qty)}</span></li>`).join("")+`</ul>`+prepSummary(o)}
function wishHTML(o,l){return o.wishes&&o.wishes.length?`<div class="wish">${o.wishes.map(k=>{const w=WISH.find(x=>x.k===k);return w?`<span>${esc(w[l])}</span>`:""}).join("")}</div>`:""}
function stepsHTML(o){const idx={new:0,accepted:1,cooking:2,ready:3,served:4}[o.status];return `<div class="steps">${[0,1,2,3,4].map(i=>`<i class="${i<=idx?"on":""}"></i>`).join("")}</div>`}

/* --- guest --- */
function oCard(o,mode){const l=ST.lang;const mineO=o.waiter===ST.me||['owner','manager'].includes(snapshot.me.role);
  let actions="";
  const ownPill=o.status==="new"&&o.owner?(o.owner===ST.me?`<span class="pill own">${esc(t("yourTable"))}</span>`:o.reEsc?`<span class="pill st-late">${esc(t("toAll"))}</span>`:`<span class="pill">${esc(wname(o.owner))}</span>`):"";
  if(o.status==="new")actions=forMe(o)?`<button class="btn sm" type="button" data-a="accept" data-id="${o.id}" ${ST.shift[ST.me]?"":"disabled"}>${esc(t("accept"))}</button>`:`<span class="wait">${esc(t("waitFor").replace("{w}",wname(o.owner)))} · <span data-left="${o.createdAt+REORDER_MS}">0:40</span></span>`;
  else if(o.status==="accepted"&&mineO)actions=`<button class="btn ghost sm" type="button" data-a="edit" data-id="${o.id}">${esc(t("edit"))}</button><button class="btn sm" type="button" data-a="kitchen" data-id="${o.id}">${esc(t("toKitchen"))}</button>`;
  else if(["cooking","ready"].includes(o.status))actions=serveActions(o);
  /* served is not paid: the table's bill stays open for re-orders until the waiter takes the money and closes it */
  const bOpen=o.bill&&ST.bills[o.bill]&&!ST.bills[o.bill].closed;
  if(o.status==="served"&&bOpen)actions=`<button class="btn ghost sm" type="button" data-a="more" data-id="${o.id}">+ ${esc(t("addMore"))}</button><button class="btn sm" type="button" data-a="bill" data-id="${o.bill}">${esc(t("bill"))}</button>`;
  if(["cooking","ready"].includes(o.status)&&o.bill&&ST.bills[o.bill]&&!ST.bills[o.bill].closed)actions=`<button class="btn ghost sm" type="button" data-a="bill" data-id="${o.bill}">${esc(t("bill"))}</button>`+actions;
  const lateAttr=o.status==="new"?`data-late="${o.createdAt}"`:"";
  const timeRef=(o.status==="new"?o.createdAt:o.status==="accepted"?o.acceptedAt:o.status==="cooking"?o.sentAt:o.status==="ready"?o.readyAt:o.servedAt)||o.createdAt;
  const bOpen2=o.bill&&ST.bills[o.bill]&&!ST.bills[o.bill].closed;const B=o.bill&&ST.bills[o.bill];
  const extra=[o.round>1?t("addMore")+" · "+o.round:"",o.check?t("check")+": "+o.check:""].filter(Boolean).join(" · ");
  const paid=o.status==="served"?(bOpen2?`<span class="pill st-late">${esc(t("billOpenP"))}</span>`:`<span class="pill st-ready">${esc(t("paidP"))}${B&&B.pay?" · "+esc(t("pay_"+B.pay)):""}</span>`):"";
  const live2=o.status!=="served";
  return `<article style="--tc:var(--t${(((+o.table||1)-1)%8+8)%8+1});--tc-ink:var(--t${(((+o.table||1)-1)%8+8)%8+1}-ink)" class="oc v2 s-${o.status}${["bar","kitchen"].some(scope=>pendingServe(o,scope))?" has-ready":""}${forMe(o)?"":" other"}${o.status==="new"&&Date.now()-o.createdAt>NEW_LATE_MS?" late":""}" ${lateAttr}>
    <div class="side"><small>${esc(t("table"))}</small><b>${esc(o.table)}</b>${live2?`<em data-mmss="${timeRef}">${mmss(timeRef)}</em>`:`<em>✓</em>`}</div>
    <div class="main">
    <div class="st"><i></i><span class="sl">${esc(stLabel(o.status))}${extra?` <span class="ex">· ${esc(extra)}</span>`:""}</span>${ownPill}${o.status==="new"?`<span class="pill st-late latepill" ${Date.now()-o.createdAt>NEW_LATE_MS?"":"hidden"}>${esc(t("late"))}</span>`:""}${o.escalated&&o.status==="ready"?`<span class="pill st-late">${esc(t("tAll"))}</span>`:""}${paid}<span class="wn">${o.waiter?esc(wname(o.waiter)):""}</span></div>
    ${orderLines(o)}${wishHTML(o,l)}${o.comment?`<div class="cmt">${esc(o.comment)}</div>`:""}
    <div class="of"><span class="tot">${vnd(tot(o))}</span>${actions}</div>
    <div class="more">${esc(LANGNAME[o.lang]||o.lang)} · #${o.no}${o.src==="waiter"?" · ✎":""}${o.bill&&bOpen2&&billOrders(o.bill).length>1?` · ${esc(t("billTotal"))}: <b>${vnd(billTotal(o.bill))}</b>`:""} · <span data-since="${timeRef}">${since(timeRef)}</span></div>
    </div></article>`}
function rWaiter(el){const meS=staffBy(ST.me);if(!meS||meS.status!=="active"){const alt=WAITERS()[0];if(alt&&(!meS||meS.status==="deleted")){ST.me=alt.id}else{el.innerHTML=`<div class="alert red"><span>${esc(t("blockedMsg").replace("{w}",meS?meS.name:""))}</span></div><div class="who"><label for="meSel" class="muted">${esc(t("me"))}</label><select id="meSel"><option></option>${WAITERS().map(w=>`<option value="${w.id}">${esc(w.name)}</option>`).join("")}</select></div>`;el.querySelector("#meSel").onchange=e=>{if(e.target.value){ST.me=e.target.value;save();render()}};return}}
  const on=ST.shift[ST.me];const L=live();
  const myReady=L.filter(o=>(o.status==="ready"||(o.status==="cooking"&&["bar","kitchen"].some(scope=>pendingServe(o,scope))))&&readyTargets(o).includes(ST.me));
  const groups=[["new",ST.lang==="ru"?"Новые":"Mới",L.filter(o=>o.status==="new")],["cooking",ST.lang==="ru"?"Готовятся":"Đang làm",L.filter(o=>["accepted","cooking"].includes(o.status)&&!["bar","kitchen"].some(scope=>pendingServe(o,scope)))],["ready",ST.lang==="ru"?"Можно выносить":"Có thể phục vụ",L.filter(o=>["cooking","ready"].includes(o.status)&&["bar","kitchen"].some(scope=>pendingServe(o,scope)))]];
  const bills=Object.values(ST.bills).filter(b=>!b.closed&&billOrders(b.id).some(o=>!o.seed));
  const tabs=[["all",ST.lang==="ru"?"Все":"Tất cả",groups.flatMap(g=>g[2])],...groups,["tables",t("tTables"),bills],["closed",ST.lang==="ru"?"Закрытые · 24 часа":"Đã đóng · 24 giờ",L.filter(o=>o.status==="served"&&o.bill&&ST.bills[o.bill]?.closedAt>Date.now()-86400000).sort((a,b)=>ST.bills[b.bill].closedAt-ST.bills[a.bill].closedAt)]];
  const cur=tabs.find(x=>x[0]===ST.wtab)||tabs[0];
  const cards=rows=>{const shown=ST.mineOnly?rows.filter(o=>o.waiter===ST.me||o.owner===ST.me):rows;return shown.length?`<div class="flow-grid">${shown.map(o=>`<div class="swp">${oCard(o)}</div>`).join("")}</div>`:`<div class="empty">${esc(t("none"))}</div>`};
    const tablesBody=()=>hallMap();
  el.innerHTML=`<div class="who"><label for="meSel" class="muted">${esc(t("me"))}</label><select id="meSel">${WAITERS().map(w=>`<option value="${w.id}" ${w.id===ST.me?"selected":""}>${esc(w.name)}${ST.shift[w.id]?" ●":""}</option>`).join("")}</select><button type="button" class="btn sm ${meS.tipQr?"ghost":"tipneed"}" id="tipQrBtn" title="${meS.tipQr?"":esc(t("tipMiss"))}">${esc(t("tipQr"))}${meS.tipQr?" ✓":""}</button><span class="sp"></span><button type="button" class="shift ${on?"on":"off"}" id="shiftBtn">${on?"● "+esc(t("onShift"))+" · "+esc(t("endShift")):esc(t("startShift"))}</button></div>

   ${on&&myReady.length?myReady.map(readyBanner).join(""):""}
   ${Object.values(ST.bills).filter(b=>!b.closed&&b.req).sort((a,b)=>a.req.at-b.req.at).map(b=>`<div class="reqbar"><b>${esc(t("table"))} ${esc(b.table)} · ${esc(t("billReq"))}</b><span>${esc(reqTxt(b.req))} · ${vnd(billTotal(b.id))}</span><button class="btn green sm" type="button" data-a="bill" data-id="${b.id}">${esc(t("openBill"))}</button></div>`).join("")}<div class="row"><div class="tabs">${tabs.map(([k,lab,arr])=>`<button type="button" data-wt="${k}" class="${k===cur[0]?"on":""} ${["new","ready"].includes(k)&&arr.length?"needs-action":""}">${esc(lab)} <span class="${k==='ready'&&arr.length?'ready-badge':''}">${arr.length}</span></button>`).join("")}</div></div><button class="fab" type="button" id="manualBtn" ${on?"":"disabled"} aria-label="${esc(t("manual"))}" title="${esc(t("manual"))}"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg><span>${esc(t("fabT"))}</span></button>
   <div class="waiter-secondary"><button type="button" id="mineFilter" aria-pressed="${!!ST.mineOnly}">${ST.lang==="ru"?"Только мои":"Của tôi"}${ST.mineOnly?" ✓":""}</button></div>
   ${cur[0]==="tables"?tablesBody():cur[0]==="all"?groups.map(([id,n,rows])=>`<section class="flow-section" data-flow="${id}" data-count="${rows.length}"><h3>${esc(n)} <span class="${id==='ready'&&rows.length?'ready-badge':''}">${rows.length}</span></h3>${cards(rows)}</section>`).join(""):cards(cur[2])}`;
  el.querySelector("#mineFilter").onclick=()=>{ST.mineOnly=!ST.mineOnly;save();render()};
  el.querySelectorAll("[data-tv]").forEach(b=>b.onclick=()=>{ST.tview=b.dataset.tv;save();render()});
  el.querySelectorAll("[data-ht]").forEach(b=>b.onclick=()=>{const n=+b.dataset.ht,bl=openBill(n);if(bl)openBillSheet(bl.id);else if(ST.shift[ST.me])openEditor(null,{table:n,lang:"vi",no:null});else toast(t("offNote"),"","r")});
  swipeCards(el);
  el.querySelector("#meSel").onchange=e=>{ST.me=e.target.value;save();render()};
  el.querySelector("#tipQrBtn").onclick=openTipQr;
  el.querySelector("#shiftBtn").onclick=()=>mutate(()=>{ST.shift[ST.me]=!ST.shift[ST.me]});
  el.querySelectorAll("[data-wt]").forEach(b=>b.onclick=()=>{ST.wtab=b.dataset.wt;save();render()});
  el.querySelector("#manualBtn").onclick=()=>openEditor(null);
  bindActions(el);
}
function swipeCards(el){el.querySelectorAll(".swp").forEach(w=>{const c=w.querySelector(".oc");const btn=[...c.querySelectorAll(".of .btn:not(.ghost)")].pop();
  if(!btn||btn.disabled)return;w.dataset.lbl="✓ "+btn.textContent.trim();w.classList.add("can");let x0=null,y0=0,dx=0,lock=null;
  c.addEventListener("pointerdown",e=>{if(e.target.closest("button,select,input"))return;x0=e.clientX;y0=e.clientY;dx=0;lock=null});
  c.addEventListener("pointermove",e=>{if(x0===null)return;const mx=e.clientX-x0,my=e.clientY-y0;if(lock===null&&(Math.abs(mx)>8||Math.abs(my)>8))lock=Math.abs(mx)>Math.abs(my)?"x":"y";
    if(lock!=="x")return;dx=Math.max(0,mx);c.classList.add("drag");c.style.transform=`translateX(${dx}px)`;w.style.setProperty("--sw",Math.min(1,dx/110));try{c.setPointerCapture(e.pointerId)}catch(_){}});
  const end=()=>{if(x0===null)return;x0=null;c.classList.remove("drag");if(lock==="x"&&dx>110){c.style.transform="translateX(110%)";try{navigator.vibrate&&navigator.vibrate(12)}catch(_){}setTimeout(()=>btn.click(),180)}else{c.style.transform="";w.style.setProperty("--sw",0)}};
  c.addEventListener("pointerup",end);c.addEventListener("pointercancel",end)})}
function bindActions(el){el.querySelectorAll("[data-a]").forEach(b=>b.onclick=()=>{const id=b.dataset.id,a=b.dataset.a;
  if(a==="accept"){accept(id);ST.wtab="cooking";save();render()}
  else if(a==="edit")openEditor(id);
  else if(a==="kitchen")toKitchen(id);
  else if(a==="served")served(id,b.dataset.scope||"all");
  else if(a==="more")openEditor(null,ST.orders.find(o=>o.id===id))
  else if(a==="bill")openBillSheet(id)
  else if(a==="moreB"){const os=billOrders(id);openEditor(null,os[os.length-1])}})}
/* the room at a glance: every table, coloured by what needs doing there */
const HALL=[1,2,3,4,5,6,7,8],TERR=[9,10,11,12];
function tState(n){const b=openBill(n);if(!b)return ["free",null];const os=billOrders(b.id);
  if(b.req)return ["bill",b];if(os.some(o=>o.status==="ready"))return ["ready",b];if(os.some(o=>o.status==="new"))return ["new",b];
  if(os.some(o=>o.status==="accepted"||o.status==="cooking"))return ["cook",b];return ["eat",b]}
function hallMap(){const extra=Object.values(ST.bills).filter(b=>!b.closed&&b.table>12).map(b=>b.table);const terr=[...TERR,...new Set(extra)].sort((a,b)=>a-b);
  const cell=n=>{const [st,b]=tState(n);const sum=b?billTotal(b.id):0;const w=b?[...billOrders(b.id)].reverse().find(o=>o.waiter)?.waiter:"";
    return `<button type="button" class="ht ${st}${n%4===3||n%4===0?" sq":""}" data-ht="${n}" style="--tc:var(--t${((n-1)%8+8)%8+1});--tc-ink:var(--t${((n-1)%8+8)%8+1}-ink)" aria-label="${esc(t("table"))} ${n}: ${esc(t("hs_"+st))}"><b>${n}</b><small>${esc(t("hs_"+st))}</small>${b?`<em>${short(sum)}${w?" · "+esc(wname(w)):""}</em>`:""}</button>`};
  const cnt=k=>[...HALL,...terr].filter(n=>tState(n)[0]===k).length;
  return `<div class="hall"><div class="zone"><span class="zl">${esc(t("zHall"))}</span>${HALL.map(cell).join("")}</div><div class="zone ter"><span class="zl">${esc(t("zTerr"))}</span>${terr.map(cell).join("")}</div>
   <div class="hleg">${["new","cook","ready","bill","eat","free"].map(k=>`<span class="${k}"><i></i>${esc(t("hs_"+k))}${k!=="free"?` · ${cnt(k)}`:""}</span>`).join("")}</div></div>`}
function tCard(b){const os=billOrders(b.id);const sum=billTotal(b.id);const pend=os.filter(o=>o.status!=="served").length;
  return `<button type="button" style="--tc:var(--t${(((+b.table||1)-1)%8+8)%8+1});--tc-ink:var(--t${(((+b.table||1)-1)%8+8)%8+1}-ink)" class="tc${b.req?" req":""}" data-a="bill" data-id="${b.id}">${b.req?`<span class="breq">${esc(t("billReq"))} · ${esc(reqTxt(b.req))}</span>`:""}<span class="tn">${esc(t("table"))} ${esc(b.table)}</span><span class="dim">${os.length} ${esc(t("rounds"))} · ${esc(wname(os.find(o=>o.waiter)?.waiter))}</span><span class="tsum">${vnd(sum)}</span><span class="tst">${os.map(o=>`<i class="d-${o.status}" title="#${o.no}"></i>`).join("")}${pend?`<small>${esc(t("unserved"))}: ${pend}</small>`:""}</span></button>`}
function billLine(i){return `<li><span class="q">${i.qty}×</span><span class="n"><b>${esc(nm(i.mid,ST.lang))}</b>${ST.lang!=="vi"?`<span class="tr">${esc(nm(i.mid,"vi"))}</span>`:""}${i.note?`<span class="note">${esc(i.note)}</span>`:""}</span><span class="p">${vnd(M[i.mid].p*i.qty)}</span></li>`}
/* guests who asked for separate checks: one block per check name */
function billChecks(os){if(!os.some(o=>o.check))return "";const g=Object.create(null);os.forEach(o=>{const k=o.check||t("ckCommon");(g[k]=g[k]||[]).push(o)});
  return Object.entries(g).map(([k,a])=>`<div class="ckh"><b>${esc(t("check"))}: ${esc(k)}</b><span>${vnd(a.reduce((s,o)=>s+tot(o),0))}</span></div><ul class="lines bill">${aggItems(a).map(billLine).join("")}</ul>`).join("")}
function aggItems(os){const m={};os.forEach(o=>o.items.forEach(i=>{const k=i.mid+"|"+(i.note||"");m[k]=m[k]||{mid:i.mid,note:i.note,qty:0};m[k].qty+=i.qty}));return Object.values(m)}
function openBillSheet(bid){const b=ST.bills[bid];if(!b)return;const os=billOrders(bid);const items=aggItems(os);const sum=billTotal(bid);const pend=os.filter(o=>o.status!=="served").length;
  $("sheetIn").innerHTML=`<div class="row"><h2>${esc(t("billT"))} ${esc(b.table)}</h2><span class="sp"></span><button class="btn ghost sm" type="button" id="bX">${esc(t("cancel"))}</button></div>${(b.reqs||(b.req?[b.req]:[])).map(r=>`<div class="reqbar"><b>${esc(t("billReqS"))}</b><span>${esc(reqTxt(r))} · ${new Date(r.at).toLocaleTimeString("vi-VN",{timeZone:snapshot.cafe.timezone||"Asia/Ho_Chi_Minh",hour:"2-digit",minute:"2-digit"})}</span></div>`).join("")}
   <div class="rounds">${os.map(o=>`<span class="pill st-${o.status}">#${o.no} · ${new Date(o.createdAt).toLocaleTimeString("vi-VN",{timeZone:snapshot.cafe.timezone||"Asia/Ho_Chi_Minh",hour:"2-digit",minute:"2-digit"})} · ${esc(stLabel(o.status))}</span>`).join("")}</div>
   ${billChecks(os)}<ul class="lines bill" ${os.some(o=>o.check)?"hidden":""}>${items.map(i=>`<li><span class="q">${i.qty}×</span><span class="n"><b>${esc(nm(i.mid,ST.lang))}</b>${ST.lang!=="vi"?`<span class="tr">${esc(nm(i.mid,"vi"))}</span>`:""}${i.note?`<span class="note">${esc(i.note)}</span>`:""}</span><span class="p">${vnd(M[i.mid].p*i.qty)}</span></li>`).join("")}</ul>
   <div class="btot"><span>${esc(t("billTotal"))}</span><b>${vnd(sum)}</b></div>
   ${pend?`<div class="alert red"><span>${esc(t("unserved"))}: ${pend}</span></div>`:""}
   ${pmBox(os,b)}
   <div class="row"><button class="btn ghost" type="button" id="bMore">+ ${esc(t("addMore"))}</button><span class="sp"></span><button class="btn green" type="button" id="bClose">${esc(t("closeBill"))}</button></div>`;
  $("sheet").hidden=false;
  $("bX").onclick=closeEditor;
  $("bMore").onclick=()=>openEditor(null,os[os.length-1]);
  const PM=pmInit(os,b);
  $("sheetIn").querySelectorAll("[data-pm]").forEach(x=>x.onclick=()=>{PM[x.dataset.ck]=x.dataset.pm;$("sheetIn").querySelectorAll(`[data-pm][data-ck="${CSS.escape(x.dataset.ck)}"]`).forEach(y=>{y.classList.toggle("on",y===x);y.setAttribute("aria-pressed",y===x)});const bx=$("sheetIn").querySelector(".pmbox");if(bx&&!Object.values(PM).some(v=>!v))bx.classList.remove("need")});
  $("bClose").onclick=async e=>{const btn=e.currentTarget;if(Object.values(PM).some(v=>!v)){const bx=$("sheetIn").querySelector(".pmbox");bx.classList.remove("need");void bx.offsetWidth;bx.classList.add("need");bx.scrollIntoView({block:"center",behavior:"smooth"});toast(t("pickPay"),"","r");return}
    if(!window.confirm(t("closeSure")))return;if(!await closeBill(bid,{...PM}))return;closeEditor();
    const v=[...new Set(Object.values(PM))];toast(t("closed")+" · "+t("table")+" "+b.table,vnd(sum)+" · "+t("pay_"+(v.length===1?v[0]:"mix")),"g")}}
/* how the bill was paid: one row, or one row per guest check; preset from what the guest asked for */
const PAYS=["cash","card","qr"];
const PMI={cash:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/></svg>',card:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/></svg>',qr:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h3v3h-3zM20 14v7M14 20h3"/></svg>'};
function billCks(os){return os.some(o=>o.check)?[...new Set(os.map(o=>o.check||t("ckCommon")))]:[""]}
function pmInit(os,b){const r=Object.create(null);const reqs=b.reqs||(b.req?[b.req]:[]);
  billCks(os).forEach(k=>{const q=reqs.find(x=>(x.check||"")===(k===t("ckCommon")?"":k))||(reqs.length===1&&!reqs[0].check?reqs[0]:null);r[k]=q?q.pay:""});return r}
function pmBox(os,b){const pm=pmInit(os,b),cks=billCks(os);
  return `<div class="pmbox"><b>${esc(t("payHow"))}</b>${cks.map(k=>`<div class="pmrow">${k?`<span class="pmn">${esc(t("check"))}: ${esc(k)} · ${vnd(os.filter(o=>(o.check||t("ckCommon"))===k).reduce((s,o)=>s+tot(o),0))}</span>`:""}${PAYS.map(p=>`<button type="button" class="pmb ${pm[k]===p?"on":""}" data-pm="${p}" data-ck="${esc(k)}" aria-pressed="${pm[k]===p}">${PMI[p]}<span>${esc(t("pay_"+p))}</span></button>`).join("")}</div>`).join("")}</div>`}

/* editor sheet */
function openTipQr(){const me=staffBy(ST.me);if(!me)return;
  $("sheetIn").innerHTML=`<div class="row"><h2>${esc(t("tipQrT"))} · ${esc(me.name)}</h2><span class="sp"></span><button class="btn ghost sm" type="button" id="tqX">${esc(t("cancel"))}</button></div>
   <div class="payqr">${me.tipQr?`<img class="qrimg" src="${me.tipQr}" alt="QR">`:`<div class="qrnone">${esc(t("payQrNo"))}</div>`}<div class="qrt"><p class="muted" style="margin:0">${esc(t("tipQrH"))}</p><div class="row"><label class="btn sm upl">${esc(me.tipQr?t("repQr"):t("upQr"))}<input type="file" accept="image/*" id="tqIn"></label>${me.tipQr?`<button class="btn ghost sm" type="button" id="tqDel">${esc(t("delQr"))}</button>`:""}</div></div></div>`;
  $("sheet").hidden=false;$("tqX").onclick=closeEditor;
  $("tqIn").onchange=e=>readQr(e.target.files[0],d=>{mutate(()=>{const x=staffBy(me.id);if(x)x.tipQr=d});toast(t("qrOk"),"","g");openTipQr()});
  {const d=$("tqDel");if(d)d.onclick=()=>{mutate(()=>{const x=staffBy(me.id);if(x)x.tipQr=""});openTipQr()}}}
let ED=null;
function openEditor(id,parent){
  if(id){const o=ST.orders.find(x=>x.id===id);ED={id,table:o.table,items:JSON.parse(JSON.stringify(o.items)),comment:o.comment||"",wishes:[...(o.wishes||[])],lang:o.lang}}
  else ED={id:null,table:parent?parent.table:1,items:[],comment:"",wishes:[],lang:parent?parent.lang:"vi",parent:parent?parent.no:null};
  drawEditor();$("sheet").hidden=false}
function drawEditor(){const l=ST.lang;const sum=ED.items.reduce((s,i)=>s+M[i.mid].p*i.qty,0);
  $("sheetIn").innerHTML=`<div class="row"><h2>${ED.id?esc(t("editT"))+" "+ED.table:ED.parent?esc(t("addMore"))+" · "+esc(t("table"))+" "+ED.table:esc(t("manualT"))}</h2><span class="sp"></span><button class="btn ghost sm" type="button" id="edX">${esc(t("cancel"))}</button></div>
   ${ED.id?"":`<div class="row"><label for="edTable" class="muted">${esc(t("pickTable"))}</label><input id="edTable" type="number" min="1" max="99" value="${ED.table}" style="width:90px;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:8px 10px"></div>`}
   <div class="ed">${ED.items.length?ED.items.map((i,k)=>`<div class="edl"><span class="nm">${esc(nm(i.mid,"vi"))}${ST.lang==="ru"?` <span class="dim">· ${esc(nm(i.mid,"ru"))}</span>`:""}</span><div class="qa"><button type="button" data-q="-" data-k="${k}" aria-label="−">−</button><b>${i.qty}</b><button type="button" data-q="+" data-k="${k}" aria-label="+">+</button></div><input type="text" data-note="${k}" value="${esc(i.note)}" placeholder="${esc(t("notePh"))}" aria-label="${esc(t("notePh"))}"></div>`).join(""):`<div class="empty">${esc(t("none"))}</div>`}</div>
   <details id="edPick" ${ED.open||!ED.items.length?"open":""}><summary class="muted" style="cursor:pointer;font-weight:600;padding:4px 0">+ ${esc(t("addItem"))}</summary><div class="picker" style="margin-top:8px">${MENU.map(m=>`<button type="button" data-add="${m.id}">${m.ph?`<img src="${PH[m.ph]}" alt="">`:""}<span>${esc(m.vi)}<br><span class="dim">${short(m.p)}</span></span></button>`).join("")}</div></details>
   <div><div class="muted" style="font-weight:600;margin-bottom:6px">${esc(t("wishes"))}</div><div class="wchips">${WISH.map(w=>`<button type="button" data-w="${w.k}" aria-pressed="${ED.wishes.includes(w.k)}">${esc(w[l])}</button>`).join("")}</div></div>
   <div><label for="edCm" class="muted" style="font-weight:600;display:block;margin-bottom:6px">${esc(t("comment"))}</label><textarea id="edCm" class="ta" placeholder="${esc(t("commentPh"))}">${esc(ED.comment)}</textarea></div>
   <div class="row"><b>${esc(t("total"))}: ${vnd(sum)}</b><span class="sp"></span><button class="btn ghost" type="button" id="edSave" ${ED.items.length?"":"disabled"}>${esc(t("save"))}</button><button class="btn" type="button" id="edSend" ${ED.items.length?"":"disabled"}>${esc(t("saveSend"))}</button></div>`;
  const S2=$("sheetIn");
  S2.querySelector("#edX").onclick=closeEditor;
  S2.querySelector("#edPick").ontoggle=e=>{ED.open=e.target.open};
  S2.querySelectorAll("[data-q]").forEach(b=>b.onclick=()=>{syncED();const it=ED.items[+b.dataset.k];it.qty+=b.dataset.q==="+"?1:-1;if(it.qty<=0)ED.items.splice(+b.dataset.k,1);drawEditor()});
  S2.querySelectorAll("[data-add]").forEach(b=>b.onclick=()=>{syncED();const ex=ED.items.find(i=>i.mid===b.dataset.add&&!i.note);if(ex)ex.qty++;else ED.items.push({mid:b.dataset.add,qty:1,note:"",done:false,added:!!ED.id});drawEditor()});
  S2.querySelectorAll("[data-w]").forEach(b=>b.onclick=()=>{syncED();const k=b.dataset.w;ED.wishes=ED.wishes.includes(k)?ED.wishes.filter(x=>x!==k):[...ED.wishes,k];drawEditor()});
  S2.querySelector("#edSave").onclick=()=>commitED(false);
  S2.querySelector("#edSend").onclick=()=>commitED(true);
}
function syncED(){const S2=$("sheetIn");S2.querySelectorAll("[data-note]").forEach(i=>{const it=ED.items[+i.dataset.note];if(it)it.note=i.value.trim()});const c=S2.querySelector("#edCm");if(c)ED.comment=c.value.trim();const tb=S2.querySelector("#edTable");if(tb)ED.table=tb.value}
function commitED(send){syncED();if(!ED.items.length)return;
  mutate(()=>{let o;
    if(ED.id){o=ST.orders.find(x=>x.id===ED.id);o.items=ED.items;o.comment=ED.comment;o.wishes=ED.wishes}
    else{o=newOrder({table:ED.table,lang:ED.lang,items:ED.items,comment:ED.comment,wishes:ED.wishes,src:"waiter",status:"accepted"});o.waiter=ST.me;o.acceptedAt=Date.now();o.lateAccept=false}
    if(send&&o.status==="accepted"){o.status="cooking";o.sentAt=Date.now()}});
  ST.wtab="cooking";save();closeEditor();render()}
function closeEditor(){$("sheet").hidden=true;ED=null}


/* --- kitchen --- */
function rKitchen(el){const f=ST.ktab==="stop"?"all":ST.ktab;const L=live();
  const filt=o=>(f==="all"||o.items.some(i=>M[i.mid].st===(f==="bar"?"b":"k")))&&!(f!=="all"&&o.stationServedAt?.[f]);
  const cooking=L.filter(o=>["cooking","ready"].includes(o.status)&&!stationReady(o,f)&&filt(o)).sort((a,b)=>a.sentAt-b.sentAt);
  const ready=L.filter(o=>["cooking","ready"].includes(o.status)&&stationReady(o,f)&&filt(o));
  const card=o=>{const its=o.items.map((i,k)=>[i,k]).filter(([i])=>f==="all"||M[i.mid].st===(f==="bar"?"b":"k"));
    const done=stationReady(o,f),at=f==="all"?o.readyAt:o.stationReadyAt?.[f]||o.readyAt;
    return `<article style="--tc:var(--t${(((+o.table||1)-1)%8+8)%8+1});--tc-ink:var(--t${(((+o.table||1)-1)%8+8)%8+1}-ink)" class="kc ${done?"ready":""}" ${!done?`data-slow="${o.sentAt}"`:""}>
    <div class="kh"><span class="tb">${esc(t("table"))} ${esc(o.table)}</span><span>#${o.no}</span><span class="tm" ${!done?`data-mmss="${o.sentAt}"`:""}>${!done?mmss(o.sentAt):"✓"}</span></div>
    <div class="kb">${its.map(([i,k])=>`<button type="button" class="ki ${i.done?"done":""}" data-ki="${o.id}" data-k="${k}" ${done?"disabled":""}><span class="q">${i.qty}×</span><span><b>${esc(nm(i.mid,"vi"))}</b>${f==="all"?`<span class="stn ${M[i.mid].st==="b"?"sb":"sk"}">${esc(M[i.mid].st==="b"?t("bar"):t("kit"))}</span>`:""}${i.added?` <span class="badge-new">+</span>`:""}${i.note?`<span class="note">⚠ ${esc(i.note)}</span>`:""}${ST.lang==="ru"?`<span class="sub">${esc(nm(i.mid,"ru"))}</span>`:""}</span></button>`).join("")}
    ${o.wishes&&o.wishes.length?`<div class="kw">⚠ ${o.wishes.map(k=>{const w=WISH.find(x=>x.k===k);return w?esc(w.vi)+(ST.lang==="ru"?" ("+esc(w.ru)+")":""):""}).join(" · ")}</div>`:""}
    ${o.comment?`<div class="kcm">${esc(o.comment)}</div>`:""}</div>
    ${f==="all"?prepSummary(o):""}<div class="kf"><span class="meta">${esc(wname(o.waiter))}</span><span class="sp"></span>${!done?(f==="all"?["kitchen","bar"]:[f]).filter(scope=>stationItems(o,scope).length&&!stationReady(o,scope)).map(scope=>`<button class="btn green sm" type="button" data-kr="${o.id}" data-station="${scope}">${esc(t(scope==="bar"?"kBar":"kKitchen"))} · ${esc(t("kDone"))}</button>`).join(""):`<span class="meta">${esc(t("kReady"))}${at?` · <span data-since="${at}">${since(at)}</span>`:""}</span>`}</div></article>`};
  const ns=Object.keys(ST.stop||{}).length;
  const ktabs=`<div class="row"><div class="tabs">${[["all",t("kAll")],["kitchen",t("kKitchen")],["bar",t("kBar")]].map(([k,lab])=>`<button type="button" data-kt="${k}" class="${k===f?"on":""} ${["kitchen","bar"].includes(k)&&L.some(o=>["cooking","ready"].includes(o.status)&&stationItems(o,k).length&&(!stationReady(o,k)||pendingServe(o,k)))?"needs-action":""}">${esc(lab)}${k==="stop"&&ns?`<span class="stopcnt">${ns}</span>`:""}</button>`).join("")}</div><span class="sp"></span>${f==="stop"?"":`<span class="dim">${esc(t("kTap"))}</span>`}</div>`;
  if(f==="stop"){el.innerHTML=ktabs+`<div id="stopIn"></div>`;el.querySelectorAll("[data-kt]").forEach(b=>b.onclick=()=>{ST.ktab=b.dataset.kt;save();render()});rStop(el.querySelector("#stopIn"));return}
  el.innerHTML=ktabs+`
   ${cooking.length?`<div class="kgrid">${cooking.map(card).join("")}</div>`:`<div class="empty">${esc(t("kNone"))}</div>`}
   ${ready.length?`<h3 class="muted">${esc(t("kReady"))} · ${ready.length}</h3><div class="kgrid">${ready.map(card).join("")}</div>`:""}`;
  el.querySelectorAll("[data-kt]").forEach(b=>b.onclick=()=>{ST.ktab=b.dataset.kt;save();render()});
  el.querySelectorAll("[data-ki]").forEach(b=>b.onclick=()=>kItem(b.dataset.ki,+b.dataset.k));
  el.querySelectorAll("[data-kr]").forEach(b=>b.onclick=()=>kReady(b.dataset.kr,b.dataset.station));
}
let stopQ=ST.stopQ||"";
const coName=(d,l)=>l==="ru"?d[1]:d[0];
function setStop(k,on){mutate(()=>{ST.stop=ST.stop||{};if(on)ST.stop[k]={at:Date.now(),by:ST.role};else delete ST.stop[k]});toast(on?t("stopOk"):t("stopRet"),coDish(k),on?"r":"g")}
function coDish(k){const [sid,i]=k.split("|");const s=CMENU.find(x=>x[0]===sid);const d=s&&s[3][+i];return d?coName(d,ST.lang):k}
function rStop(el){const stop=ST.stop||{};const ks=Object.keys(stop).sort((a,b)=>stop[b].at-stop[a].at);const l=ST.lang;
  const row=(k,d,out)=>`<li class="${out?"out":""}" data-q="${esc((d[0]+" "+d[1]).toLowerCase())}"><div class="n"><b>${esc(coName(d,l))}</b>${l==="ru"?`<span>${esc(d[0])}</span>`:""}</div><button class="btn sm availability-toggle ${out?"":"outb"}" type="button" role="switch" aria-checked="${!out}" aria-label="${esc((l==="ru"?"Доступность: ":"Tình trạng: ")+coName(d,l))}" data-stop="${k}" data-on="${out?0:1}"><span aria-hidden="true"></span><b>${esc(out?(l==="ru"?"Выключено":"Đã tắt"):(l==="ru"?"Доступно":"Có món"))}</b></button></li>`;
  el.innerHTML=`<div class="card"><h3>${esc(t("stopT"))} · ${ks.length}</h3><p class="muted" style="margin:0">${esc(t("stopH"))}</p>${ks.length?`<ul class="stopl">${ks.map(k=>{const [sid,i]=k.split("|");const s=CMENU.find(x=>x[0]===sid);const d=s&&s[3][+i];return d?row(k,d,true):""}).join("")}</ul>`:`<div class="empty" style="padding:14px">${esc(t("stopNone"))}</div>`}</div>
   <div class="card"><h3>${esc(t("stopAll"))}</h3><input class="stopin" id="stopQ" type="search" placeholder="${esc(t("stopQ"))}" value="${esc(stopQ)}"><ul class="stopl" id="stopAll">${CMENU.map(s=>`<h4 data-sec="${s[0]}">${esc(l==="ru"?s[2]:s[1])}</h4>`+s[3].map((d,i)=>row(s[0]+"|"+i,d,!!stop[s[0]+"|"+i])).join("")).join("")}</ul></div>`;
  const flt=()=>{const q=stopQ.trim().toLowerCase();const all=el.querySelector("#stopAll");let shown={};
    all.querySelectorAll("li").forEach(li=>{const v=!q||li.dataset.q.includes(q);li.hidden=!v;if(v)shown[li.querySelector("[data-stop]").dataset.stop.split("|")[0]]=1});
    all.querySelectorAll("h4").forEach(h=>h.hidden=!shown[h.dataset.sec])};
  const qi=el.querySelector("#stopQ");qi.oninput=()=>{stopQ=qi.value;ST.stopQ=stopQ;save();flt()};flt();
  el.querySelectorAll("[data-stop]").forEach(b=>b.onclick=()=>setStop(b.dataset.stop,b.dataset.on==="1"))}
// Authoritative commands replace all business mutations; preferences remain local.
setStop=(key,on)=>{const item=stopMenu[Number(key.split('|')[1])];if(item)return options.onCommand('stop',{item_id:item.id,stopped:on})};
const originalStop=rStop;rStop=host=>{const prior=ST.stop;ST.stop=Object.fromEntries(stopMenu.map((i,n)=>[i,n]).filter(([i])=>i.stopped).map(([i,n])=>['menu|'+n,{at:0}]));originalStop(host);if(snapshot.me.role==='waiter'){host.querySelectorAll('[data-stop]').forEach(b=>b.disabled=true);const text=host.querySelector('p');if(text)text.textContent=ST.lang==='ru'?'Доступность меняет кухня, бар или управляющий.':'Bếp, bar hoặc quản lý cập nhật tình trạng món.'}ST.stop=prior};
const command=async(a,b)=>options.onCommand(a,b);
accept=id=>command('guest_accept',{submission_id:id});toKitchen=id=>command('send',staffServerState.orderCommand(ST,'send',id).b);
kReady=(id,station)=>command('station_ready',staffServerState.orderCommand(ST,'station_ready',id,{station}).b);
kItem=(id,index)=>{const i=ST.orders.find(o=>o.id===id)?.items[index];if(i)return command('item_ready',staffServerState.orderCommand(ST,'item_ready',id,{item_id:i.id,ready:!i.done}).b)};
served=(id,station)=>command('serve',staffServerState.orderCommand(ST,'serve',id,{station}).b);
closeBill=async(id,pays)=>{const bill=snapshot.bills.find(b=>b.id===id);if(!bill||bill.status!=='open'){options.onNotice(ST.lang==='ru'?'Этот счёт уже закрыт. Данные обновляются.':'Hóa đơn đã đóng. Đang cập nhật.');return false}return !!await command('bill_close',staffFlowContract.closeBody(snapshot,id,pays));};
openTipQr=()=>options.onProfile();
commitED=async send=>{syncED();const draft=structuredClone(ED);if(!draft.items.length)return;draft.items=draft.items.map(i=>({...i,serverId:M[i.mid]?.serverId}));const request=staffFlowContract.editBody(snapshot,draft,send);if(await command(request.a,request.b)){closeEditor();ST.wtab='cooking';save();options.onRender()}};
el.querySelectorAll?.('[data-a=accept]');
// Pending guest submissions retain their exact server ID, quotes, notes and check names.
for(const g of options.incoming||[]){const items=[];for(const ck of g.checks)for(const [n,i] of ck.items.entries()){const mid='incoming:'+g.id+':'+ck.id+':'+n;M[mid]={...i.names,p:i.price};items.push({mid,qty:i.quantity,note:(g.checks.length>1?'Чек '+ck.label+'. ':'')+(i.note||'')})}ST.orders.push({id:g.id,no:g.id.slice(0,8),status:'new',table:g.table,items,createdAt:Date.parse(g.created_at),check:g.checks.length===1?g.checks[0].label:'',src:'qr',lang:g.lang,wishes:[],seed:false})}
for(const q of options.services||[]){const b=ST.bills[q.bill_id];if(b){b.req={at:Date.parse(q.created_at),pay:q.method==='qr_transfer'?'qr':q.method,check:q.check,paid:q.paid};(b.reqs||=[]).push(b.req)}}
hallMap=()=>{
 const ru=ST.lang==='ru',isSunSea=snapshot.menu.some(item=>String(item.external_key||'').startsWith('sunsea|'));
 const byLabel=new Map(snapshot.tables.map(tb=>[String(tb.label),tb]));
 const capacity=slot=>slot.min===slot.max?String(slot.max):slot.min+'–'+slot.max;
 const card=(tb,slot)=>{
  const bill=snapshot.bills.find(b=>b.table_id===tb.id&&b.status==='open'),os=bill?ST.orders.filter(o=>o.bill===bill.id):[];
  const waiting=(options.incoming||[]).some(g=>g.table===tb.label),req=bill&&(options.services||[]).some(q=>q.bill_id===bill.id&&!q.done);
  const state=waiting?'waiting':!bill?'free':req?'bill':os.some(o=>o.status==='ready')?'ready':os.some(o=>['accepted','cooking'].includes(o.status))?'cook':os.some(o=>o.status==='new')?'new':'eat';
  const label=(ru?{waiting:'Ожидает заказ',free:'Свободен',bill:'Просит счёт',ready:'Можно выносить',cook:'Готовится',new:'Новый заказ',eat:'Занят'}:{waiting:'Chờ gọi món',free:'Còn trống',bill:'Yêu cầu tính tiền',ready:'Sẵn sàng phục vụ',cook:'Đang chuẩn bị',new:'Đơn mới',eat:'Đang dùng bữa'})[state];
  const sum=os.reduce((n,o)=>n+tot(o),0),seats=slot?capacity(slot):tb.seats;
  const position=slot?' style="left:'+slot.x/6+'%;top:'+slot.y/9+'%;width:'+slot.w/6+'%;height:'+slot.h/9+'%"':'';
  return '<div class="hall-table '+state+(slot?' hall-plan-table'+(slot.kind==='booth'?' is-booth':'')+(slot.group?' in-room':''):'')+'"'+position+'><button type="button" class="hall-table-main" data-ht="'+esc(tb.label)+'" aria-label="'+(ru?'Стол ':'Bàn ')+esc(tb.label)+', '+seats+(ru?' мест, ':' chỗ, ')+label+'"><strong>'+esc(tb.label)+'</strong><span>'+seats+(ru?' мест':' chỗ')+'</span><small>'+label+'</small>'+(bill?'<em>'+vnd(sum)+'</em>':'')+'</button>'+(options.onQr?'<button type="button" class="hall-table-qr" data-hall-qr="'+esc(tb.id)+'" aria-label="QR меню стола '+esc(tb.label)+'">QR</button>':'')+'</div>';
 };
 const planned=isSunSea?SUNSEA_LAYOUT.tables.filter(slot=>byLabel.has(String(slot.id))):[];
 const seen=new Set(planned.map(slot=>String(slot.id)));
 const extras=snapshot.tables.filter(tb=>!seen.has(String(tb.label)));
 const floor='<div class="server-hall-plan-scroll" tabindex="0" aria-label="'+(ru?'План зала Sun&Sea, можно прокрутить горизонтально':'Sơ đồ Sun&Sea, có thể cuộn ngang')+'"><div class="server-hall-plan"><div class="hall-plan-door" aria-hidden="true">⌄<span>'+(ru?'Вход':'Lối vào')+'</span></div><div class="hall-plan-aisle" aria-hidden="true">'+(ru?'ПРОХОД':'LỐI ĐI')+'</div><div class="hall-plan-room" aria-hidden="true"><span>'+(ru?'Зал · 30 мест':'Phòng · 30 chỗ')+'</span></div>'+planned.map(slot=>card(byLabel.get(String(slot.id)),slot)).join('')+'</div></div>';
 const cells=isSunSea?floor+(extras.length?'<div class="server-hall-grid">'+extras.map(tb=>card(tb)).join('')+'</div>':''):'<div class="server-hall-grid">'+snapshot.tables.map(tb=>card(tb)).join('')+'</div>';
 return '<div class="server-hall"><div class="server-hall-heading"><h3>'+(ru?'Карта зала':'Sơ đồ bàn')+'</h3><span>'+snapshot.tables.length+(ru?' столов · ':' bàn · ')+snapshot.tables.reduce((n,t)=>n+t.seats,0)+(ru?' мест':' chỗ')+'</span></div>'+cells+'<div class="server-hall-legend"><span>○ '+(ru?'Свободен':'Còn trống')+'</span><span>● '+(ru?'Ожидает заказ':'Chờ gọi món')+'</span><span>● '+(ru?'Занят':'Đang dùng bữa')+'</span><span>● '+(ru?'Можно выносить':'Sẵn sàng phục vụ')+'</span></div></div>';
};
el.classList.add('original-flow');
if(options.screen==='menu'){rStop(el)}else if(options.screen==='workbench'){el.innerHTML='<section><h2>'+esc(ST.lang==='ru'?'Заказы':'Đơn hàng')+'</h2><div id=\"flow-waiter-pane\"></div></section><section><h2>'+esc(ST.lang==='ru'?'Кухня и бар':'Bếp & Bar')+'</h2><div id=\"flow-prep-pane\"></div></section>';el.classList.add('flow-workbench');rWaiter(el.querySelector('#flow-waiter-pane'));rKitchen(el.querySelector('#flow-prep-pane'))}else if(options.screen==='prep'){if(['bar','kitchen'].includes(snapshot.me.role)&&ST.ktab!=='stop')ST.ktab=snapshot.me.role;rKitchen(el);if(['bar','kitchen'].includes(snapshot.me.role))el.querySelectorAll('[data-kt]').forEach(b=>{if(![snapshot.me.role,'stop'].includes(b.dataset.kt))b.remove()})}
else rWaiter(el);
el.querySelectorAll('[data-a=accept]').forEach(b=>{const decline=document.createElement('button');decline.type='button';decline.className='btn ghost sm';decline.textContent=ST.lang==='ru'?'Отклонить':'Từ chối';decline.onclick=()=>{if(confirm(ST.lang==='ru'?'Отклонить этот заказ?':'Từ chối đơn này?'))options.onCommand('guest_reject',{submission_id:b.dataset.id})};b.after(decline)});
if(options.headerManaged)el.querySelector('.who')?.remove();
const select=el.querySelector('#meSel');if(select){select.value=ST.me;select.disabled=true;select.setAttribute('aria-label',ST.lang==='ru'?'Ваш аккаунт':'Tài khoản của bạn')}
const shift=el.querySelector('#shiftBtn');if(shift)shift.onclick=()=>options.onShift(!ST.shift[ST.me]);
const manual=el.querySelector('#manualBtn');if(manual)manual.disabled=snapshot.me.role==='waiter'&&!ST.shift[ST.me];
// Only authenticated assignment may edit a draft; others can view status.
el.querySelectorAll('[data-a=edit],[data-a=kitchen],[data-a=served]').forEach(b=>{const o=ST.orders.find(o=>o.id===b.dataset.id);if(snapshot.me.role==='waiter'&&o?.waiter!==ST.me)b.disabled=true});
el.querySelectorAll('[data-a=edit]').forEach(b=>{const o=ST.orders.find(o=>o.id===b.dataset.id);if(o?.status!=='accepted')b.remove()});
const originalDraw=drawEditor;drawEditor=()=>{originalDraw();if(!ED.id){const old=$('sheetIn').querySelector('#edTable');if(old){const select=document.createElement('select');select.id='edTable';for(const t of snapshot.tables){const option=document.createElement('option');option.value=t.label;option.textContent=t.label;option.selected=t.label===String(ED.table);select.append(option)}old.replaceWith(select)}const field=document.createElement('label');field.textContent=ST.lang==='ru'?'Чек':'Hóa đơn';const input=document.createElement('input');input.id='edCheck';input.maxLength=80;input.value=ED.check||'Общий счёт';input.oninput=()=>ED.check=input.value;field.append(input);$('sheetIn').querySelector('.ed').before(field)}};
const baseDraw=drawEditor;drawEditor=()=>{baseDraw();const picker=$('sheetIn')?.querySelector('#edPick .picker');if(!picker)return;const search=document.createElement('input');search.type='search';search.className='ed-menu-search';search.placeholder=ST.lang==='ru'?'Найти блюдо по названию…':'Tìm món…';search.setAttribute('aria-label',search.placeholder);search.value=ED.search||'';picker.before(search);const empty=document.createElement('p');empty.className='ed-search-empty';empty.textContent=ST.lang==='ru'?'Блюдо не найдено':'Không tìm thấy món';picker.after(empty);const filter=()=>{ED.search=search.value;const q=search.value.trim().toLocaleLowerCase();let count=0;picker.querySelectorAll('[data-add]').forEach(btn=>{const item=M[btn.dataset.add],match=!q||[item?.vi,item?.ru,item?.en].some(n=>String(n||'').toLocaleLowerCase().includes(q));btn.hidden=!match;if(match)count++});empty.hidden=!!count};search.oninput=filter;search.onkeydown=e=>{if(e.key==='Enter'){e.preventDefault();picker.querySelector('[data-add]:not([hidden])')?.click()}};filter()};
const originalOpen=openEditor;openEditor=(id,parent)=>{originalOpen(id,parent);if(ED){ED.check=parent?.check||'Общий счёт';const input=$('sheetIn').querySelector('#edCheck');if(input)input.value=ED.check}};
if(manual)manual.onclick=()=>openEditor(null,{table:snapshot.tables[0]?.label,lang:'vi'});
const ensureBill=openBillSheet;openBillSheet=id=>{ensureBill(id);const close=$('bClose');if(close&&billOrders(id).some(o=>o.status!=='served')){close.disabled=true;close.title=ST.lang==='ru'?'Сначала подайте все позиции':'Phục vụ tất cả món trước'}if(ST.bills[id]?.closed){$('bClose')?.remove();$('bMore')?.remove();$('sheetIn')?.querySelector('.pmbox')?.remove()}};
el.querySelectorAll('[data-ht]').forEach(b=>b.onclick=()=>{const tb=snapshot.tables.find(t=>t.label===b.dataset.ht),bl=Object.values(ST.bills).find(x=>!x.closed&&x.tableId===tb?.id);if(bl)openBillSheet(bl.id);else openEditor(null,{table:tb.label,lang:'vi',no:null})});
el.querySelectorAll('[data-hall-qr]').forEach(b=>b.onclick=()=>options.onQr?.(b.dataset.hallQr));

return {isEditing:()=>!$('sheet').hidden,close:closeEditor};
}
return {render:renderFlow,stop(){overlay?.remove();overlay=null}};})();
