/* Banner QR: browsing and contacting the restaurant, never a table order. */
const PUBLIC_PREVIEW=new URLSearchParams(location.search).get('view')==='preview';
if(PUBLIC_PREVIEW){
 const copies={
 ru:{pre:'Сделать предзаказ',book:'Забронировать столик',note:'Предзаказ и бронь подтверждаются рестораном.',missing:'Контакт ресторана ещё не подключён.'},
 en:{pre:'Pre-order',book:'Book a table',note:'Pre-orders and table bookings are confirmed by the restaurant.',missing:'Restaurant contact has not been connected yet.'},
 vi:{pre:'Đặt món trước',book:'Đặt bàn',note:'Nhà hàng sẽ xác nhận yêu cầu đặt món trước và đặt bàn.',missing:'Chưa kết nối thông tin liên hệ của nhà hàng.'},
 ko:{pre:'메뉴 사전 주문',book:'테이블 예약',note:'사전 주문과 테이블 예약은 레스토랑 확인 후 확정됩니다.',missing:'레스토랑 연락처가 아직 연결되지 않았습니다.'},
 zh:{pre:'提前预订餐品',book:'预订餐桌',note:'提前订餐和订桌需由餐厅确认。',missing:'尚未添加餐厅联系方式。'}
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
 const pre=document.createElement('button'),book=document.createElement('button');pre.type=book.type='button';pre.className='public-preorder';book.className='public-booking';actions.append(pre,book);document.body.appendChild(actions);
 function contactLink(key){try{const u=new URL(PUBLIC_CONTACT?.[key]);return ['https:','tel:','mailto:'].includes(u.protocol)?u.href:''}catch{return ''}}
 function paint(){const t=copy();intro.textContent=t.note;const href=contactLink('preorderUrl');pre.textContent=t.pre;pre.disabled=!href;pre.setAttribute('aria-disabled',String(!href));pre.onclick=()=>{if(href)window.open(href,'_blank','noopener,noreferrer')};book.textContent=t.book;book.setAttribute('aria-disabled','false');book.onclick=()=>BOOKING.open?.(book)}
 renderBar=function(){$('bar').hidden=true;document.body.classList.remove('hasbar');paint()};
 const previousDraw=drawDish;drawDish=function(...args){const result=previousDraw(...args);$('dOpts').querySelectorAll('.dish-item-preferences,.item-pref-entry').forEach(el=>el.remove());return result};
 paint();
}
