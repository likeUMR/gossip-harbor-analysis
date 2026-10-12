"""Pin evidence for reviewed rules, without certifying whole functions or closure."""
from pathlib import Path
import hashlib
import json
import re
from stage3_generator_rule_repairs import BODIES as CORE_BODIES, CASES as CORE_CASES
from stage3_generator_deep_repairs import BODIES as DEEP_BODIES, CASES as DEEP_CASES
from stage3_generator_source_links import SOURCES, PAGES

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'analysis_output/logic_recovery/stage3/generator_gate_audit'
DOCS=ROOT/'analysis_output/logic_recovery/stage3/mkdocs_site/docs'

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    tests=json.loads((OUT/'source_rule_tests.json').read_text(encoding='utf-8'))
    rules=[]
    for rel in dict.fromkeys([*CORE_BODIES,*DEEP_BODIES,*CORE_CASES,*DEEP_CASES]):
        page=DOCS/'operations/generator'/rel
        text=page.read_text(encoding='utf-8')
        config=re.findall(r'<!-- generator-configs:start -->.*?<!-- generator-configs:end -->',text,re.S)
        rules.append({'page':page.relative_to(DOCS).as_posix(),'page_sha256':sha(page),
          'review_scope':'Selected source rules and examples; NOT full function/branch approval or complete event closure.',
          'status':'selected_rules_reviewed',
          'sections':re.findall(r'^## (.+)$',text,re.M),
          'source_files':[{'name':name,'source':SOURCES[name].relative_to(ROOT).as_posix(),'sha256':sha(SOURCES[name])} for name in PAGES.get(rel,[])],
          'preserved_config_block_sha256':[hashlib.sha256(c.encode()).hexdigest() for c in config]})
    payload={'status':'partial_review_not_acceptance','reviewed_rule_pages':rules,
             'source_execution_evidence':{'path':'source_rule_tests.json','sha256':sha(OUT/'source_rule_tests.json'),
               'passed':tests['passed'],'total':tests['total'],'ids':[c['id'] for c in tests['cases']],
               'original_runtime_confirmed':False},
             'original_runtime_boundary':'User confirmed on 2026-10-12: only installation package and extracted resources; no original client/account traces provided.',
             'remaining_gates':'Prototype mapping, complete event/call closure, per-branch state/config/doc review and original-client differences remain open.'}
    OUT.mkdir(exist_ok=True)
    (OUT/'reviewed_rules.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'reviewed_rule_pages':len(rules),'source_tests':f"{tests['passed']}/{tests['total']}",'acceptance':False}))

if __name__=='__main__': main()
