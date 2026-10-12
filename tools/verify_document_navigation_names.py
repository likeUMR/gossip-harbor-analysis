"""Validate the scoped naming pass without promoting logic recovery gates."""
from pathlib import Path
import json,re
import yaml
from bs4 import BeautifulSoup
from refine_document_navigation import ROOT,SITE,DOCS,AUDIT,paths

def main():
    report=json.loads((AUDIT/'naming_map.json').read_text(encoding='utf-8'))
    mapping={r['old']:r['new'] for r in report['names']}
    pattern=re.compile('|'.join(re.escape(x) for x in sorted(mapping,key=len,reverse=True)))
    rename=lambda s:pattern.sub(lambda m:mapping[m.group()],s)
    config=SITE/'mkdocs.yml'
    before=AUDIT/'before'/config.relative_to(ROOT)
    old=yaml.safe_load(before.read_text(encoding='utf-8'))['nav']
    new=yaml.safe_load(config.read_text(encoding='utf-8'))['nav']
    assert paths(old)==paths(new)
    assert old[0]==new[0]
    for relative in report['changed_files']:
        assert (ROOT/relative).read_text(encoding='utf-8')==rename((AUDIT/'before'/relative).read_text(encoding='utf-8')),relative
    checked=0
    for r in report['names']:
        folder=DOCS/'operations'/r['directory']
        for name,title in [('index',r['new']),('detail',r['new']+'：具体算法与配置')]:
            if not (folder/(name+'.md')).exists():continue
            rendered=SITE/'site'/'operations'/r['directory']
            if name=='detail':rendered/='detail'
            soup=BeautifulSoup((rendered/'index.html').read_text(encoding='utf-8'),'html.parser')
            assert soup.select_one('article h1').get_text(strip=True).rstrip('¶')==title,(r['directory'],name)
            checked+=1
    result={'status':'passed','renamed_nodes':len(report['names']),'rendered_titles':checked,'url_membership_and_order_preserved':True,'generator_navigation_preserved':True,'only_audited_name_substitutions':True,'limits':'Naming/rendering review only; existing logic recovery gate status retained.'}
    (AUDIT/'validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False))

if __name__=='__main__':main()
