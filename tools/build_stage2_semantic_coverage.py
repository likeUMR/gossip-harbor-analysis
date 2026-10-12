"""Build per-input-root semantic evidence coverage for stage-two acceptance."""
from __future__ import annotations
import json, sqlite3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
S=ROOT/"analysis_data"/"logic_index"/"stage2"
R=ROOT/"analysis_output"/"logic_recovery"/"stage2"

def keys(db_path, table, condition="1=1"):
    d=sqlite3.connect(db_path)
    rows={(str(Path(r[0]).resolve()).casefold(), r[1].replace(':', '.')) for r in d.execute(
        f"SELECT source_path,function_symbol FROM {table} WHERE function_symbol IS NOT NULL AND ({condition})")}
    d.close(); return rows

def main():
    out=S/"semantic_coverage.sqlite3"
    if out.exists(): out.unlink()
    inp=sqlite3.connect(S/"input_entries.sqlite3")
    reach=sqlite3.connect(S/"input_call_reachability.sqlite3")
    lua=sqlite3.connect(S/"lua_relations.sqlite3")
    db=sqlite3.connect(out)
    db.executescript("""
      CREATE TABLE root_coverage(
        root_id INTEGER PRIMARY KEY, module TEXT NOT NULL, function_symbol TEXT NOT NULL,
        entry_kinds TEXT NOT NULL, reachable_functions INTEGER NOT NULL,
        has_event INTEGER NOT NULL, has_state INTEGER NOT NULL, has_network INTEGER NOT NULL,
        has_bridge INTEGER NOT NULL, has_random INTEGER NOT NULL, has_config INTEGER NOT NULL,
        dynamic_callback_linked INTEGER NOT NULL, dynamic_callback_unlinked INTEGER NOT NULL,
        evidence_class TEXT NOT NULL, wrapper_direct_effect INTEGER NOT NULL,
        wrapper_effect_kinds TEXT NOT NULL, forwarding_call INTEGER NOT NULL,
        forwarding_methods TEXT NOT NULL
      );
      CREATE INDEX root_cov_class ON root_coverage(evidence_class);
    """)
    funcs={r[0]:(str((ROOT/r[1]).resolve()).casefold(),r[2]) for r in lua.execute("SELECT id,source_path,symbol FROM functions")}
    event_keys=keys(S/"event_graph.sqlite3","event_sites")
    state_keys=keys(S/"state_config_access.sqlite3","access_sites") | keys(S/"state_mutations.sqlite3","mutations")
    network_keys=keys(S/"network_calls.sqlite3","calls")
    bridge_keys=keys(S/"interaction_triggers.sqlite3","triggers", "trigger_kind='bridge'")
    random_keys=keys(S/"random_mechanisms.sqlite3","mechanisms", "mechanism_kind IN ('weighted','random_uniform','random_n')")
    config_keys=keys(S/"state_config_access.sqlite3","access_sites", "access_kind IN ('configuration_read','configuration_control_or_metadata','resource_config_read','model_config_accessor')")
    dynamic_db=sqlite3.connect(S/"dynamic_callbacks.sqlite3")
    dynamic_linked={(str((ROOT/r[0]).resolve()).casefold(), (r[1] or '').replace(':','.')) for r in dynamic_db.execute("SELECT c.source_path,c.function_symbol FROM calls c WHERE EXISTS (SELECT 1 FROM links l WHERE l.call_id=c.id)")}
    dynamic_unlinked={(str((ROOT/r[0]).resolve()).casefold(), (r[1] or '').replace(':','.')) for r in dynamic_db.execute("SELECT c.source_path,c.function_symbol FROM calls c WHERE NOT EXISTS (SELECT 1 FROM links l WHERE l.call_id=c.id)")}
    dynamic_db.close()
    wrapper_db=sqlite3.connect(S/"dynamic_wrapper_effects.sqlite3")
    wrapper_effects={}
    for path,symbol,kind in wrapper_db.execute("SELECT w.source_path,w.function_symbol,e.effect_kind FROM wrappers w JOIN effects e ON e.wrapper_id=w.id"):
        key=(str((ROOT/path).resolve()).casefold(),(symbol or '').replace(':','.'))
        wrapper_effects.setdefault(key,set()).add(kind)
    wrapper_db.close()
    forwarding_db=sqlite3.connect(S/"dynamic_forwarding.sqlite3")
    forwarding_methods={}
    for path,symbol,method in forwarding_db.execute("SELECT source_path,function_symbol,method FROM calls"):
        key=(str((ROOT/path).resolve()).casefold(),(symbol or '').replace(':','.'))
        forwarding_methods.setdefault(key,set()).add(method)
    forwarding_db.close()
    callback_effect_db=sqlite3.connect(S/"dynamic_callback_effects.sqlite3")
    dynamic_calls_db=sqlite3.connect(S/"dynamic_callbacks.sqlite3")
    callback_effect_keys={kind:set() for kind in ('state_mutation','event_dispatch','network_call','ui_effect')}
    call_keys={r[0]:(r[1],r[2]) for r in dynamic_calls_db.execute("SELECT id,source_path,function_symbol FROM calls")}
    for call_id,definition_id,effect_kind in callback_effect_db.execute("SELECT l.call_id,l.definition_id,e.effect_kind FROM links l JOIN effects e ON e.definition_id=l.definition_id"):
        source_path,function_symbol=call_keys.get(call_id,(None,None))
        if source_path is None: continue
        callback_effect_keys.setdefault(effect_kind,set()).add((str((ROOT/source_path).resolve()).casefold(),(function_symbol or '').replace(':','.')))
    dynamic_calls_db.close()
    callback_effect_db.close()
    rows=0
    gap_rows=[]
    for rid,module,symbol,entry_kinds in reach.execute("SELECT id,module,function_symbol,entry_kinds FROM roots"):
        fids=[r[0] for r in reach.execute("SELECT function_id FROM reachable WHERE root_id=?",(rid,))]
        fkeys={(path, symbol.replace(':', '.')) for path, symbol in (funcs[fid] for fid in fids if fid in funcs)}
        flags={"event":bool(fkeys & event_keys) or bool(fkeys & callback_effect_keys['event_dispatch']),"state":bool(fkeys & state_keys) or bool(fkeys & callback_effect_keys['state_mutation']),"network":bool(fkeys & network_keys) or bool(fkeys & callback_effect_keys['network_call']),"bridge":bool(fkeys & bridge_keys),"random":bool(fkeys & random_keys),"config":bool(fkeys & config_keys)}
        direct_kinds=set()
        for fk in fkeys: direct_kinds |= wrapper_effects.get(fk,set())
        forward_methods=set()
        for fk in fkeys: forward_methods |= forwarding_methods.get(fk,set())
        has_callback_effect=any(bool(fkeys & values) for values in callback_effect_keys.values())
        linked=bool(fkeys & dynamic_linked); unlinked=bool(fkeys & dynamic_unlinked)
        if not fkeys: cls="no_reachable_function"
        elif flags["event"] or flags["state"] or flags["network"] or flags["bridge"]: cls="downstream_effect_evidence"
        elif direct_kinds == {"explicit_noop"}: cls="explicit_noop_or_guard_only"
        elif direct_kinds: cls="direct_wrapper_effect_unresolved_target"
        elif forward_methods: cls="dynamic_forwarding_candidate"
        elif has_callback_effect: cls="dynamic_callback_effect_candidate"
        elif linked: cls="dynamic_callback_candidate_linked"
        elif any(token.lower() in symbol.lower() for token in ("onclick", "onselected", "onpointer", "onlua", "ondrag", "callback", "handler", "_getcelldata")) or "inline_input_callback" in json.loads(entry_kinds): cls="dynamic_callback_unresolved"
        else: cls="logic_only_no_indexed_effect"
        db.execute("INSERT INTO root_coverage VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",(rid,module,symbol,entry_kinds,len(fids),int(flags["event"]),int(flags["state"]),int(flags["network"]),int(flags["bridge"]),int(flags["random"]),int(flags["config"]),int(linked),int(unlinked),cls,int(bool(direct_kinds)),json.dumps(sorted(direct_kinds)),int(bool(forward_methods)),json.dumps(sorted(forward_methods)))); rows+=1
        if cls != "downstream_effect_evidence":
            gap_rows.append({"root_id":rid,"module":module,"function_symbol":symbol,"entry_kinds":json.loads(entry_kinds),"reachable_functions":len(fids),"classification":cls})
    db.commit()
    summary={"roots":rows,"by_class":dict(db.execute("SELECT evidence_class,count(*) FROM root_coverage GROUP BY evidence_class")),"with_event":db.execute("SELECT count(*) FROM root_coverage WHERE has_event=1").fetchone()[0],"with_state":db.execute("SELECT count(*) FROM root_coverage WHERE has_state=1").fetchone()[0],"with_network":db.execute("SELECT count(*) FROM root_coverage WHERE has_network=1").fetchone()[0],"with_bridge":db.execute("SELECT count(*) FROM root_coverage WHERE has_bridge=1").fetchone()[0],"with_random":db.execute("SELECT count(*) FROM root_coverage WHERE has_random=1").fetchone()[0],"with_config":db.execute("SELECT count(*) FROM root_coverage WHERE has_config=1").fetchone()[0],"database":str(out.relative_to(ROOT)).replace('\\','/')}
    (R/"stage2_semantic_coverage_summary.json").write_text(json.dumps(summary,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    (R/"stage2_semantic_gaps.json").write_text(json.dumps(gap_rows,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    (R/"STAGE2_SEMANTIC_COVERAGE.md").write_text("# 阶段二输入语义覆盖矩阵\n\n"+json.dumps(summary,ensure_ascii=False,indent=2)+"\n\n该矩阵按输入根统计静态可达的事件、状态、网络、桥接、随机和配置证据。`downstream_effect_evidence` 只表示静态索引中存在后续效果证据，不表示已证明运行时一定触发；动态接收者、服务端行为和未解析回调仍不能由该表单独证明。\n",encoding="utf-8")
    for d in (inp,reach,lua,db): d.close()
    print(json.dumps(summary,ensure_ascii=False,indent=2))
if __name__=='__main__': main()
