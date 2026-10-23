/* Sun&Sea-only navigation. Dish records and order keys stay in the shared engine. */
const COAST_ICONS={
 chef:'<path d="M8 15c-5-1-5-7-1-8 0-5 8-5 9 0 5 0 6 7 1 8v5H8z"/><path d="M8 16h9M11 11v4m3-4v4"/>',
 fish:'<path d="M17 8c-6-5-12-1-14 4 2 5 8 9 14 4l4 3V5z"/><circle cx="7" cy="11" r=".7"/>',
 bowl:'<path d="M3 11h18c-1 6-4 9-9 9S4 17 3 11zM8 4c-3 2 3 2 0 5m5-6c-3 2 3 2 0 5m5-4c-3 2 3 2 0 5"/>',
 leaf:'<path d="M19 3C8 3 2 8 5 17c9 5 16-3 14-14zM4 21 16 8m-6 8v-5m0 5h5"/>',
 pizza:'<path d="m4 20 4-16c5 0 9 3 12 8zM8 7c4 1 7 3 9 6"/><circle cx="10" cy="11" r="1"/><circle cx="9" cy="16" r="1"/>',
 pie:'<path d="M3 11h18l-3 8H6zM3 11c2-7 16-7 18 0M8 7l3 4m1-5 3 5m1-4 3 4"/>',
 cup:'<path d="M4 8h13v7a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5zM17 9c7-1 7 7 0 6M8 2v3m5-3v3"/>',
 meat:'<path d="M6 18c-7-5 0-17 8-14 8 2 10 10 3 13-4 1-7-2-11 1z"/><path d="M9 8c4-4 9 1 6 4-3 3-7-1-6-4z"/>',
 pasta:'<path d="M3 15h18c-1 4-4 6-9 6s-8-2-9-6zM6 14V6c0-4 4-4 4 0v7m1-1V5c0-4 4-4 4 0v8m1 0V8c0-4 4-4 4 0v5"/>',
 bottle:'<path d="M9 2h6v5l3 4v10H6V11l3-4zM9 5h6M7 13h10v5H7"/>'
};
function coastIcon(id){
 const key=id.replace('ss_','');
 const kind=({chef:'chef',pies:'pie',pizza:'pizza',salads:'leaf',tuna:'fish',rolls:'bowl',soups:'bowl',noodles:'pasta',rice:'bowl',shrimp:'fish',squid:'fish',oysters:'fish',chicken:'meat',meat:'meat',pasta:'pasta',veg:'leaf',sides:'bowl',coffee:'cup'})[key]||(key.includes('coffee')||key.includes('tea')?'cup':'bottle');
 return `<svg class="coast-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${COAST_ICONS[kind]}</svg>`;
}
// Strict near-viewport loading: total menu size does not determine initial downloads.
let menuPhotoObserver;
function observeMenuPhotos(){
 for(const id of ['ss_pies','ss_pizza']){const section=document.getElementById(id),note=section?.querySelector('.note');if(note)section.querySelector('.sh').appendChild(note);}

 if(menuPhotoObserver)menuPhotoObserver.disconnect();
 const images=document.querySelectorAll('#menu img[data-menu-src]');
 const load=img=>{img.src=img.dataset.menuSrc;delete img.dataset.menuSrc;};
 if(!('IntersectionObserver' in window)){images.forEach(load);return;}
 menuPhotoObserver=new IntersectionObserver(entries=>entries.forEach(entry=>{
  if(entry.isIntersecting){load(entry.target);menuPhotoObserver.unobserve(entry.target);}
 }),{rootMargin:'220px 0px'});
 images.forEach(img=>menuPhotoObserver.observe(img));
}
