"""Join player-input candidates to same-function event, state, and Lua-call evidence."""
from __future__ import annotations
import collections, json, sqlite3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
STAGE2=ROOT/"analysis_data"/"logic_index"/"stage2"
REPORT=ROOT/"analysis_output"/"logic_recovery"/"stage2"

def main():
    out=STAGE2/"input_paths.sqlite3"
    if out.exists(): out.unlink()
    db=sqlite3.connect(out)
    db.executescript("""PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;
    CREATE TABLE paths(id INTEGER PRIMARY KEY,input_id TEXT NOT NULL,module TEXT NOT NULL,
      function_symbol TEXT,entry_kind TEXT NOT NULL,entry_line INTEGER NOT NULL,
      source_path TEXT NOT NULL,classification TEXT NOT NULL);
    CREATE TABLE path_items(id INTEGER PRIMARY KEY,path_id INTEGER NOT NULL,item_kind TEXT NOT NULL,
      line INTEGER NOT NULL,callee_or_operation TEXT NOT NULL,detail TEXT NOT NULL,
      certainty TEXT NOT NULL,source_id TEXT);
    CREATE INDEX path_input ON paths(input_id); CREATE INDEX item_path ON path_items(path_id);
    CREATE INDEX item_kind ON path_items(item_kind);""")
    inp=sqlite3.connect(STAGE2/"input_entries.sqlite3")
    ev=sqlite3.connect(STAGE2/"event_graph.sqlite3")
    st=sqlite3.connect(STAGE2/"state_config_access.sqlite3")
    lr=sqlite3.connect(STAGE2/"lua_relations.sqlite3")
    events=collections.defaultdict(list); states=collections.defaultdict(list); rels=collections.defaultdict(list)
    for row in ev.execute("SELECT id,module,function_symbol,line,operation,event_expression,event_name,callback_expression,certainty FROM event_sites"):
        events[(row[1],row[2])].append(row)
    for row in st.execute("SELECT id,module,function_symbol,line,access_kind,operation,member,key_expression,certainty FROM access_sites"):
        states[(row[1],row[2])].append(row)
    fids={row[0]:(row[1],row[2]) for row in lr.execute("SELECT id,module,symbol,line FROM functions")}
    for row in lr.execute("SELECT id,source_function,target_function,line,kind,expression,certainty FROM relations"):
        source=row[1]; module,symbol=fids.get(source,("",""))
        if module: rels[(module,symbol)].append((row, fids.get(row[2],("",""))[1]))
    counts=collections.Counter(); item_total=0; path_total=0
    for entry in inp.execute("SELECT id,module,function_symbol,entry_kind,line,source_path FROM entries"):
        input_id,module,symbol,kind,line,source_path=entry
        key=(module,symbol); path_id=path_total+1
        candidates=[]
        for row in events.get(key,[]):
            if row[3]>=line: candidates.append(("event",row[3],row[4],f"{row[5]} -> {row[7]}",row[8],row[0]))
        for row in states.get(key,[]):
            if row[3]>=line: candidates.append(("state",row[3],f"{row[4]}/{row[5]}",f"{row[7]} ({row[6]})",row[8],row[0]))
        for row,target_symbol in rels.get(key,[]):
            direction="after_entry" if row[3]>=line else "before_entry_same_function"
            candidates.append(("lua_call",row[3],row[4],f"{direction}: {row[5]} -> {target_symbol}",row[6],row[0]))
        candidates.sort(key=lambda x:x[1])
        classification="no_downstream_static_evidence"
        if candidates:
            kinds={x[0] for x in candidates}
            classification="event_state_and_calls" if len(kinds)>=3 else ("event_and_state" if {"event","state"}<=kinds else ("event" if "event" in kinds else ("state" if "state" in kinds else "calls")))
        db.execute("INSERT INTO paths VALUES (?,?,?,?,?,?,?,?)",(path_id,input_id,module,symbol,kind,line,source_path,classification))
        for item in candidates:
            db.execute("INSERT INTO path_items(path_id,item_kind,line,callee_or_operation,detail,certainty,source_id) VALUES (?,?,?,?,?,?,?)",(path_id,*item))
            item_total+=1; counts[item[0]]+=1
        path_total+=1
    db.commit()
    result={"title":"阶段二玩家输入静态路径","input_candidates":path_total,"paths_with_downstream_evidence":db.execute("SELECT count(*) FROM paths WHERE classification!='no_downstream_static_evidence'").fetchone()[0],"path_items":item_total,"item_counts":dict(counts),"classification_counts":dict(db.execute("SELECT classification,count(*) FROM paths GROUP BY classification")),"database":str(out.relative_to(ROOT)).replace("\\","/"),"limitations":["路径按同一模块和同一命名函数的源码顺序连接；跨函数调用需结合 Lua/IL2CPP 调用图继续展开。","候选入口可能是组件初始化或测试工具，实际玩家可达性仍需 prefab/运行时验证。"]}
    (REPORT/"stage2_input_paths_summary.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    for x in (inp,ev,st,lr): x.close()
    db.close(); print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=="__main__": main()
