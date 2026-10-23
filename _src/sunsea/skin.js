/* Sun&Sea-only navigation. Dish records and order keys stay in the shared engine. */
const COAST_ICONS={"chef": "M8 15c-5-1-5-7-1-8 0-5 8-5 9 0 5 0 6 7 1 8v5H8z M8 16h9", "pies": "M3 11h18l-3 8H6z M3 11c2-7 16-7 18 0 M8 7l3 4m1-5 3 5m1-4 3 4", "pizza": "m4 20 4-16c5 0 9 3 12 8z M8 7c4 1 7 3 9 6 M10 11h.1M9 16h.1", "salads": "M4 13h16c-1 5-4 8-8 8s-7-3-8-8z M6 12C1 5 9 2 11 9c0-8 10-8 8-1 M11 12l6-6", "tuna": "M17 8c-6-5-12-1-14 4 2 5 8 9 14 4l4 3V5z M6 11h.1 M10 7l2-4 3 4", "rolls": "m4 7 10-4 6 13-10 5z M4 7l6 14 M4 7l6 1 4-5 M7 8l6 11 M12 9l4 7", "soups": "M3 11h18c-1 6-4 9-9 9S4 17 3 11z M8 3c-3 2 3 3 0 5m6-6c-3 2 3 3 0 5", "noodles": "M3 14h18c-1 5-5 7-9 7s-8-2-9-7z M8 14V6c0-4 4-4 4 0v8 M15 14V4 M18 2l-2 12 M5 9h14", "rice": "M3 13h18c-1 5-4 8-9 8s-8-3-9-8z M5 12C3 8 8 5 10 7c0-4 5-4 6 0 4-1 6 3 3 5 M8 10l1-1m4 0 1 1m2-2 1 1", "shrimp": "M19 5c-2-3-10-3-14 3-4 7 3 15 10 12l-3-4c-5 2-7-3-4-6 2-3 6-3 8-1l3-4z M13 4l1 5m-5-4 2 5M5 8l4 4m-5 1 4 1 M19 5l3-3m-3 3 3 3 M16 7h.1", "squid": "M8 11C3 6 9 2 12 2s9 4 4 9l-4 2z M8 11c-6 3-5 8-2 9s4-2 3-5m3-2v9m3-10c7 3 6 8 3 8s-3-2-3-5", "oysters": "M12 20C-2 18 0 2 7 5c1-4 8-4 9 0 8-2 9 13-4 15z M12 17C4 15 5 8 9 9c3-6 10 2 3 8z", "chicken": "M10 15c-9-1-6-12 0-12 8-1 13 10 5 13l-4 3-3-2z M9 17l-3 4c-4 2-6-3-2-4l3-3", "meat": "M6 18c-7-5 0-17 8-14 8 2 10 10 3 13-4 1-7-2-11 1z M9 8c4-4 9 1 6 4-3 3-7-1-6-4z", "pasta": "M4 19 20 3 M9 3c-7 4 3 12 7 6M6 6c-4 5 7 11 9 7 M2 22l7-7 M9 17l3 3m2-5 3 3", "veg": "M18 3C8 3 3 8 5 17c9 5 16-3 13-14z M4 21 15 8m-5 8v-5m0 5h5", "sides": "M5 9h14l-2 12H7z M7 9V3h3v6m2 0V2h3v7m2 0V4h3v5 M10 13h4", "coffee": "M3 8h14v7a5 5 0 0 1-5 5H8a5 5 0 0 1-5-5z M17 9c7-1 7 7 0 6 M7 2v3m5-3v3", "juice": "M6 3h12l-2 18H8z M7 9h10 M13 9l3-8 M9 5h5", "tea": "M4 10h13v5a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5z M17 11c6-1 6 6 0 5 M10 8c-5-2-2-6 3-6 1 4 0 6-3 6z", "smoothie": "M6 7h12l-2 14H8z M5 7c0-6 14-6 14 0z M13 5l4-4 M9 11l6 5m0-5-6 5", "yogurt": "M6 9h12l-2 12H8z M7 9c-3-3 2-5 3-5-1-3 4-4 4-1 4 0 6 4 3 6 M9 14h6", "beer": "M4 6h12v15H4z M16 8h5v10h-5 M8 9v9m4-9v9 M4 6C1 1 7 1 8 3c2-4 7-2 6 1 4-2 5 3 2 2", "soft": "M5 5h14v16H5z M7 2h10 M5 7h14 M9 10l5 6m0-6-5 6", "souvenir": "M9 2h6v5l3 4v10H6V11l3-4z M9 5h6 M7 13h10v5H7"};
function coastIcon(id){
 const path=COAST_ICONS[id.replace('ss_','')]||COAST_ICONS.chef;
 return `<svg class="coast-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="${path}"/></svg>`;
}
// Strict near-viewport loading: total menu size does not determine initial downloads.
let menuPhotoObserver;
function observeMenuPhotos(){
 if(menuPhotoObserver)menuPhotoObserver.disconnect();
 const images=document.querySelectorAll('#menu img[data-menu-src]');
 const load=img=>{img.src=img.dataset.menuSrc;delete img.dataset.menuSrc;};
 if(!('IntersectionObserver' in window)){images.forEach(load);return;}
 menuPhotoObserver=new IntersectionObserver(entries=>entries.forEach(entry=>{
  if(entry.isIntersecting){load(entry.target);menuPhotoObserver.unobserve(entry.target);}
 }),{rootMargin:'220px 0px'});
 images.forEach(img=>menuPhotoObserver.observe(img));
}
