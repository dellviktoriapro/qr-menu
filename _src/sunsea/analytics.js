/* No personal text, capability URLs, recordings or purchase/revenue events. */
{
 const counter=113805286;
 const safe=new URL(location.href);
 const table=safe.searchParams.get('t');
 safe.search='';safe.hash='';
 if(/^\d{1,2}$/.test(table||''))safe.searchParams.set('t',table);
 history.replaceState(history.state,'',safe.href);
 const ref=(()=>{try{return new URL(document.referrer).origin+'/'}catch{return ''}})();
 window.ym=window.ym||function(){(window.ym.a=window.ym.a||[]).push(arguments)};
 window.ym.l=Date.now();
 window.ym(counter,'init',{url:safe.href,referrer:ref,webvisor:false,clickmap:false,trackLinks:false,accurateTrackBounce:true});
 const script=document.createElement('script');script.async=true;script.src='https://mc.yandex.ru/metrika/tag.js?id='+counter;script.referrerPolicy='no-referrer';document.head.appendChild(script);
 function goal(name,params={}){try{window.ym(counter,'reachGoal',name,{...params,language:lang||'unknown',...(table?{table:Number(table)}:{})})}catch{}}
 const previousBump=bump;
 bump=function(key,delta,...args){const before=allTotals().n;const result=previousBump(key,delta,...args);if(delta>0&&allTotals().n>before)goal('add_to_cart',{category:String(key).split('|')[0],quantity:allTotals().n-before});return result};
 const previousShow=sendOrder;
 sendOrder=openPick=function(...args){const alreadyOpen=!document.getElementById('waiterView').hidden;const result=previousShow(...args);const x=allTotals();if(!alreadyOpen&&!document.getElementById('waiterView').hidden&&x.n)goal('waiter_view_opened',{amount_vnd:x.sum,item_count:x.n,unpriced_items:x.extra||0,currency:'VND'});return result};
}
