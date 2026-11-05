/* Printed menu references are display-only, never cart IDs or inferred indices. */
function waiterMenuRef(item,key){
 const number=item?.[7]?.n;
 if(typeof number!=='string'||!/^\d+(?:\.\d+)?$/.test(number))return '';
 const section=DATA.find(s=>s.id===String(key).split('|')[0]);
 if(!section)return '';
 return `<span class="waiter-menu-ref" data-printed-number="${esc(number)}"><bdi>№ ${esc(number)}</bdi><span lang="vi">${esc(section.n.vi)}</span></span>`;
}
