// The direction is a full visual language, not just a fixed accent colour.
const THEMES=[
 {id:'atelier',letter:'А',name:'Лазурная терраса',note:'Молочный камень, пыльный синий и спокойная терракота. Светлый рабочий кабинет с ощущением моря.',colors:['#243A4D','#86A7B8','#C96E53','#F0DFCC'],vars:{signal:'#B85D43',signalInk:'#FFF8EF',signalText:'#B85D43',navBlue:'#6C92A6',frame:'#243A4D',frameInk:'#FFF8EF',block1:'#86A7B8',block1Ink:'#173442',block2:'#C96E53',block2Ink:'#FFF8EF',block3:'#F0DFCC',block3Ink:'#243A4D',block4:'#D7A379',block4Ink:'#33241E',ground:'#DCE9E8',surface:'#F8F2E9',raised:'#FFFDFC',ink:'#243A4D',muted:'#405D69',line:'#BFCFCE',accent:'#C96E53',accentInk:'#FFF8EF',secondary:'#6C92A6',soft:'#E8F0EC'}},
 {id:'pine',letter:'Б',name:'Ночной сад',note:'Глубокая зелень, дымчатый нефрит и тёплая шампань. Собранный тёмный режим для длинной смены.',colors:['#101A17','#6D8D7B','#D3B47A','#F4E8D8'],vars:{signal:'#C58E67',signalInk:'#211B15',signalText:'#DAB08B',navBlue:'#8EAC9A',frame:'#14251E',frameInk:'#F4E8D8',block1:'#6D8D7B',block1Ink:'#10251B',block2:'#D3B47A',block2Ink:'#282016',block3:'#27382F',block3Ink:'#F4E8D8',block4:'#9E7E62',block4Ink:'#FFF8EF',ground:'#101A17',surface:'#1A2922',raised:'#24372D',ink:'#F4E8D8',muted:'#C3D1C4',line:'#395647',accent:'#D3B47A',accentInk:'#282016',secondary:'#8EAC9A',soft:'#203229'}},
 {id:'wine',letter:'В',name:'Бархатное бордо',note:'Винный фон, пудровая роза и ледяной голубой. Выразительный вечерний вариант без яркой рыжины.',colors:['#2B1A23','#642C47','#DB8798','#B9D4E6'],vars:{signal:'#DB8798',signalInk:'#351E2A',signalText:'#E7A8B6',navBlue:'#B9D4E6',frame:'#2B1A23',frameInk:'#F9E8DE',block1:'#642C47',block1Ink:'#FFF7F0',block2:'#DB8798',block2Ink:'#351E2A',block3:'#B9D4E6',block3Ink:'#263447',block4:'#7A556B',block4Ink:'#FFF7F0',ground:'#241720',surface:'#33202B',raised:'#452C3A',ink:'#F9E8DE',muted:'#DEC9D2',line:'#624052',accent:'#DB8798',accentInk:'#351E2A',secondary:'#B9D4E6',soft:'#3B2632'}}
];
const terrace=THEMES.find(t=>t.id==='atelier');
terrace.vars.signal='#A74C37';
terrace.vars.signalInk='#FFF8EF';
terrace.vars.signalText='#A74C37';
terrace.vars.block2Ink='#101E28';
terrace.vars.accentInk='#101E28';
const orchard=THEMES.find(t=>t.id==='pine');
orchard.vars.block1Ink='#0C1D14';
orchard.vars.block4Ink='#211B15';
function applyTheme(id){const theme=THEMES.find(t=>t.id===id)||THEMES[0];Object.entries(theme.vars).forEach(([k,v])=>document.documentElement.style.setProperty('--'+k,v));document.documentElement.dataset.palette=theme.id;return theme}
