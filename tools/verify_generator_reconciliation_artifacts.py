"""Check exact supplemented detail pages and recorded source/document hashes."""
import json
from bs4 import BeautifulSoup
from reconcile_generator_logic import ROOT,OUT,DOCS,sha
from reconcile_generator_failure_downstream import BODIES
from reconcile_generator_persistence import BODIES as PERSISTENCE_BODIES
from reconcile_generator_reload import BODIES as RELOAD_BODIES
from reconcile_generator_buff_lifecycle import BODIES as BUFF_BODIES
from reconcile_generator_activity_lifecycle import BODY as ACTIVITY_BODY
def main():
 ledger=json.loads((OUT/'ledger.json').read_text(encoding='utf-8'))
 checks=[]
 for row in ledger['functions']:
  assert sha(ROOT/row['path'])==row['source_sha256']
  for unit in row['reviewed_units']:
   assert sha(DOCS/unit['document'])==unit['document_sha256']
 for rel,body in {**BODIES,**PERSISTENCE_BODIES,**RELOAD_BODIES,**BUFF_BODIES,'lifecycle/cooldown/detail.md':ACTIVITY_BODY}.items():
  rendered=DOCS.parent/'site/operations/generator'/rel.removesuffix('.md')/'index.html'
  article=BeautifulSoup(rendered.read_text(encoding='utf-8'),'html.parser').select_one('article')
  expected=body.splitlines()[0].removeprefix('## ')
  assert any(h.get_text(strip=True).rstrip('¶')==expected for h in article.select('h2')),rel
  assert not any(expected in p.get_text() for p in article.select('pre')),rel
  checks.append({'page':rel,'rendered_heading':expected,'supplement_not_in_code_block':True})
 result={'status':'passed','pages':checks,'source_and_document_hashes_current':True,'scope':'Exact supplemented detail pages and evidence freshness only; no full semantic acceptance.'}
 (OUT/'render_validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps({'status':'passed','pages':len(checks)}))
if __name__=='__main__':main()

