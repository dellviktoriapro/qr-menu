'use strict';
const operationsCore={
 personalControls(s,lang,qrKnown){const on=!!s.shifts?.[s.me.id],vi=lang==='vi';return {visible:['owner','manager','waiter'].includes(s.me.role),on,shiftLabel:vi?(on?'Kết thúc ca':'Mở ca'):(on?'Завершить смену':'Открыть смену'),qrLabel:vi?'QR tiền boa':'QR для чаевых',qrAttention:qrKnown===false}},
 viewAllowed(role,view){const owner=['owner','manager'].includes(role);return view==='orders'?owner||role==='waiter':view==='prep'?owner||['kitchen','bar'].includes(role):['workbench','report','staff','appearance'].includes(view)?owner:['menu','profile'].includes(view)},
 definitive(e){return /^(?:P0001|42501|22[0-9A-Z]{3}|23[0-9A-Z]{3}|40001)$/.test(String(e?.code||''))},
 name(item){return item.name_snapshot?.ru||item.names?.ru||item.name_snapshot?.vi||item.names?.vi||'Без названия'},
 total(order){return order.items.filter(i=>!i.cancelled_at).reduce((s,i)=>s+Number(i.quantity)*Number(i.unit_price_minor||0),0)},
 station(order,scope){const items=order.items.filter(i=>!i.cancelled_at&&i.station===scope);return {present:items.length>0,ready:items.length>0&&items.every(i=>i.ready_at),served:items.length>0&&items.every(i=>i.served_at)}},
 hasPending(order){return ['kitchen','bar'].some(s=>{const v=this.station(order,s);return v.ready&&!v.served})},
 money(value,currency='VND'){return new Intl.NumberFormat('ru-RU',{style:'currency',currency,maximumFractionDigits:0}).format(Number(value||0))},
 error(e){const m=String(e?.message||'');if(/GUEST_ORDERS_PENDING/.test(m))return 'Сначала примите гостевые заказы этого стола.';if(/LINK_EXISTS_CONFIRM_REISSUE/.test(m))return 'QR уже существует. Для замены отметьте перевыпуск — прежний QR перестанет работать.';if(/ITEM_OR_PRICE_CHANGED/.test(m))return 'Цена или доступность позиции изменилась. Уточните заказ у гостя перед приёмом.';if(/VERSION_CONFLICT|40001/.test(m))return 'Заказ уже изменился на другом устройстве. Данные обновлены — проверьте и повторите действие.';if(/ACCESS_DENIED|AUTH_REQUIRED|ROLE_DENIED|42501/.test(m))return 'Нет доступа к этому действию. Проверьте аккаунт или обратитесь к владельцу.';if(/STATION_NOT_READY/.test(m))return 'Эта станция ещё не приготовила все позиции.';if(/UNSERVED_ORDERS/.test(m))return 'Сначала отметьте подачу всех заказов этого стола.';if(/fetch|network|timeout|abort/i.test(m))return 'Нет подтверждения от сервера. Не повторяйте заказ заново: используйте «Повторить отправку».';return 'Действие не выполнено: '+m}
};
if(typeof module!=='undefined')module.exports=operationsCore;
