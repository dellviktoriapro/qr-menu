/* Banner QR: browsing and contacting the restaurant, never a table order. */
const PUBLIC_PREVIEW=(()=>{
 const params=new URLSearchParams(location.search);if(params.get('view')==='preview')return true;
 const table=params.get('t');if(!/^\d{1,2}$/.test(table||''))return true;
 let token=params.get('room');try{if(!token)token=sessionStorage.getItem('ss_table_room_'+table)}catch{}
 return !/^[a-f0-9]{64}$/.test(token||'');
})();
if(PUBLIC_PREVIEW){
 const copies={
 ru:{pre:'Сделать предзаказ',book:'Забронировать столик',note:'Бронь подтверждается рестораном.',missing:'Контакт ресторана ещё не подключён.'},
 en:{pre:'Pre-order',book:'Book a table',note:'Table bookings are confirmed by the restaurant.',missing:'Restaurant contact has not been connected yet.'},
 vi:{pre:'Đặt món trước',book:'Đặt bàn',note:'Nhà hàng sẽ xác nhận yêu cầu đặt bàn.',missing:'Chưa kết nối thông tin liên hệ của nhà hàng.'},
 ko:{pre:'메뉴 사전 주문',book:'테이블 예약',note:'테이블 예약은 레스토랑 확인 후 확정됩니다.',missing:'레스토랑 연락처가 아직 연결되지 않았습니다.'},
 zh:{pre:'提前预订餐品',book:'预订餐桌',note:'订桌需由餐厅确认。',missing:'尚未添加餐厅联系方式。'}
 };
 const copy=()=>copies[lang]||copies.ru;
 document.body.classList.add('public-preview');
 const descriptions={ru:'Sun&Sea Restaurant в Муйне: морепродукты, вьетнамская и тайская кухня, пицца, паста и фирменные блюда от шефа.',en:'Sun&Sea Restaurant in Mui Ne: seafood, Vietnamese and Thai cuisine, pizza, pasta and chef’s specials.',vi:'Nhà hàng Sun&Sea ở Mũi Né: hải sản, món Việt và Thái, pizza, mì Ý và món đặc biệt của bếp trưởng.',ko:'무이네의 Sun&Sea 레스토랑: 해산물, 베트남·태국 요리, 피자, 파스타, 셰프 스페셜.',zh:'美奈 Sun&Sea 餐厅：海鲜、越南与泰国菜、披萨、意面和主厨特色菜。'};
 if(typeof T!=='undefined')for(const [lg,description] of Object.entries(descriptions))T[lg].tag=description;

 if(typeof SERVICE_CONFIG!=='undefined')SERVICE_CONFIG.cartApi=null;
 ctrl=()=>'';bump=clearCart=sendOrder=openPick=openTbl=openPay=openQr=openTips=inbox=()=>{};
 if(typeof ITEM_PREFS!=='undefined'){ITEM_PREFS.set=()=>{};ITEM_PREFS.priceButton=()=>''}
 const intro=document.createElement('p');intro.className='public-intro';$('menu').insertAdjacentElement('beforebegin',intro);
 const actions=document.createElement('div');actions.id='publicLeads';actions.className='public-leads';
 const book=document.createElement('button');book.type='button';book.className='public-booking';actions.append(book);document.body.appendChild(actions);
 function paint(){const t=copy();intro.textContent=t.note;book.textContent=t.book;book.setAttribute('aria-disabled','false');book.onclick=()=>BOOKING.open?.(book)}
 renderBar=function(){$('bar').hidden=true;document.body.classList.remove('hasbar');paint()};
 const previousDraw=drawDish;drawDish=function(...args){const result=previousDraw(...args);$('dOpts').querySelectorAll('.dish-item-preferences,.item-pref-entry').forEach(el=>el.remove());return result};
 paint();
}
