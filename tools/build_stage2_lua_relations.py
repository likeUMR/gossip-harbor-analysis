"""Build a conservative, source-located Lua relation layer for stage two."""
from __future__ import annotations

import collections
import bisect
import hashlib
import json
import re
import sqlite3
from pathlib import Path

try:
    from tree_sitter import Language, Parser
    import tree_sitter_lua
except ImportError:
    Language = Parser = tree_sitter_lua = None

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "analysis_data" / "logic_index"
OUT = INDEX / "stage2"
REPORT = ROOT / "analysis_output" / "logic_recovery" / "stage2"

FUNCTION_RE = re.compile(r"^\s*(?:local\s+)?function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(", re.M)
CALL_RE = re.compile(r"\bself\s*:\s*([A-Za-z_]\w*)\s*\(")
QUALIFIED_CALL_RE = re.compile(r"\b([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*:\s*([A-Za-z_]\w*)\s*\(")
EVENT_RE = re.compile(r"EventDispatcher\.(DispatchEvent|PostEvent)\s*\(\s*EEventType\.([A-Za-z_]\w*)")
REGISTER_RE = re.compile(r"EventDispatcher\.(AddListener|RemoveListener)\s*\(\s*EEventType\.([A-Za-z_]\w*)\s*,\s*([^,]+),\s*([^\)]+)\)")


def load_modules():
    return json.loads((INDEX / "lua_modules.json").read_text(encoding="utf-8"))


def stable_id(*parts):
    return hashlib.sha256("\0".join(map(str, parts)).encode("utf-8")).hexdigest()


def line_at(text, offset):
    return text.count("\n", 0, offset) + 1


def mask_noncode(source):
    """Blank strings and comments while preserving source offsets and newlines."""
    out = list(source)
    i, n, state = 0, len(source), "code"
    while i < n:
        if state == "code":
            if source.startswith("--[[", i):
                j = source.find("]]", i + 4); j = n if j < 0 else j + 2
                for k in range(i, j):
                    if out[k] not in "\r\n": out[k] = " "
                i = j; continue
            if source.startswith("--", i):
                j = source.find("\n", i + 2); j = n if j < 0 else j
                for k in range(i, j): out[k] = " "
                i = j; continue
            if source[i] in "'\"`":
                state = source[i]; out[i] = " "; i += 1; continue
            i += 1; continue
        if source[i] == "\\":
            out[i] = " "; i += 1
            if i < n: out[i] = " "; i += 1
        elif source[i] == state:
            out[i] = " "; i += 1; state = "code"
        else:
            if source[i] not in "\r\n": out[i] = " "
            i += 1
    return "".join(out)


def ast_metadata(source):
    """Parse enough AST to identify declaration name spans and parser health."""
    if Parser is None:
        return {"status": "unavailable", "declaration_spans": [], "calls": []}
    try:
        parser = Parser(); parser.language = Language(tree_sitter_lua.language())
        encoded = source.encode("utf-8")
        tree = parser.parse(encoded); spans, calls = [], []
        def walk(node):
            if node.type == "function_declaration":
                name = node.child_by_field_name("name")
                if name is not None:
                    # Tree-sitter offsets are bytes; regex offsets below are Python characters.
                    start = len(encoded[:name.start_byte].decode("utf-8", "ignore"))
                    end = len(encoded[:name.end_byte].decode("utf-8", "ignore"))
                    spans.append((start, end))
            elif node.type == "function_call":
                name = node.child_by_field_name("name")
                if name is not None:
                    start = len(encoded[:name.start_byte].decode("utf-8", "ignore"))
                    end = len(encoded[:name.end_byte].decode("utf-8", "ignore"))
                    calls.append((start, end, name.type, name.text.decode("utf-8", "replace")))
            for child in node.children: walk(child)
        walk(tree.root_node)
        return {"status": "error" if tree.root_node.has_error else "ok", "declaration_spans": spans, "calls": calls}
    except Exception as exc:
        return {"status": "failed:" + type(exc).__name__, "declaration_spans": [], "calls": []}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    REPORT.mkdir(parents=True, exist_ok=True)
    path = OUT / "lua_relations.sqlite3"
    if path.exists():
        path.unlink()
    db = sqlite3.connect(path)
    db.executescript("""
        PRAGMA journal_mode=OFF;
        PRAGMA synchronous=OFF;
        CREATE TABLE functions (
            id TEXT PRIMARY KEY, module TEXT NOT NULL, module_sha256 TEXT NOT NULL,
            symbol TEXT NOT NULL, line INTEGER NOT NULL, source_path TEXT NOT NULL,
            source_status TEXT NOT NULL, bytecode_mapping TEXT NOT NULL
        );
        CREATE TABLE relations (
            id INTEGER PRIMARY KEY, source_function TEXT, target_function TEXT,
            kind TEXT NOT NULL, certainty TEXT NOT NULL, module TEXT NOT NULL,
            source_path TEXT NOT NULL, line INTEGER NOT NULL, expression TEXT NOT NULL,
            target_candidates_json TEXT NOT NULL
        );
        CREATE TABLE unresolved (
            id INTEGER PRIMARY KEY, kind TEXT NOT NULL, module TEXT NOT NULL,
            source_path TEXT NOT NULL, line INTEGER NOT NULL, expression TEXT NOT NULL,
            reason TEXT NOT NULL
        );
        CREATE INDEX function_symbol ON functions(symbol);
        CREATE INDEX relation_source ON relations(source_function);
        CREATE INDEX relation_target ON relations(target_function);
        CREATE INDEX relation_kind ON relations(kind, certainty);
    """)

    modules = load_modules()
    source_states = collections.Counter()
    parser_states = collections.Counter()
    definitions_by_module = {}
    symbols = collections.defaultdict(list)
    sources = []
    for module in modules:
        name = module.get("name", "")
        digest = module.get("sha256", "")
        source_path = module.get("source_path", "")
        full_path = ROOT / source_path
        if not full_path.is_file():
            source_states["missing_source"] += 1
            continue
        try:
            source = full_path.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            source_states["unreadable_source"] += 1
            continue
        source_states["available"] += 1
        ast = ast_metadata(source)
        parser_states[ast["status"]] += 1
        masked = mask_noncode(source)
        definitions = []
        for match in FUNCTION_RE.finditer(masked):
            symbol = match.group(1)
            line = line_at(source, match.start())
            fid = stable_id(digest, symbol, line)
            item = {"id": fid, "module": name, "digest": digest, "symbol": symbol,
                    "line": line, "offset": match.start(), "source_path": source_path}
            definitions.append(item)
            symbols[symbol].append(item)
            # Class:Method declarations provide a searchable target key.
            if ":" in symbol or "." in symbol:
                owner, method = re.split(r"[.:]", symbol, maxsplit=1)
                qualified = owner + ":" + method
                if qualified != symbol:
                    symbols[qualified].append(item)
        definitions_by_module[digest] = definitions
        sources.append((module, source, definitions, masked, ast))
        for item in definitions:
            db.execute("INSERT INTO functions VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                       (item["id"], name, digest, item["symbol"], item["line"], source_path,
                        module.get("decompile_status", "unknown"), "source-line only; no verified bytecode mapping"))

    relation_counts = collections.Counter()
    resolution_counts = collections.Counter()
    unresolved_counts = collections.Counter()
    for module, source, definitions, masked, ast in sources:
        name, digest, source_path = module.get("name", ""), module.get("sha256", ""), module.get("source_path", "")
        # A nearest preceding function is only a lexical owner hint; nested closures can change scope.
        definition_offsets = [item["offset"] for item in definitions]

        def nearest(offset):
            pos = bisect.bisect_right(definition_offsets, offset) - 1
            return definitions[pos] if pos >= 0 else None

        declaration_starts = {start for start, _ in ast["declaration_spans"]}
        for match in CALL_RE.finditer(masked):
            if match.start() in declaration_starts:
                continue
            method = match.group(1)
            caller = nearest(match.start())
            line = line_at(source, match.start())
            owner = None
            if caller and (":" in caller["symbol"] or "." in caller["symbol"]):
                owner = re.split(r"[.:]", caller["symbol"], maxsplit=1)[0]
            candidates = [item for item in symbols.get(owner + ":" + method, []) if item["digest"] == digest] if owner else []
            kind = "lua_self_call_candidate"
            expr = "self:" + method
            if len(candidates) == 1:
                certainty, target = "candidate_unique_in_module", candidates[0]["id"]
                resolution_counts["unique_in_module"] += 1
            elif candidates:
                certainty, target = "ambiguous", None
                resolution_counts["ambiguous"] += 1
            else:
                certainty, target = "unresolved", None
                unresolved_counts["self_call_target_not_found"] += 1
            db.execute("INSERT INTO relations (source_function,target_function,kind,certainty,module,source_path,line,expression,target_candidates_json) VALUES (?,?,?,?,?,?,?,?,?)",
                       (caller["id"] if caller else None, target, kind, certainty, name, source_path, line, expr,
                        json.dumps([item["id"] for item in candidates])))
            relation_counts[kind] += 1
            if not candidates:
                db.execute("INSERT INTO unresolved (kind,module,source_path,line,expression,reason) VALUES (?,?,?,?,?,?)",
                           (kind, name, source_path, line, expr, "self 的运行时接收对象及继承/混入关系需继续解析"))

        for match in QUALIFIED_CALL_RE.finditer(masked):
            if match.start() in declaration_starts:
                continue
            receiver, method = match.groups()
            if receiver == "self":
                continue
            caller = nearest(match.start())
            line = line_at(source, match.start())
            key = receiver.split(".")[-1] + ":" + method
            candidates = symbols.get(key, [])
            if len(candidates) == 1:
                certainty, target = "candidate_unique_symbol", candidates[0]["id"]
                resolution_counts["qualified_unique"] += 1
            elif candidates:
                certainty, target = "ambiguous", None
                resolution_counts["qualified_ambiguous"] += 1
            else:
                certainty, target = "unresolved", None
                resolution_counts["qualified_unresolved"] += 1
            db.execute("INSERT INTO relations (source_function,target_function,kind,certainty,module,source_path,line,expression,target_candidates_json) VALUES (?,?,?,?,?,?,?,?,?)",
                       (caller["id"] if caller else None, target, "lua_qualified_call_candidate", certainty,
                        name, source_path, line, receiver + ":" + method, json.dumps([x["id"] for x in candidates])))
            relation_counts["lua_qualified_call_candidate"] += 1
            if not candidates:
                db.execute("INSERT INTO unresolved (kind,module,source_path,line,expression,reason) VALUES (?,?,?,?,?,?)",
                           ("lua_qualified_call_candidate", name, source_path, line, receiver + ":" + method,
                            "调用接收者可能是动态对象、外部桥接或缺失的模块/继承定义"))

        # AST-only call forms that the legacy regex layer did not represent.
        regex_call_starts = {m.start() for m in CALL_RE.finditer(masked)}
        regex_call_starts.update(m.start() for m in QUALIFIED_CALL_RE.finditer(masked))
        for start, end, node_type, text_name in ast.get("calls", []):
            if start in regex_call_starts:
                continue
            caller = nearest(start)
            line = line_at(source, start)
            if node_type == "identifier":
                kind, expression, candidates = "lua_bare_call_candidate", text_name, symbols.get(text_name, [])
            elif node_type == "dot_index_expression":
                method = text_name.rsplit(".", 1)[-1]
                kind, expression, candidates = "lua_dot_call_candidate", text_name, symbols.get(method, [])
                if not candidates:
                    candidates = symbols.get(text_name.replace(".", ":"), [])
            else:
                continue
            if len(candidates) == 1:
                certainty, target = "candidate_unique_symbol", candidates[0]["id"]
            elif candidates:
                certainty, target = "ambiguous", None
            else:
                certainty, target = "unresolved", None
            db.execute("INSERT INTO relations (source_function,target_function,kind,certainty,module,source_path,line,expression,target_candidates_json) VALUES (?,?,?,?,?,?,?,?,?)",
                       (caller["id"] if caller else None, target, kind, certainty, name, source_path, line,
                        expression, json.dumps([x["id"] for x in candidates])))
            relation_counts[kind] += 1
            if not candidates:
                db.execute("INSERT INTO unresolved (kind,module,source_path,line,expression,reason) VALUES (?,?,?,?,?,?)",
                           (kind, name, source_path, line, expression, "AST 调用目标可能是局部变量、外部桥接或动态函数值"))

        for match in EVENT_RE.finditer(masked):
            op, event = match.groups()
            caller = nearest(match.start())
            line = line_at(source, match.start())
            db.execute("INSERT INTO relations (source_function,target_function,kind,certainty,module,source_path,line,expression,target_candidates_json) VALUES (?,?,?,?,?,?,?,?,?)",
                       (caller["id"] if caller else None, None, "lua_event_dispatch", "confirmed_symbol_candidate_semantics",
                        name, source_path, line, event, "[]"))
            relation_counts["lua_event_dispatch"] += 1

        for match in REGISTER_RE.finditer(masked):
            op, event, receiver, callback = (part.strip() for part in match.groups())
            callback_match = re.search(r"\.([A-Za-z_]\w*)\s*$", callback)
            if not callback_match:
                continue
            method = callback_match.group(1)
            line = line_at(source, match.start())
            candidates = [item for item in definitions if item["symbol"].endswith((":" + method, "." + method))]
            db.execute("INSERT INTO relations (source_function,target_function,kind,certainty,module,source_path,line,expression,target_candidates_json) VALUES (?,?,?,?,?,?,?,?,?)",
                       (None, candidates[0]["id"] if len(candidates) == 1 else None,
                        "lua_event_callback_candidate", "candidate_unique_in_module" if len(candidates) == 1 else "ambiguous_or_unresolved",
                        name, source_path, line, event + " -> " + callback,
                        json.dumps([x["id"] for x in candidates])))
            relation_counts["lua_event_callback_candidate"] += 1
            if len(candidates) != 1:
                db.execute("INSERT INTO unresolved (kind,module,source_path,line,expression,reason) VALUES (?,?,?,?,?,?)",
                           ("lua_event_callback_candidate", name, source_path, line, event + " -> " + callback,
                            "回调可能通过继承、对象别名或运行时注册解析"))
                unresolved_counts["event_callback_not_unique"] += 1

    db.commit()
    summary = {
        "title": "阶段二 Lua 源码关系补充索引",
        "method": "Tree-sitter 解析健康度加字符串/注释屏蔽后的源码候选提取；所有调用目标均为候选关系，事件类型名及派发调用点是源码直接证据",
        "modules_total": len(modules), "source_states": dict(source_states),
        "parser_states": dict(parser_states),
        "function_declarations": db.execute("SELECT count(*) FROM functions").fetchone()[0],
        "relation_counts": dict(relation_counts), "resolution_counts": dict(resolution_counts),
        "unresolved_counts": dict(unresolved_counts),
        "bytecode_source_mapping": "未建立：现有函数原型 first_line/last_line 多为 0 或不能稳定对应反编译文本；以 source_path + decompiled line 定位阅读，不声称映射到字节码原型。",
        "limitations": [
            "字符串和注释已从词法扫描中屏蔽；Tree-sitter 用于识别函数声明范围和报告解析健康度。",
            "当前调用关系仍是保守候选；点调用、裸函数调用、匿名闭包以及动态索引需要后续 AST 语义层继续补齐。",
            "self 接收对象、类继承、混入、动态 require、反射和 C#/Lua 桥接目标仍可能改变实际目标。",
            "事件派发调用点已定位，但事件顺序、异步时机和运行时监听集合还需按场景追踪。",
        ],
        "database": str(path.relative_to(ROOT)).replace("\\", "/"),
    }
    (REPORT / "stage2_lua_relations_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    db.close()
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
