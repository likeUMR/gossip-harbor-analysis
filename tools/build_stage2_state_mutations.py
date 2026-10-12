"""Index direct Lua object/table state mutations that API-based state scans miss."""
from __future__ import annotations
import bisect, hashlib, json, re, sqlite3
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; LUA=ROOT/'analysis_data/logic_index/lua/decoded'; OUT=ROOT/'analysis_data/logic_index/stage2'; REP=ROOT/'analysis_output/logic_recovery/stage2'
FN=re.compile(r'^\s*(?:local\s+)?function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(',re.M)
ASSIGN=re.compile(r'(?P<target>(?:self|GM|getmetatable\(self\)|[A-Za-z_]\w*)\.[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*=\s*(?P<value>[^\r\n]+)')
TABLE_ASSIGN=re.compile(r'(?P<target>[A-Za-z_]\w*)\s*=\s*\{')
def stable(*x): return hashlib.sha256('\0'.join(map(str,x)).encode()).hexdigest()
def main():
 out=OUT/'state_mutations.sqlite3'
 if out.exists(): out.unlink()
 d=sqlite3.connect(out); d.executescript('''CREATE TABLE mutations(id TEXT PRIMARY KEY,module TEXT,source_path TEXT,line INTEGER,function_symbol TEXT,target_expression TEXT,value_expression TEXT,mutation_kind TEXT,code_excerpt TEXT); CREATE INDEX mutation_function ON mutations(source_path,function_symbol); CREATE INDEX mutation_target ON mutations(target_expression);''')
 rows=[]
 for src in sorted(LUA.glob('*/decompiled.lua')):
  text=src.read_text(encoding='utf-8',errors='replace'); lines=text.splitlines(); defs=[(m.start(),m.group(1)) for m in FN.finditer(text)]
  starts=[0]
  for m in re.finditer('\n',text): starts.append(m.end())
  for m in ASSIGN.finditer(text):
   # Ignore comments and likely local declarations; preserve source evidence.
   line=bisect.bisect_right(starts,m.start()); excerpt=lines[line-1] if line<=len(lines) else ''
   if excerpt.lstrip().startswith('--') or not m.group('target').startswith(('self.','GM.','getmetatable(self).')): continue
   prev=[x for x in defs if x[0]<=m.start()]; fn=prev[-1][1] if prev else None
   kind='object_field_assignment' if m.group('target').startswith(('self.','getmetatable(self).')) else 'global_model_assignment'
   rows.append((stable(src,m.start()),src.parent.name,str(src),line,fn,m.group('target'),m.group('value').strip(),kind,excerpt))
 d.executemany('INSERT INTO mutations VALUES(?,?,?,?,?,?,?,?,?)',rows); d.commit(); summary={'mutations':len(rows),'self_mutations':d.execute("select count(*) from mutations where mutation_kind='object_field_assignment'").fetchone()[0],'global_model_mutations':d.execute("select count(*) from mutations where mutation_kind='global_model_assignment'").fetchone()[0],'database':str(out.relative_to(ROOT)).replace('\\','/')}; (REP/'stage2_state_mutations_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8'); d.close(); print(json.dumps(summary,ensure_ascii=False,indent=2))
if __name__=='__main__': main()
