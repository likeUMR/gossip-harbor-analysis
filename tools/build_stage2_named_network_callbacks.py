"""Resolve named callback expressions from network/API calls to Lua functions."""
from __future__ import annotations
import collections, json, re, sqlite3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]; STAGE2=ROOT/"analysis_data"/"logic_index"/"stage2"; REPORT=ROOT/"analysis_output"/"logic_recovery"/"stage2"
METHOD_RE=re.compile(r"(?:^|[.:])([A-Za-z_]\w*)$")
CALLBACK_HINT_RE=re.compile(r"(?:callback|call_back|\bcb\b|onsuccess|onerror|onfail|oncomplete|handler|func)",re.I)
def main():
    out=STAGE2/"named_network_callbacks.sqlite3"
    if out.exists():out.unlink()
    db=sqlite3.connect(out); db.executescript("""PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;
    CREATE TABLE callbacks(id INTEGER PRIMARY KEY,module TEXT NOT NULL,source_path TEXT NOT NULL,request_line INTEGER NOT NULL,
      request_expression TEXT NOT NULL,callback_expression TEXT NOT NULL,target_candidates_json TEXT NOT NULL,
      certainty TEXT NOT NULL,target_function_symbol TEXT);
    CREATE TABLE effects(id INTEGER PRIMARY KEY,callback_id INTEGER NOT NULL,effect_kind TEXT NOT NULL,count INTEGER NOT NULL);
    CREATE INDEX callback_certainty ON callbacks(certainty); CREATE INDEX callback_target ON callbacks(target_function_symbol);""")
    net=sqlite3.connect(STAGE2/"network_calls.sqlite3"); lua=sqlite3.connect(STAGE2/"lua_relations.sqlite3"); ev=sqlite3.connect(STAGE2/"event_graph.sqlite3"); st=sqlite3.connect(STAGE2/"state_config_access.sqlite3")
    functions=collections.defaultdict(list)
    for row in lua.execute("SELECT id,module,symbol FROM functions"):
        functions[(row[1],row[2])].append(row[0])
    by_method=collections.defaultdict(list)
    for row in lua.execute("SELECT id,module,symbol FROM functions"):
        sym=row[2]; method=sym.rsplit(":",1)[-1].rsplit(".",1)[-1]
        by_method[(row[1],method)].append((row[0],sym))
    event_counts=collections.Counter((r[0],r[1],"event") for r in ev.execute("SELECT module,function_symbol,operation FROM event_sites"))
    state_counts=collections.Counter((r[0],r[1],"state") for r in st.execute("SELECT module,function_symbol,access_kind FROM access_sites"))
    counts=collections.Counter(); seen=set()
    for row in net.execute("SELECT module,source_path,line,request_expression,arguments_json FROM calls"):
        module,path,line,expr,args_json=row
        try: args=json.loads(args_json)
        except json.JSONDecodeError: continue
        for arg in args:
            arg=arg.strip()
            if not arg or arg.startswith("function"): continue
            match=METHOD_RE.search(arg)
            if not match: continue
            method=match.group(1)
            if not (arg.startswith("self.") or arg.startswith("self:") or CALLBACK_HINT_RE.search(arg) or method.lower().startswith("on")):
                continue
            candidates=by_method.get((module,method),[])
            certainty="candidate_unique" if len(candidates)==1 else ("ambiguous" if candidates else "unresolved")
            key=(module,path,line,arg)
            if key in seen: continue
            seen.add(key)
            target=candidates[0][1] if len(candidates)==1 else None
            cid=db.execute("INSERT INTO callbacks(module,source_path,request_line,request_expression,callback_expression,target_candidates_json,certainty,target_function_symbol) VALUES (?,?,?,?,?,?,?,?)",(module,path,line,expr,arg,json.dumps([x[0] for x in candidates]),certainty,target)).lastrowid
            counts[certainty]+=1
            if target:
                ec=event_counts.get((module,target,"event"),0); sc=state_counts.get((module,target,"state"),0)
                if ec: db.execute("INSERT INTO effects(callback_id,effect_kind,count) VALUES (?,?,?)",(cid,"event",ec))
                if sc: db.execute("INSERT INTO effects(callback_id,effect_kind,count) VALUES (?,?,?)",(cid,"state",sc))
    db.commit()
    result={"title":"阶段二命名网络回调索引","callback_expressions":db.execute("SELECT count(*) FROM callbacks").fetchone()[0],"by_certainty":dict(counts),"unique_callbacks_with_event_or_state_effect":db.execute("SELECT count(DISTINCT callback_id) FROM effects").fetchone()[0],"effect_rows":db.execute("SELECT count(*) FROM effects").fetchone()[0],"database":str(out.relative_to(ROOT)).replace("\\","/"),"limitations":["参数中所有末端方法表达式都作为候选扫描，部分可能是普通请求参数而非回调；原始参数和候选列表均保留。","唯一方法名不等于运行时唯一对象；继承、动态赋值和跨语言回调仍需场景验证。"]}
    (REPORT/"stage2_named_network_callbacks_summary.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    for x in (net,lua,ev,st):x.close()
    db.close();print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=="__main__":main()
