"""Resolve self:Method calls inside dynamically named Lua functions by module context."""
from __future__ import annotations
import collections, json, re, sqlite3
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; DB=ROOT/'analysis_data/logic_index/stage2/lua_relations.sqlite3'; REPORT=ROOT/'analysis_output/logic_recovery/stage2'
CALL=re.compile(r'^\s*self\s*:\s*(?P<method>[A-Za-z_]\w*)')
INHERIT=re.compile(r'^\s*(?P<child>[A-Za-z_]\w*)\s*=\s*setmetatable\(\{\},\s*(?P<parent>[A-Za-z_]\w*)\)')
def main():
 d=sqlite3.connect(DB); d.execute('BEGIN IMMEDIATE')
 by=collections.defaultdict(list)
 class_methods=collections.defaultdict(list)
 parents={}
 for src in sorted((ROOT/'analysis_data/logic_index/lua/decoded').glob('*/decompiled.lua')):
  for line in src.read_text(encoding='utf-8',errors='replace').splitlines():
   m=INHERIT.match(line)
   if m: parents[m.group('child')]=m.group('parent')
 for fid,module,symbol in d.execute('SELECT id,module,symbol FROM functions'):
  if ':' in symbol:
   by[(module,symbol.rsplit(':',1)[-1])].append((fid,symbol))
   class_methods[(symbol.split(':',1)[0],symbol.rsplit(':',1)[-1])].append((fid,symbol))
 rows=d.execute("SELECT id,module,expression,target_candidates_json FROM relations WHERE target_function IS NULL AND kind='lua_self_call_candidate'").fetchall()
 unique=ambiguous=inherited=0
 for rid,module,expression,candidates_json in rows:
  m=CALL.match(expression)
  if not m: continue
  targets=by.get((module,m.group('method')),[])
  if len(targets)==1:
   d.execute("UPDATE relations SET target_function=?,certainty='candidate_unique_in_module',target_candidates_json=? WHERE id=?",(targets[0][0],json.dumps([targets[0][0]]),rid)); unique+=1
  elif len(targets)>1:
   d.execute("UPDATE relations SET certainty='ambiguous_in_module',target_candidates_json=? WHERE id=?",(json.dumps([x[0] for x in targets]),rid)); ambiguous+=1
  if not targets:
   owner=module.rsplit('.',1)[-1]; chain=[]; seen=set()
   while owner and owner not in seen:
    seen.add(owner); chain.append(owner); owner=parents.get(owner)
   inherited_targets=[]
   for cls in chain[1:]:
    inherited_targets.extend(class_methods.get((cls,m.group('method')),[]))
   inherited_targets=list({x[0]:x for x in inherited_targets}.values())
   if len(inherited_targets)==1:
    d.execute("UPDATE relations SET target_function=?,certainty='candidate_unique_inherited',target_candidates_json=? WHERE id=?",(inherited_targets[0][0],json.dumps([inherited_targets[0][0]]),rid)); inherited+=1
   elif len(inherited_targets)>1:
    d.execute("UPDATE relations SET certainty='ambiguous_inherited',target_candidates_json=? WHERE id=?",(json.dumps([x[0] for x in inherited_targets]),rid)); ambiguous+=1
 d.commit(); total=d.execute("SELECT count(*) FROM relations WHERE target_function IS NOT NULL AND certainty IN ('candidate_unique_in_module','candidate_unique_inherited')").fetchone()[0]; result={'eligible_unresolved':len(rows),'new_unique_edges':unique,'new_inherited_edges':inherited,'new_ambiguous_edges':ambiguous,'total_unique_edges':total,'database':str(DB.relative_to(ROOT)).replace('\\','/')}; (REPORT/'stage2_dynamic_self_call_fix_summary.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8'); d.close(); print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=='__main__': main()
