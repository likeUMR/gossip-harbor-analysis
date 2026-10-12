"""Build a reproducible cross-language logic inventory for stage two."""
from __future__ import annotations

import collections
import hashlib
import json
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "analysis_data" / "logic_index"
OUT = INDEX / "stage2"
REPORT = ROOT / "analysis_output" / "logic_recovery" / "stage2"


def read_json(name: str):
    with (INDEX / name).open("r", encoding="utf-8") as stream:
        return json.load(stream)


def write_json(path: Path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def relpath(path: str | Path) -> str:
    try:
        return str(Path(path).resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def stable_id(kind: str, *parts) -> str:
    return kind + ":" + ":".join(str(x) for x in parts)


def insert_entity(db, entity):
    db.execute(
        "INSERT OR REPLACE INTO entities VALUES (?, ?, ?, ?, ?, ?, ?)",
        (entity["id"], entity["kind"], entity["name"], entity.get("source", ""),
         entity.get("location", ""), entity.get("status", ""),
         json.dumps(entity.get("details", {}), ensure_ascii=False, separators=(",", ":"))),
    )


def insert_edge(db, src, dst, kind, source, line=None, certainty="confirmed", detail=None):
    db.execute(
        "INSERT OR IGNORE INTO edges VALUES (?, ?, ?, ?, ?, ?, ?)",
        (src, dst, kind, source, line, certainty,
         json.dumps(detail or {}, ensure_ascii=False, separators=(",", ":"))),
    )


def decode_lua_string(raw: str) -> str:
    data = bytearray()
    i = 0
    while i < len(raw):
        if raw[i] == "\\" and i + 3 < len(raw) and raw[i + 1:i + 4].isdigit():
            data.append(int(raw[i + 1:i + 4]))
            i += 4
        elif raw[i] == "\\" and i + 1 < len(raw):
            escapes = {"n": 10, "r": 13, "t": 9, "\\": 92, '"': 34, "'": 39}
            data.append(escapes.get(raw[i + 1], ord(raw[i + 1])))
            i += 2
        else:
            data.extend(raw[i].encode("utf-8"))
            i += 1
    return data.decode("utf-8", errors="replace")


def lua_source(module):
    path = ROOT / module.get("source_path", "")
    if not path.is_file():
        return None, "missing_source"
    try:
        return path.read_text(encoding="utf-8"), "available"
    except (OSError, UnicodeError):
        return None, "unreadable_source"


def test_risk(source: str) -> str:
    low = source.lower()
    if any(token in low for token in ("deletedatabase", "clearserver", "restartgame", "forceactive", "setlevel", "finishall", "finishtotask", "acquirewithcollectanimation", "acquireskin", "removeall", "removecachedqueue")):
        return "high_state_change_candidate"
    if any(token in low for token in ("network", "server", "request", "iap", "purchase", "payment", "account")):
        return "external_or_account_effect_candidate"
    if any(token in low for token in ("playerprefs.set", "setenergy", "setproperty", "additem", "removeitem", "collectall", "mergeall", "spreadall", "timescale")):
        return "local_state_change_candidate"
    return "read_or_ui_candidate"


def extract_test_buttons(source: str, module_name: str):
    rows = []
    if module_name.endswith("TestWindowButtonDefinition"):
        # Each top-level entry ends at the two-space table close; nested callbacks are kept intact.
        entry_re = re.compile(r'^  \[("(?:\\.|[^"])*")\] = \{(.*?)^  \},?\s*$', re.M | re.S)
        for match in entry_re.finditer(source):
            key = decode_lua_string(match.group(1)[1:-1])
            body = match.group(2)
            name_match = re.search(r'^\s+name\s*=\s*("(?:\\.|[^"])*")', body, re.M)
            callback_matches = re.findall(r'\bself:([A-Za-z_]\w*)\s*\(', body)
            callback = callback_matches[-1] if callback_matches else ""
            kind_match = re.search(r'buttonType\s*=\s*TestWindowButtonType\.([A-Za-z_]+)', body)
            on_click_present = re.search(r'\bonClick\s*=', body) is not None
            effects_seen = sorted(set(re.findall(
                r'\b(?:GM\.[\w.]+:(?:\w+)|PlayerPrefs\.(?:Get|Set)\w+|CS\.LuaTestHelper\.\w+|Network\w*\.[\w.:]+|EventDispatcher\.(?:AddListener|DispatchEvent))', body)))
            rows.append({
                "id": key,
                "label": decode_lua_string(name_match.group(1)[1:-1]) if name_match else key,
                "button_type": kind_match.group(1) if kind_match else "unknown",
                "callback": callback,
                "callback_kind": "named_self_method" if callback else "inline_callback" if on_click_present else "no_click_handler",
                "on_click_present": on_click_present,
                "direct_effects_seen": effects_seen,
                "source_line": source.count("\n", 0, match.start()) + 1,
                "risk": test_risk(body),
                "evidence": module_name,
                "record_type": "button_definition",
            })
    else:
        if module_name.endswith("TestWindowTabConfig"):
            for table_match in re.finditer(r'buttonIds\s*=\s*\{([^}]*)\}', source, re.S):
                for literal in re.finditer(r'"((?:\\.|[^"])*)"', table_match.group(1)):
                    button_id = decode_lua_string(literal.group(1))
                    rows.append({"id": button_id, "label": button_id, "button_type": "configured_id",
                                 "callback": "", "risk": "configured_action_not_resolved",
                                 "evidence": module_name, "record_type": "tab_or_group_button"})
        if module_name.endswith("TestWindowCustomConfig"):
            for table_name, role in (("TestWindowQuickButtonConfig", "quick_button"),
                                     ("TestWindowFavouriteButtonConfig", "favorite_button")):
                table_match = re.search(r'^' + table_name + r'\s*=\s*\{([^}]*)\}', source, re.M | re.S)
                if table_match:
                    for literal in re.finditer(r'"((?:\\.|[^"])*)"', table_match.group(1)):
                        button_id = decode_lua_string(literal.group(1))
                        rows.append({"id": button_id, "label": button_id, "button_type": "configured_id",
                                     "callback": "", "risk": "configured_action_not_resolved",
                                     "evidence": module_name, "record_type": role})
    return rows


def extract_test_commands(source: str, module_name: str):
    rows = []
    if not module_name.endswith("TestCommandDefinition"):
        return rows
    entry_re = re.compile(r'^  ([A-Za-z_]\w*) = \{(.*?)^  \},?\s*$', re.M | re.S)
    for match in entry_re.finditer(source):
        key, body = match.group(1), match.group(2)
        cmd_match = re.search(r'\bCmd\s*=\s*"((?:\\.|[^"])*)"', body)
        desc_match = re.search(r'\bDesc\s*=\s*"((?:\\.|[^"])*)"', body)
        execute_body = body
        rows.append({"key": key, "command": decode_lua_string(cmd_match.group(1)) if cmd_match else "",
            "description": decode_lua_string(desc_match.group(1)) if desc_match else "",
            "risk": test_risk(execute_body), "effects_seen": sorted(set(re.findall(
                r'\b(?:GM\.[\w.]+:(?:\w+)|PlayerPrefs\.(?:Get|Set)\w+|CS\.LuaTestHelper\.\w+|Network\w*\.[\w.:]+|EventDispatcher\.(?:AddListener|DispatchEvent))', execute_body))),
            "evidence": module_name, "source_line": source.count("\n", 0, match.start()) + 1})
    return rows


def find_test_handler(sources, callback, owner="TestWindowV2"):
    if not callback:
        return []
    pattern = re.compile(r'^function\s+(' + re.escape(owner) + r':' + re.escape(callback) + r')\s*\([^\n]*\)\s*$', re.M)
    candidates = []
    for module_name, path, source in sources:
        for match in pattern.finditer(source):
            next_match = re.search(r'^function\s+[\w.:]+\s*\(', source[match.end():], re.M)
            end = match.end() + next_match.start() if next_match else len(source)
            body = source[match.start():end]
            candidates.append({"module": module_name, "handler": match.group(1), "source_path": path,
                "line": source.count("\n", 0, match.start()) + 1,
                "risk": test_risk(body),
                "effects_seen": sorted(set(re.findall(
                    r'\b(?:GM\.[\w.]+:(?:\w+)|PlayerPrefs\.(?:Get|Set)\w+|CS\.LuaTestHelper\.\w+|Network\w*\.[\w.:]+|EventDispatcher\.(?:AddListener|DispatchEvent))', body)))})
    return candidates


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    REPORT.mkdir(parents=True, exist_ok=True)
    db_path = OUT / "logic_index.sqlite3"
    if db_path.exists():
        db_path.unlink()
    db = sqlite3.connect(db_path)
    db.executescript("""
        PRAGMA journal_mode=OFF;
        PRAGMA synchronous=OFF;
        CREATE TABLE entities (
            id TEXT PRIMARY KEY, kind TEXT NOT NULL, name TEXT NOT NULL,
            source TEXT, location TEXT, status TEXT, details_json TEXT NOT NULL
        );
        CREATE TABLE edges (
            src TEXT NOT NULL, dst TEXT NOT NULL, kind TEXT NOT NULL,
            evidence_source TEXT NOT NULL, evidence_line INTEGER,
            certainty TEXT NOT NULL, details_json TEXT NOT NULL,
            PRIMARY KEY(src, dst, kind, evidence_source, evidence_line)
        );
        CREATE TABLE unresolved (
            id TEXT PRIMARY KEY, layer TEXT, category TEXT, item TEXT,
            evidence TEXT, next_step TEXT
        );
        CREATE INDEX entity_kind ON entities(kind);
        CREATE INDEX entity_name ON entities(name);
        CREATE INDEX edge_src ON edges(src);
        CREATE INDEX edge_dst ON edges(dst);
        CREATE INDEX unresolved_layer ON unresolved(layer, category);
    """)

    counts = collections.Counter()
    modules = read_json("lua_modules.json")
    module_by_hash = {}
    module_by_name = collections.defaultdict(list)
    for module in modules:
        digest = module.get("sha256") or hashlib.sha256(module.get("name", "").encode()).hexdigest()
        mid = stable_id("lua_module", digest)
        module_by_hash[digest] = (mid, module)
        module_by_name[module.get("name", "")].append(mid)
        insert_entity(db, {"id": mid, "kind": "lua_module", "name": module.get("name", ""),
            "source": module.get("origin", ""), "location": module.get("path", ""),
            "status": module.get("parse_status", "unknown"), "details": {
                "sha256": digest, "category": module.get("category"), "archive": module.get("archive"),
                "bytes": module.get("bytes"), "prototype_count": module.get("prototype_count"),
                "decompile_status": module.get("decompile_status")}})
        counts["lua_module"] += 1

    for fn in read_json("lua_functions.json"):
        digest = fn.get("module_sha256", "")
        module_id, module = module_by_hash.get(digest, (stable_id("lua_module", digest), {}))
        proto = fn.get("prototype", "?")
        fid = stable_id("lua_proto", digest, proto)
        insert_entity(db, {"id": fid, "kind": "lua_prototype", "name": f"{fn.get('module', '?')}#{proto}",
            "source": module.get("origin", ""), "location": f"{module.get('source_path', '')}:{fn.get('first_line', 0)}",
            "status": fn.get("review_status", "unreviewed"), "details": {
                "module": fn.get("module"), "module_sha256": digest, "prototype": proto,
                "bytecode_offset": fn.get("offset"), "first_line": fn.get("first_line"),
                "last_line": fn.get("last_line"), "parameters": fn.get("parameters"),
                "vararg": fn.get("vararg"), "instructions": fn.get("instructions"),
                "constant_count": fn.get("constants"), "literal_count": len(fn.get("strings", []))}})
        insert_edge(db, module_id, fid, "defines_prototype", module.get("path", "lua_functions.json"),
                    fn.get("first_line"), "confirmed", {"prototype": proto, "offset": fn.get("offset")})
        if "." in proto:
            parent = proto.rsplit(".", 1)[0]
            parent_id = stable_id("lua_proto", digest, parent)
            insert_edge(db, parent_id, fid, "contains_nested_prototype", module.get("path", "lua_functions.json"),
                        fn.get("first_line"), "confirmed", {"child_prototype": proto})
        counts["lua_prototype"] += 1

    android_classes = read_json("android_classes.json")
    class_ids = {}
    for row in android_classes:
        cid = stable_id("dex_class", row.get("dex_sha256", ""), row.get("owner", ""))
        class_ids[(row.get("dex_sha256", ""), row.get("owner", ""))] = cid
        insert_entity(db, {"id": cid, "kind": "android_class", "name": row.get("owner", ""),
            "source": row.get("dex_sha256", ""), "location": row.get("path", ""), "status": "smali_exported",
            "details": {"line_count": row.get("lines"), "dex_sha256": row.get("dex_sha256")}})
        counts["android_class"] += 1

    android_method_rows = read_json("android_methods.json")
    android_target_ids = collections.defaultdict(list)
    android_path_meta = {}
    android_method_ids = set()
    for row in android_method_rows:
        owner, dex = row.get("owner", ""), row.get("dex_sha256", "")
        sig = row.get("signature", "")
        mid = stable_id("dex_method", dex, owner, sig)
        android_method_ids.add(mid)
        insert_entity(db, {"id": mid, "kind": "android_method", "name": owner + "->" + sig,
            "source": dex, "location": f"{row.get('path', '')}:{row.get('start_line', '')}",
            "status": "has_code" if row.get("has_code") else "declaration_only",
            "details": {"owner": owner, "signature": sig, "dex_sha256": dex,
                        "end_line": row.get("end_line"), "has_code": row.get("has_code")}})
        cid = class_ids.get((dex, owner))
        if cid:
            insert_edge(db, cid, mid, "declares_method", row.get("path", "android_methods.json"),
                        row.get("start_line"), "confirmed", {"signature": sig})
        android_target_ids[(owner, sig)].append(mid)
        counts["android_method"] += 1

    for row in android_classes:
        android_path_meta[row.get("path", "").replace("\\", "/")] = (row.get("dex_sha256", ""), row.get("owner", ""))

    invoke_re = re.compile(r'^\s*invoke-([\w/-]+)\s+\{[^}]*\},\s*(L[^;]+;)->([^\s(]+)(\([^\s]*\)\S+)')
    method_decl_re = re.compile(r'^\s*\.method\s+(.+?)\s*$')
    android_call_counts = collections.Counter()
    android_edge_batch = []
    for relpath_text, (dex_hash, owner) in android_path_meta.items():
        smali_path = ROOT / relpath_text
        if not smali_path.is_file():
            db.execute("INSERT OR REPLACE INTO unresolved VALUES (?, ?, ?, ?, ?, ?)",
                (stable_id("missing_smali", dex_hash, owner), "android", "smali_file_missing", owner,
                 relpath_text, "核对 DEX 类导出与 smali 文件清单"))
            continue
        caller_id = None
        with smali_path.open("r", encoding="utf-8", errors="replace") as source:
            for line_no, line in enumerate(source, 1):
                declaration = method_decl_re.match(line)
                if declaration:
                    tokens = declaration.group(1).split()
                    if tokens:
                        signature = tokens[-1]
                        caller_id = stable_id("dex_method", dex_hash, owner, signature)
                        if caller_id not in android_method_ids:
                            caller_id = None
                    continue
                if line.lstrip().startswith(".end method"):
                    caller_id = None
                    continue
                call = invoke_re.match(line)
                if not call:
                    continue
                opcode, descriptor, method_name, proto = call.groups()
                target_owner = descriptor[1:-1].replace("/", ".")
                target_sig = method_name + proto
                android_call_counts["invoke_sites"] += 1
                if caller_id is None:
                    android_call_counts["caller_unresolved"] += 1
                    category = "caller_unresolved"
                    targets = []
                else:
                    targets = android_target_ids.get((target_owner, target_sig), [])
                    if len(targets) == 1:
                        category = "resolved"
                        android_call_counts["resolved"] += 1
                    elif len(targets) > 1:
                        category = "ambiguous"
                        android_call_counts["ambiguous"] += 1
                    elif opcode.startswith("custom") or opcode.startswith("polymorphic"):
                        category = "dynamic_target_unresolved"
                        android_call_counts[category] += 1
                    else:
                        category = "external_or_unresolved"
                        android_call_counts[category] += 1
                edge_kind = "android_invoke_" + opcode.replace("/", "_")
                if caller_id is not None and targets:
                    certainty = "resolved" if len(targets) == 1 else "ambiguous"
                    for target_id in targets:
                        android_edge_batch.append((caller_id, target_id, edge_kind, relpath_text, line_no,
                            certainty, json.dumps({"opcode": opcode, "target": target_owner + "->" + target_sig}, separators=(",", ":"))))
                else:
                    unresolved_id = stable_id("android_invoke", target_owner, target_sig, category)
                    db.execute("INSERT OR IGNORE INTO unresolved VALUES (?, ?, ?, ?, ?, ?)",
                        (unresolved_id, "android", category, target_owner + "->" + target_sig,
                         f"{relpath_text}:{line_no}", "区分 Android/Java 外部 API、反射目标和未索引 DEX 定义"))
                if len(android_edge_batch) >= 20000:
                    db.executemany("INSERT OR IGNORE INTO edges VALUES (?, ?, ?, ?, ?, ?, ?)", android_edge_batch)
                    android_edge_batch.clear()
        if android_edge_batch and len(android_edge_batch) >= 20000:
            db.executemany("INSERT OR IGNORE INTO edges VALUES (?, ?, ?, ?, ?, ?, ?)", android_edge_batch)
            android_edge_batch.clear()
    if android_edge_batch:
        db.executemany("INSERT OR IGNORE INTO edges VALUES (?, ?, ?, ?, ?, ?, ?)", android_edge_batch)
    counts["android_invoke_sites"] = android_call_counts["invoke_sites"]

    for row in read_json("native_methods.json"):
        address, name = row.get("Address"), row.get("Name", "")
        nid = stable_id("il2cpp_method", address, name)
        insert_entity(db, {"id": nid, "kind": "il2cpp_method_mapping", "name": name,
            "source": "native_methods.json", "location": f"RVA/VA:{address}",
            "status": row.get("recovery_status", "unknown"), "details": {
                "address": address, "signature": row.get("Signature"), "type_signature": row.get("TypeSignature"),
                "review_status": row.get("review_status")}})
        counts["il2cpp_method_mapping"] += 1

    for row in read_json("native_libraries.json"):
        lid = stable_id("native_library", row.get("sha256", ""))
        insert_entity(db, {"id": lid, "kind": "native_library", "name": Path(row.get("path", "")).name,
            "source": row.get("sha256", ""), "location": row.get("path", ""), "status": row.get("status", "unknown"),
            "details": {"bytes": row.get("bytes"), "machine": row.get("machine"),
                        "sections": row.get("sections", [])}})
        counts["native_library"] += 1

    # Build evidence-backed Lua module relations and a focused test-tool catalogue.
    require_count = 0
    event_count = 0
    test_modules = []
    test_buttons = []
    test_commands = []
    test_source_bodies = []
    test_functions = []
    gate_evidence = []
    requires_re = re.compile(r'\brequire\s*\(?\s*["\']([^"\']+)["\']')
    event_re = re.compile(r'EventDispatcher\.(AddListener|RemoveListener)\s*\(\s*EEventType\.([A-Za-z_][\w.]*)\s*,\s*([^,]+)\s*,\s*([^\)]+)\)')
    function_re = re.compile(r'^\s*(?:local\s+)?function\s+([\w.:]+)\s*\(', re.M)
    for module in modules:
        name = module.get("name", "")
        digest = module.get("sha256", "")
        src, src_status = lua_source(module)
        if src is None:
            db.execute("INSERT OR REPLACE INTO unresolved VALUES (?, ?, ?, ?, ?, ?)",
                (stable_id("missing_source", digest), "lua", "source_missing", name,
                 module.get("source_path", ""), "恢复或定位对应反编译/反汇编产物"))
            continue
        module_id = module_by_hash[digest][0]
        source_path = module.get("source_path", "")
        for match in requires_re.finditer(src):
            target_name = match.group(1)
            targets = module_by_name.get(target_name, [])
            line = src.count("\n", 0, match.start()) + 1
            if len(targets) == 1:
                insert_edge(db, module_id, targets[0], "lua_require", source_path, line, "confirmed", {"module_name": target_name})
            else:
                db.execute("INSERT OR REPLACE INTO unresolved VALUES (?, ?, ?, ?, ?, ?)",
                    (stable_id("lua_require", digest, line, target_name), "lua", "require_target_unresolved",
                     f"{name} requires {target_name}", f"{source_path}:{line}",
                     "区分动态模块名、缺失模块与未索引模块版本"))
            require_count += 1
        for match in event_re.finditer(src):
            operation, event, target_obj, callback = (x.strip() for x in match.groups())
            line = src.count("\n", 0, match.start()) + 1
            eid = stable_id("event", event)
            insert_entity(db, {"id": eid, "kind": "lua_event", "name": event,
                               "source": source_path, "location": f"{source_path}:{line}", "status": "event_type_symbol"})
            insert_edge(db, module_id, eid, "event_" + operation.lower(), source_path, line, "confirmed",
                        {"receiver": target_obj, "callback_expression": callback})
            event_count += 1

        if module.get("category") == "test_debug" or name.startswith("Test."):
            test_modules.append({"name": name, "sha256": digest, "module_path": module.get("path"),
                "source_path": source_path, "archive": module.get("archive"), "bytes": module.get("bytes"),
                "prototype_count": module.get("prototype_count"), "source_status": src_status})
            test_source_bodies.append((name, source_path, src))
            for match in function_re.finditer(src):
                function_name = match.group(1)
                line = src.count("\n", 0, match.start()) + 1
                # Scope is a module-level evidence locator; callers still need exact call graph resolution.
                snippet = src[match.start():min(len(src), match.start() + 1200)]
                test_functions.append({"module": name, "function": function_name, "line": line,
                    "source_path": source_path, "risk": test_risk(snippet),
                    "effects_seen": sorted(set(re.findall(r'\b(?:GM\.[\w.]+:(?:\w+)|PlayerPrefs\.(?:Get|Set)\w+|CS\.LuaTestHelper\.\w+|Network\w*\.[\w.:]+|EventDispatcher\.(?:AddListener|DispatchEvent))', snippet)))})
            test_buttons.extend(extract_test_buttons(src, name))
            test_commands.extend(extract_test_commands(src, name))
            if "ProjectConfig.IS_TEST_MODE" in src or "GameConfig.IsTestMode" in src:
                gate_evidence.append({"module": name, "source_path": source_path,
                    "line": next((i for i, line in enumerate(src.splitlines(), 1) if "IsTestMode" in line or "IS_TEST_MODE" in line), None),
                    "condition": "ProjectConfig.IS_TEST_MODE via GameConfig.IsTestMode()"})
    counts["lua_require_edges"] = require_count
    counts["lua_event_registration_edges"] = event_count
    db.commit()

    edge_counts = {row[0]: row[1] for row in db.execute("SELECT kind, count(*) FROM edges GROUP BY kind")}
    unresolved_counts = {row[0] + "/" + row[1]: row[2] for row in db.execute(
        "SELECT layer, category, count(*) FROM unresolved GROUP BY layer, category")}
    summary = {
        "title": "Gossip Harbor 阶段二逻辑索引初始构建",
        "sample": "Gossip Harbor 3.98.10; existing stage-one resource snapshot",
        "entities": dict(counts), "total_entities": sum(counts[k] for k in (
            "lua_module", "lua_prototype", "android_class", "android_method", "il2cpp_method_mapping", "native_library")),
        "edges": edge_counts, "unresolved": unresolved_counts,
        "android_callsite_resolution": dict(android_call_counts),
        "important_limits": [
            "此初始索引包括所有已恢复 Lua、DEX 和 IL2CPP 符号实体，但调用边尚未完成全语言提取。",
            "Lua require 与事件注册依据可读反编译文本抽取；generated_unverified 模块的行号及语义需要结合字节码复核。",
            "IL2CPP 当前记录到方法签名和地址映射；地址不是已经反编译的 C# 方法体。",
            "Test 工具函数的副作用标签是词面筛查候选，必须沿调用链核实后才能作确定结论。",
            "测试模式的具体运行时值及账号远端自定义配置需要运行时或配置响应证据确认。",
        ],
        "database": relpath(db_path),
    }
    write_json(REPORT / "stage2_index_summary.json", summary)
    for button in test_buttons:
        if button["record_type"] == "button_definition":
            button["handler_candidates"] = find_test_handler(test_source_bodies, button["callback"])
            candidates = button["handler_candidates"]
            if len(candidates) == 1:
                button["resolved_handler"] = candidates[0]
                button["handler_resolution"] = "unique_TestWindowV2_method"
            elif candidates and len({candidate["source_path"] for candidate in candidates}) == 1:
                button["resolved_handler"] = max(candidates, key=lambda candidate: candidate["line"])
                button["handler_resolution"] = "last_definition_wins_in_source_order"
                button["superseded_handlers"] = [candidate for candidate in candidates
                                                  if candidate is not button["resolved_handler"]]
            else:
                button["resolved_handler"] = None
                button["handler_resolution"] = ("ambiguous_across_modules" if candidates else
                                                  "no_named_handler_candidate")
            if button["resolved_handler"]:
                button["risk"] = button["resolved_handler"]["risk"]
    definitions_by_id = collections.defaultdict(list)
    for button in test_buttons:
        if button["record_type"] == "button_definition":
            definitions_by_id[button["id"]].append(button)
    for reference in test_buttons:
        if reference["record_type"] != "button_definition":
            candidates = definitions_by_id.get(reference["id"], [])
            reference["definition_candidates"] = [
                {"evidence": item["evidence"], "callback": item["callback"]} for item in candidates]
            reference["definition_resolution"] = (
                "unique_static_definition" if len(candidates) == 1 else
                "ambiguous_static_definition" if candidates else
                "not_found_in_static_definition_table")
    write_json(REPORT / "test_framework_inventory.json", {
        "title": "内置测试框架索引",
        "scope": "所有 Lua 模块中 category=test_debug 或模块名以 Test. 开头的模块",
        "module_count": len(test_modules), "source_function_declarations": len(test_functions),
        "button_definition_count": sum(x["record_type"] == "button_definition" for x in test_buttons),
        "configured_button_reference_count": sum(x["record_type"] != "button_definition" for x in test_buttons),
        "button_callback_kind_counts": dict(collections.Counter(
            x.get("callback_kind", "configured_reference") for x in test_buttons)),
        "button_handler_resolution_counts": dict(collections.Counter(
            x.get("handler_resolution", "configured_reference") for x in test_buttons)),
        "button_reference_resolution_counts": dict(collections.Counter(
            x.get("definition_resolution", "button_definition") for x in test_buttons)),
        "test_command_count": len(test_commands),
        "modules": sorted(test_modules, key=lambda x: x["name"]),
        "functions": sorted(test_functions, key=lambda x: (x["module"], x["line"])),
        "button_definitions": [x for x in test_buttons if x["record_type"] == "button_definition"],
        "button_configurations": [x for x in test_buttons if x["record_type"] != "button_definition"],
        "commands": test_commands,
        "command_execution_path": [
            {"step": "input", "evidence": "TestModel:Update reads BackQuote and opens TestCommandView when it is not already open"},
            {"step": "submit", "evidence": "TestCommandView:Update handles Return; OnExecuteBntClick calls ExecuteCmd with the input text"},
            {"step": "parse", "evidence": "TestCommandView:ExecuteCmd trims input, splits on spaces, takes token 1 as command, then scans ECommand by Cmd"},
            {"step": "dispatch", "evidence": "Matched ECommand entry invokes cmdDef:ExecuteFunc(list); each TestCommandDefinition entry owns its ExecuteFunc implementation"},
        ],
        "command_flow_evidence": [
            {"module": "Test.TestModel", "source_file": "decompiled.lua", "line": 242},
            {"module": "Test.TestCommandView", "source_file": "decompiled.lua", "lines": [17, 23, 78]},
            {"module": "Test.TestCommandDefinition", "source_file": "decompiled.lua", "table": "ECommand"},
        ],
        "activation_gates": gate_evidence,
        "confirmed_gate_code": {
            "project_flag": "ProjectConfig.IS_TEST_MODE captured by GameConfig.IsTestMode()",
            "ui_preference": "Some test UI requires EPlayerPrefKey.TestButton == 1",
            "remote_extension": "TestModel calls CS.LuaTestHelper.DownloadTestWindowCustomConfig(userId, callback) on main-scene entry when no custom config is present",
            "remote_code_execution": "TestWindowV2:LoadCustomConfig obtains custom Lua text from CS.LuaTestHelper.GetTestWindowCustomConfig(), passes it to load(), and executes the returned function when compilation succeeds",
        },
        "interpretation_limits": [
            "存在于安装包只证明测试代码已打包，不证明当前构建或账号已启用。",
            "按钮名称、回调和风险标签来自代码静态线索；需要继续解析 TestWindowV2 配置选择、自定义配置覆盖和具体回调副作用。",
            "带有账户、服务器、支付、删库、跳关、资源修改或重启线索的入口不应在正式账号上试点。",
            "远端自定义 Lua 的来源、签名/完整性校验、权限控制、失败策略及持久化边界尚未由此索引确认。",
        ],
    })
    db.close()
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
