"""Resolve original named prototypes using Lua debug metadata, not source order."""
import json
from lupa.lua53 import LuaRuntime
from reconcile_generator_logic import ROOT,OUT,sha
from build_stage3_function_audit import source_functions

def main():
 modules=json.loads((ROOT/'analysis_data/logic_index/lua_modules.json').read_text(encoding='utf-8'))
 protos=json.loads((ROOT/'analysis_data/logic_index/lua_functions.json').read_text(encoding='utf-8'))
 sources=source_functions();rows=[];unmapped=[]
 for table,module in [('ItemSpread','Board.Model.Item.ItemSpread'),('LuckyProduceModel','LuckyProduce.Model.LuckyProduceModel')]:
  # Resolve the Lucky module by source content hash if its namespace differs.
  records=[r for r in sources if r['module']==table]
  source=ROOT/records[0]['path']
  candidates=[m for m in modules if m['name']==module or (table=='LuckyProduceModel' and m['sha256']==source.stem)]
  assert len(candidates)==1,(table,len(candidates))
  m=candidates[0];original=ROOT/m['standard_path'];group=[p for p in protos if p['module_sha256']==m['sha256']]
  runtime=LuaRuntime();runtime.execute(original.read_bytes())
  recovered=LuaRuntime();recovered.execute(source.read_text(encoding='utf-8'))
  inspect=runtime.eval("function(f) local i=debug.getinfo(f,'Su');return i.linedefined,i.lastlinedefined,i.nparams,i.isvararg end")
  inspect_source=recovered.eval("function(f) local i=debug.getinfo(f,'Su');return i.linedefined,i.lastlinedefined,i.nparams,i.isvararg end")
  used=set()
  for r in records:
   name=r['identifier'].split(':')[-1].split('.')[-1]
   info=inspect(runtime.globals()[table][name]);restored=inspect_source(recovered.globals()[table][name])
   matches=[p for p in group if (p['first_line'],p['last_line'],p['parameters'],p['vararg'])==info]
   assert len(matches)==1,(r['identifier'],info,len(matches))
   assert restored[0]==r['line'],(r['identifier'],restored,r['line'])
   p=matches[0];assert p['prototype'] not in used;used.add(p['prototype'])
   rows.append(dict(identifier=r['identifier'],module=table,original_module=m['name'],original_sha256=sha(original),prototype=p['prototype'],prototype_offset=p['offset'],original_first_line=info[0],original_last_line=info[1],source=r['path'],source_sha256=sha(source),recovered_first_line=restored[0],recovered_last_line=restored[1],parameters=info[2],vararg=info[3],status='structurally_mapped_not_semantically_approved'))
  for p in group:
   if p['prototype'] not in used:unmapped.append(dict(module=table,prototype=p['prototype'],first_line=p['first_line'],last_line=p['last_line'],strings=p['strings'],status='待解决',reason='Root module or anonymous/nested function; requires explicit body and closure mapping.'))
 result={'named_mappings':rows,'remaining_prototypes':unmapped,'counts':{'mapped_named_functions':len(rows),'remaining_prototypes':len(unmapped)},'scope':'Original Lua function metadata uniquely matches indexed prototype; recovered function metadata matches source start. This verifies structural identity, not semantic equivalence or operation closure.'}
 OUT.mkdir(parents=True,exist_ok=True);(OUT/'prototype_mapping.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps(result['counts']))
if __name__=='__main__':main()
