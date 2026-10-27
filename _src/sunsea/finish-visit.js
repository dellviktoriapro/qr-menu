/* The QR table adapter already supplies its own shared-visit action. */
if(!document.body.classList.contains('shared-cart')){
 const finishCopy={
 ru:['Завершить визит','Завершить визит?','Все выбранные блюда и пожелания будут удалены из корзины на этом устройстве.'],
 en:['End visit','End this visit?','All selected dishes and preferences will be removed from the cart on this device.'],
 vi:['Kết thúc lượt dùng bàn','Kết thúc lượt dùng bàn?','Tất cả món đã chọn và yêu cầu sẽ được xóa khỏi giỏ hàng trên thiết bị này.'],
 ko:['방문 종료','방문을 종료할까요?','이 기기의 장바구니에서 선택한 메뉴와 요청사항이 모두 삭제됩니다.'],
 zh:['结束本次用餐','结束本次用餐？','此设备购物车中的所有已选菜品和要求将被清空。']
 };
 const finish=document.createElement('button');finish.type='button';finish.id='menuFinishVisit';finish.className='cart-finish';
 $('menuQrPayCart').insertAdjacentElement('afterend',finish);
 const copy=()=>finishCopy[lang]||finishCopy.ru;
 const beforeBar=renderBar;renderBar=function(...args){const result=beforeBar(...args);finish.textContent=copy()[0];return result};
 finish.onclick=()=>{const [label,title,description]=copy();confirmBox(title,description,label,()=>{clearCart();$('waiterView').hidden=true;$('qrs').hidden=true})};
}
