"""Keep downstream function candidates in one persistent cross-module inventory."""
import json,re
from reconcile_generator_logic import ROOT,OUT,sha
def main():
 records={};reports={}
 for filename in ('failure_downstream.json','persistence_review.json','reload_review.json','buff_lifecycle_review.json','activity_lifecycle_review.json','progress_lifecycle_review.json'):
  report=json.loads((OUT/filename).read_text(encoding='utf-8'));reports[filename]=sha(OUT/filename)
  sources=report.get('sources',[])+report.get('expanded_function_candidates',[])
  for record in sources:
   path=record['source'];p=ROOT/path;text=p.read_text(encoding='utf-8');lines=text.splitlines()
   # Named/nested candidates only: prototype mapping and anonymous body boundaries remain open.
   starts=[(i,m.group(1)) for i,line in enumerate(lines,1) if (m:=re.match(r'\s*function\s+([\w.:]+)\(',line))]
   for j,(line,ident) in enumerate(starts):
    key=f'{path}:{line}:{ident}'
    if key in records:records[key]['discovered_via'].append(filename);continue
    end=starts[j+1][0]-1 if j+1<len(starts) else len(lines)
    records[key]={'id':key,'source':path,'source_sha256':sha(p),'identifier':ident,'line':line,'candidate_end_line':end,'body_range_limit':'Next named start is an inventory boundary, not an AST function-body proof.','status':'待解决','relevance':'candidate_only; whole-module inclusion does not establish operation reachability','discovered_via':[filename]}
 result={'records':list(records.values()),'input_hashes':reports,'candidate_count':len(records),'status':'not_accepted','scope':'Expanded modules discovered through actual dependency tracing; review relevant functions and explicitly exclude unrelated functions. No denominator freeze or coverage percentage.'}
 (OUT/'downstream_inventory.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps({'downstream_function_candidates':len(records)}))
if __name__=='__main__':main()

