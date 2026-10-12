"""Index Lua-to-C#/XLua bridge expressions and match candidates to IL2CPP methods."""
from __future__ import annotations
import collections, json, re, sqlite3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
STAGE2=ROOT/"analysis_data"/"logic_index"/"stage2"
REPORT=ROOT/"analysis_output"/"logic_recovery"/"stage2"
BRIDGE_RE=re.compile(r"CS\.([A-Za-z_][\w.]*)")
MEMBER_RE=re.compile(r"CS\.[A-Za-z_][\w.]*:([A-Za-z_][\w]*)")
CTOR_RE=re.compile(r"CS\.([A-Za-z_][\w.]*)\s*\(")

def main():
    out=STAGE2/"lua_bridge.sqlite3"
    if out.exists(): out.unlink()
    db=sqlite3.connect(out)
    db.executescript("""PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;
    CREATE TABLE bridges(id TEXT PRIMARY KEY,module TEXT NOT NULL,source_path TEXT NOT NULL,
      line INTEGER NOT NULL,function_symbol TEXT,expression TEXT NOT NULL,bridge_namespace TEXT NOT NULL,
      terminal_name TEXT NOT NULL,candidate_method_ids_json TEXT NOT NULL,certainty TEXT NOT NULL);
    CREATE INDEX bridge_terminal ON bridges(terminal_name);
    CREATE INDEX bridge_certainty ON bridges(certainty);""")
    interaction=sqlite3.connect(STAGE2/"interaction_triggers.sqlite3")
    native=sqlite3.connect(STAGE2/"il2cpp_native.sqlite3")
    methods=collections.defaultdict(list)
    for row in native.execute("SELECT id,name FROM methods"):
        methods[row[1].split("$$")[-1].split("::")[-1].split(".")[-1]].append(row[0])
    all_rows=interaction.execute("SELECT id,module,source_path,line,function_symbol,callee,expression FROM triggers WHERE trigger_kind='bridge'").fetchall()
    counts=collections.Counter()
    for row in all_rows:
        ident,module,source_path,line,function_symbol,callee,expression=row
        bridge_match=BRIDGE_RE.search(expression)
        if not bridge_match: continue
        namespace=bridge_match.group(1)
        member_match=MEMBER_RE.search(expression)
        ctor_match=CTOR_RE.search(expression)
        if member_match:
            terminal=member_match.group(1)
            candidate=methods.get(terminal,[])
            certainty="unique_member_method_match" if len(candidate)==1 else ("ambiguous_member_method_match" if candidate else "unresolved_member_method")
        elif ctor_match:
            terminal=namespace.split(".")[-1]
            candidate=[]
            for name, ids in methods.items():
                if name in (terminal, ".ctor"):
                    candidate.extend(ids)
            candidate=list(dict.fromkeys(candidate))
            certainty="constructor_method_candidate" if candidate else "unresolved_constructor"
        else:
            terminal=namespace.split(".")[-1]
            candidate=[]
            certainty="static_or_instance_member"
        db.execute("INSERT INTO bridges VALUES (?,?,?,?,?,?,?,?,?,?)",(ident,module,source_path,line,function_symbol,expression,namespace,terminal,json.dumps(candidate),certainty))
        counts[certainty]+=1
    db.commit()
    result={"title":"阶段二 Lua/C# 桥接索引","bridge_rows":db.execute("SELECT count(*) FROM bridges").fetchone()[0],"by_certainty":dict(counts),"distinct_bridge_names":db.execute("SELECT count(DISTINCT bridge_namespace) FROM bridges").fetchone()[0],"database":str(out.relative_to(ROOT)).replace("\\","/"),"limitations":["Lua 中 CS.* 可能是类型、静态属性、实例属性或方法；仅凭文本终端名匹配不能证明具体 overload。","XLua userdata、反射和动态索引不一定带有可静态匹配的方法名，已作为未解析桥接保留。"]}
    (REPORT/"stage2_lua_bridge_summary.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    interaction.close(); native.close(); db.close(); print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=="__main__": main()
