
function bindConfigTables(){document.querySelectorAll('.config-block').forEach(function(block){
 const input=block.querySelector('input');if(!input||input.dataset.bound)return;input.dataset.bound='1';
 const rows=Array.from(block.querySelectorAll('tbody tr'));const count=block.querySelector('.config-count');
 function filter(){const q=input.value.trim().toLowerCase();let visible=0;rows.forEach(function(row){
 row.hidden=!row.textContent.toLowerCase().includes(q);if(!row.hidden)visible++;});
 count.textContent='显示 '+visible+' / '+rows.length+' 条配置';}input.addEventListener('input',filter);filter();});}
if(typeof document$!=='undefined'){document$.subscribe(bindConfigTables);}else{bindConfigTables();}
