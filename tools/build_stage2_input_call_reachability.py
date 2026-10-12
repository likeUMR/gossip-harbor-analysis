"""Expand input functions through resolved Lua call candidates and collect downstream evidence."""
from __future__ import annotations
import collections, json, os, sqlite3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
STAGE2=ROOT/"analysis_data"/"logic_index"/"stage2"
REPORT=ROOT/"analysis_output"/"logic_recovery"/"stage2"
MAX_DEPTH=int(os.environ.get("STAGE2_MAX_DEPTH", "12"))

def main():
    out=STAGE2/"input_call_reachability.sqlite3"
    if out.exists(): out.unlink()
    db=sqlite3.connect(out)
    db.executescript("""PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;
    CREATE TABLE roots(id INTEGER PRIMARY KEY,module TEXT NOT NULL,function_symbol TEXT NOT NULL,entry_kinds TEXT NOT NULL);
    CREATE TABLE reachable(root_id INTEGER NOT NULL,function_id TEXT NOT NULL,function_symbol TEXT NOT NULL,depth INTEGER NOT NULL,path_json TEXT NOT NULL,has_event INTEGER NOT NULL,has_state INTEGER NOT NULL);
    CREATE INDEX reachable_root ON reachable(root_id,depth);
    CREATE INDEX reachable_symbol ON reachable(function_symbol);
    """)
    inp=sqlite3.connect(STAGE2/"input_entries.sqlite3")
    lua=sqlite3.connect(STAGE2/"lua_relations.sqlite3")
    ev=sqlite3.connect(STAGE2/"event_graph.sqlite3")
    st=sqlite3.connect(STAGE2/"state_config_access.sqlite3")
    functions={row[0]:(row[1],row[2]) for row in lua.execute("SELECT id,module,symbol FROM functions")}
    function_paths={row[0]:row[3] for row in lua.execute("SELECT id,module,symbol,source_path FROM functions")}
    ids_by_path_symbol=collections.defaultdict(list)
    for fid,src_path in function_paths.items(): ids_by_path_symbol[(str((ROOT/src_path).resolve()).casefold(),functions[fid][1])].append(fid)
    ids_by_key=collections.defaultdict(list)
    for fid,(module,symbol) in functions.items(): ids_by_key[(module,symbol)].append(fid)
    graph=collections.defaultdict(set)
    for source,target,certainty in lua.execute("SELECT source_function,target_function,certainty FROM relations WHERE source_function IS NOT NULL AND target_function IS NOT NULL"):
        if certainty not in ("candidate_unique_symbol","candidate_unique_in_module","candidate_unique_inherited","confirmed"): continue
        if source in functions and target in functions: graph[source].add(target)
    # Add unique dynamic object-field forwarding edges. These are kept out of
    # the ordinary Lua relation table because receiver object identity is still
    # a candidate, but a unique method-name target is useful for coverage.
    forwarding=sqlite3.connect(STAGE2/"dynamic_forwarding.sqlite3")
    method_targets=collections.defaultdict(list)
    for fid,(module,symbol) in functions.items():
        if ':' in symbol: method_targets[symbol.rsplit(':',1)[-1]].append(fid)
    for module,path,symbol,line,receiver,method in forwarding.execute("SELECT module,source_path,function_symbol,line,receiver,method FROM calls"):
        source_ids=ids_by_path_symbol.get((str(Path(path).resolve()).casefold(),symbol),[])
        targets=method_targets.get(method,[])
        if len(source_ids)==1 and len(targets)==1: graph[source_ids[0]].add(targets[0])
    forwarding.close()
    event_keys={(row[0],row[1]) for row in ev.execute("SELECT module,function_symbol FROM event_sites")}
    state_keys={(row[0],row[1]) for row in st.execute("SELECT module,function_symbol FROM access_sites")}
    roots={}
    for module,symbol,kind in inp.execute("SELECT module,function_symbol,entry_kind FROM entries WHERE function_symbol IS NOT NULL"):
        if (module,symbol) not in roots: roots[(module,symbol)]=set()
        roots[(module,symbol)].add(kind)
    root_count=0; rows=0; depth_counts=collections.Counter(); evidence_counts=collections.Counter()
    for (module,symbol),kinds in sorted(roots.items()):
        root_ids=ids_by_key.get((module,symbol),[])
        root_id= root_count+1
        db.execute("INSERT INTO roots VALUES (?,?,?,?)",(root_id,module,symbol,json.dumps(sorted(kinds),ensure_ascii=False)))
        root_count+=1
        queue=collections.deque((fid,0,[fid]) for fid in root_ids)
        seen=set(root_ids)
        while queue:
            fid,depth,path_ids=queue.popleft()
            target_module,target_symbol=functions[fid]
            has_event=int((target_module,target_symbol) in event_keys)
            has_state=int((target_module,target_symbol) in state_keys)
            db.execute("INSERT INTO reachable VALUES (?,?,?,?,?,?,?)",(root_id,fid,target_symbol,depth,json.dumps([functions[x][1] for x in path_ids],ensure_ascii=False),has_event,has_state))
            rows+=1; depth_counts[depth]+=1
            if has_event: evidence_counts["event_functions"]+=1
            if has_state: evidence_counts["state_functions"]+=1
            if depth>=MAX_DEPTH: continue
            for nxt in graph.get(fid,()):
                if nxt not in seen:
                    seen.add(nxt); queue.append((nxt,depth+1,path_ids+[nxt]))
    db.commit()
    max_observed=max(depth_counts) if depth_counts else 0
    result={"title":"阶段二输入跨函数可达性","root_functions":root_count,"reachable_function_rows":rows,"max_depth":MAX_DEPTH,"max_observed_depth":max_observed,"reached_depth_limit":max_observed>=MAX_DEPTH,"depth_counts":dict(depth_counts),"evidence_counts":dict(evidence_counts),"roots_with_event_reachable":db.execute("SELECT count(DISTINCT root_id) FROM reachable WHERE has_event=1").fetchone()[0],"roots_with_state_reachable":db.execute("SELECT count(DISTINCT root_id) FROM reachable WHERE has_state=1").fetchone()[0],"database":str(out.relative_to(ROOT)).replace("\\","/"),"limitations":["只沿唯一解析的静态 Lua 候选边展开；动态接收者、跨 Lua/C# 桥接和未解析边不在可达性证明内.",f"本次最多允许深度 {MAX_DEPTH}；实际最大深度 {max_observed}。" if max_observed < MAX_DEPTH else f"本次达到深度上限 {MAX_DEPTH}，仍需继续展开或用运行时证据确认。"]}
    (REPORT/"stage2_input_call_reachability_summary.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    for x in (inp,lua,ev,st): x.close()
    db.close(); print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=="__main__": main()
