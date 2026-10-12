"""Documentary example review; never promotes semantic/runtime recovery gates."""
from pathlib import Path
import json, re
from urllib.parse import unquote, urlsplit
from bs4 import BeautifulSoup
from revise_operation_examples import ROOT,SITE,DOCS,AUDIT,prefix,CASES

def execute_selected_examples():
    import verify_order_source_rules as original
    from lupa.lua53 import LuaRuntime
    from stage3_merge_documents import BY_NAME,source
    setup=r'''GM.ItemDataModel={GetChainId=function() return '2' end,GetChainLevel=function(_,code) return tonumber(code)-200 end,GetTypeByChainAndLevel=function(_,chain,level) return tostring(200+level) end};cfg={['209']={DiffScore=146},['208']={DiffScore=78},['207']={DiffScore=39},['206']={DiffScore=19},['205']={DiffScore=10}}'''
    tests={
      'chest_budget_5_cost_3':r'''local m=setmetatable({},ChestCustomerModel);local r,c=m:FindNormalRewardConfig(5,{rewards={{type='203',count=3}}},'');assert(#r==2 and r[1].type=='203' and r[2].type=='203' and c==6)''',
      'chest_old_budget_30_cost_19':setup+r'''local out={};local left=RandomGenerateCodeHelper._PickItems_old({code='209'},cfg,30,out,nil,0,'');assert(left==-8 and #out==2 and out[1]=='206' and out[2]=='206')''',
      'chest_new_lack_16':setup+r'''local out={};local lack={['209']=16};local left=RandomGenerateCodeHelper._PickItems_new({code='209'},cfg,30,out,nil,0,'',lack);assert(left==11 and #out==1 and out[1]=='206' and lack['209']==-16)''',
      'temp_new_inventory_202':r'''GM.ItemDataModel={GetChain=function() return {'201','202','203','204'} end};local m=setmetatable({},TempItemModel);local d=m:_GetLevelOneCountDiffs('2',{['202']=1});assert(d[1]==1 and d[2]==0 and d[3]==2 and d[4]==6)''',
    }
    rows=[]
    modules=original.NAMES+['TempItem.Model.TempItemModel']
    for mode in ('bytecode','recovered-source'):
        for name,body in tests.items():
            lua=LuaRuntime();lua.execute(original.SETUP)
            try:
                for module in modules:
                    m=BY_NAME[module];lua.execute((ROOT/m['standard_path']).read_bytes() if mode=='bytecode' else source(module).read_text(encoding='utf-8'))
                lua.execute(body);rows.append(dict(case=name,mode=mode,status='passed'))
            except Exception as exc:rows.append(dict(case=name,mode=mode,status='failed',error=str(exc)))
    return rows

def run():
    ledger=json.loads((AUDIT/'scenario_ledger.json').read_text(encoding='utf-8'))
    # A subsequent audited naming pass may update titles, without altering examples or rules.
    naming=ROOT/'analysis_output/logic_recovery/stage3/navigation_naming_audit/naming_map.json'
    replacements={row['old']:row['new'] for row in json.loads(naming.read_text(encoding='utf-8'))['names']} if naming.exists() else {}
    naming_pattern=re.compile('|'.join(re.escape(old) for old in sorted(replacements,key=len,reverse=True))) if replacements else None
    def renamed_original(text):return naming_pattern.sub(lambda m:replacements[m.group()],text) if naming_pattern else text
    failures=[];records=[]
    for record in ledger['pages_index']:
        md=SITE/record['page'];relative=md.relative_to(DOCS/'operations')
        original=AUDIT/'before'/relative
        text=md.read_text(encoding='utf-8')
        if prefix(text)!=renamed_original(prefix(original.read_text(encoding='utf-8'))):failures.append([str(relative),'body changed beyond audited names'])
        output=SITE/'site'/md.relative_to(DOCS).parent
        if md.stem!='index':output/=md.stem
        output/='index.html'
        soup=BeautifulSoup(output.read_text(encoding='utf-8'),'html.parser');article=soup.select_one('article')
        heading=next((h for h in article.select('h2') if h.get_text(strip=True)=='演示案例'),None)
        if not heading:failures.append([str(relative),'unrendered example heading']);continue
        # Inspect only new examples; old evidence/downloads are outside this change.
        tail=[]
        for sibling in heading.next_siblings:
            if getattr(sibling,'get_text',None):tail.append(sibling.get_text(' ',strip=True))
        rendered=' '.join(tail)
        expected=[c for k in record['mechanisms'] for c in CASES[k]]
        for c in expected:
            if c['title'] not in rendered or c['result'] not in rendered:failures.append([str(relative),'missing scene/result',c['title']])
            if md.stem=='detail' and c['calculation'] not in rendered:failures.append([str(relative),'missing calculation',c['title']])
            if md.stem!='detail' and c['context'] not in rendered:failures.append([str(relative),'missing qualitative context',c['title']])
        if article.select('pre') and '演示案例' in ''.join(p.get_text() for p in article.select('pre')):failures.append([str(relative),'case rendered as code'])
        for image in article.select('img[src]'):
            src=urlsplit(image['src'])
            if src.scheme:continue
            target=output.parent/unquote(src.path)
            if not target.exists():failures.append([str(relative),'broken image',image['src']])
        records.append(dict(page=str(relative),scenarios=len(expected),url='http://127.0.0.1:8000/'+str(output.parent.relative_to(SITE/'site')).replace('\\','/')+'/#'+heading.get('id','')))
    # Independently recompute selected multi-step arithmetic and finite pool trajectories.
    arithmetic={
        'ordinary_order':(2+2+4,2+2+5,100+8)==(8,9,108),
        'gold_buff':(2+2+4)*2==16,
        'bubble_three_corrections':40*.5*(.5**2)*.8==4,
        'bubble_floor':max(3*.5*(.5**2)*.8,1)==1,
        'temp_new_equivalent_stock':[2**(level-1)-(2 if level>=2 else 0) for level in range(1,5)]==[1,0,2,6],
        'candidate_multipliers':[100*100,100*1000,100*10000*10**2]==[10000,100000,100000000],
        'energy_bubble_timer':1000+5*60==1300,
        'return_timer':29800-1000==8*3600,
        'chest_budget':5-3-3==-1,
    }
    pool=[['2402',2],['2405',1],['2502',2],['2503',1]];draw=[]
    for ticket in [1,2,2,3,1,1]:
        for item in pool:
            if ticket<=item[1]:draw.append(item[0]);item[1]-=1;break
            ticket-=item[1]
    arithmetic['finite_branch_pool']=draw==['2402','2405','2502','2503','2402','2502'] and sum(n for _,n in pool)==0
    if not all(arithmetic.values()):failures.append(['arithmetic',arithmetic])
    executed=execute_selected_examples()
    failures.extend([r for r in executed if r['status']=='failed'])
    report=dict(status='passed' if not failures else 'failed',pages=len(records),mechanisms=ledger['mechanisms'],scenarios=ledger['scenarios'],arithmetic_checks=arithmetic,executed_example_rules=executed,failures=failures,records=records,limits='Page/result presence, preserved specifications, assets, selected arithmetic and four selected rules against original converted bytecode and recovered source with controlled dependencies. Does not assert all internal subbranches covered or G1–G7 passed.')
    (AUDIT/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({k:report[k] for k in ('status','pages','mechanisms','scenarios','arithmetic_checks','failures')},ensure_ascii=False))
    if failures:raise SystemExit(1)

if __name__=='__main__':run()
