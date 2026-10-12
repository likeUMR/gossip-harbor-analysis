"""Resolve callback variables assigned to named Lua methods before API calls."""
from __future__ import annotations
import collections, json, re, sqlite3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]; INDEX=ROOT/"analysis_data"/"logic_index"; STAGE2=INDEX/"stage2"; REPORT=ROOT/"analysis_output"/"logic_recovery"/"stage2"
FUNC_RE=re.compile(r"^\s*(?:local\s+)?function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(",re.M)
ASSIGN_RE=re.compile(r"^\s*(?:local\s+)?([A-Za-z_]\w*)\s*=\s*((?:self|[A-Za-z_]\w*)\s*[:.]\s*[A-Za-z_]\w*|[A-Za-z_]\w*)\s*$",re.M)
def mask(s):
    out=list(s);i=0;n=len(s);q=None
    while i<n:
        if q:
            if s[i]=="\\":out[i]=" ";i+=1;out[i]=" " if i<n else out[i]
            elif s[i]==q:out[i]=" ";i+=1;q=None
            else:
                if s[i] not in "\r\n":out[i]=" "
                i+=1
        elif s.startswith("--",i):
            j=s.find("\n",i+2);j=n if j<0 else j
            for k in range(i,j):out[k]=" "
            i=j
        elif s[i] in "'\"":q=s[i];out[i]=" ";i+=1
        else:i+=1
    return "".join(out)
def main():
    out=STAGE2/"callback_assignments.sqlite3"
    if out.exists():out.unlink()
    db=sqlite3.connect(out);db.executescript("""PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;
    CREATE TABLE assignments(id INTEGER PRIMARY KEY,module TEXT NOT NULL,function_symbol TEXT,variable TEXT NOT NULL,
      rhs TEXT NOT NULL,line INTEGER NOT NULL);
    CREATE TABLE resolved_calls(id INTEGER PRIMARY KEY,module TEXT NOT NULL,source_path TEXT NOT NULL,line INTEGER NOT NULL,
      request_expression TEXT NOT NULL,argument TEXT NOT NULL,rhs TEXT NOT NULL,target_candidates_json TEXT NOT NULL,certainty TEXT NOT NULL);
    CREATE INDEX assign_key ON assignments(module,function_symbol,variable);""")
    modules=json.loads((INDEX/"lua_modules.json").read_text(encoding="utf-8")); assigns=collections.defaultdict(list); method_map=collections.defaultdict(list)
    for mod in modules:
        path=ROOT/mod.get("source_path","")
        if not path.is_file():continue
        try:s=path.read_text(encoding="utf-8")
        except (OSError,UnicodeError):continue
        m=mask(s); defs=[(x.start(),x.group(1)) for x in FUNC_RE.finditer(m)]
        for x in ASSIGN_RE.finditer(m):
            owner=None
            for pos,sym in defs:
                if pos<=x.start():owner=sym
                else:break
            rhs=x.group(2).replace(" ",""); row=(mod.get("name",""),owner,x.group(1),rhs,s.count("\n",0,x.start())+1)
            assigns[(row[0],owner,row[2])].append(row)
            if ":" in rhs or "." in rhs:
                method=rhs.rsplit(":",1)[-1].rsplit(".",1)[-1];method_map[(row[0],method)].append(rhs)
            db.execute("INSERT INTO assignments(module,function_symbol,variable,rhs,line) VALUES (?,?,?,?,?)",row[0],row[1],row[2],row[3],row[4]) if False else None
    # Reinsert with explicit parameters to keep sqlite binding readable.
    for rows in assigns.values():
        for row in rows: db.execute("INSERT INTO assignments(module,function_symbol,variable,rhs,line) VALUES (?,?,?,?,?)",row)
    net=sqlite3.connect(STAGE2/"network_calls.sqlite3"); counts=collections.Counter()
    for row in net.execute("SELECT module,source_path,line,function_symbol,request_expression,arguments_json FROM calls"):
        module,path,line,owner,expr,args_json=row
        try:args=json.loads(args_json)
        except json.JSONDecodeError:continue
        for arg in args:
            arg=arg.strip()
            if not re.fullmatch(r"[A-Za-z_]\w*",arg):continue
            rhs_rows=assigns.get((module,owner,arg),[])
            if not rhs_rows:continue
            rhs=rhs_rows[-1][3];method=rhs.rsplit(":",1)[-1].rsplit(".",1)[-1]
            candidates=method_map.get((module,method),[])
            certainty="candidate_unique" if len(candidates)==1 else ("ambiguous" if candidates else "unresolved")
            db.execute("INSERT INTO resolved_calls(module,source_path,line,request_expression,argument,rhs,target_candidates_json,certainty) VALUES (?,?,?,?,?,?,?,?)",(module,path,line,expr,arg,rhs,json.dumps(candidates),certainty))
            counts[certainty]+=1
    db.commit();result={"title":"阶段二回调变量赋值传播","assignment_rows":db.execute("SELECT count(*) FROM assignments").fetchone()[0],"resolved_call_arguments":db.execute("SELECT count(*) FROM resolved_calls").fetchone()[0],"by_certainty":dict(counts),"database":str(out.relative_to(ROOT)).replace("\\","/"),"limitations":["仅传播同一模块、同一命名函数内的简单变量赋值；表字段、闭包捕获、跨函数返回值和动态赋值仍需 AST 数据流分析。"]}
    (REPORT/"stage2_callback_assignments_summary.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8");net.close();db.close();print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=="__main__":main()
