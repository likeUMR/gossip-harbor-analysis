"""Index event, callback, timer, coroutine, and bridge trigger sites in Lua."""
from __future__ import annotations
import collections, hashlib, json, re, sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "analysis_data" / "logic_index"
OUT = INDEX / "stage2"
REPORT = ROOT / "analysis_output" / "logic_recovery" / "stage2"
FUNCTION_RE = re.compile(r"^\s*(?:local\s+)?function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(", re.M)
EVENT_RE = re.compile(r"\bEventDispatcher\s*\.\s*(AddListener|RemoveListener|DispatchEvent|PostEvent)\s*\(", re.M)
ASYNC_RE = re.compile(r"\b(DelayExecuteFuncInView|DelayExecuteFunc|InsertCallback|OnComplete|StartCoroutine|coroutine\.create|coroutine\.wrap|coroutine\.yield|Schedule|SetTimeout|HttpGet|HttpPost|Request|SendRequest|AcquireRewardsInView)\s*\(", re.M)
BRIDGE_RE = re.compile(r"\b(CS\.[A-Za-z_][\w.]*|xlua\.[A-Za-z_]\w*|require\s*\()", re.M)

def stable_id(*parts):
    return hashlib.sha256("\0".join(map(str, parts)).encode()).hexdigest()

def mask_noncode(source):
    out = list(source); i, n, state = 0, len(source), "code"
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
            if source[i] in "'\"":
                state = source[i]; out[i] = " "; i += 1; continue
            i += 1; continue
        if source[i] == "\\":
            out[i] = " "; i += 1
            if i < n: out[i] = " "
        elif source[i] == state:
            out[i] = " "; i += 1; state = "code"
        else:
            if source[i] not in "\r\n": out[i] = " "
            i += 1
    return "".join(out)

def line_at(source, offset):
    return source.count("\n", 0, offset) + 1

def main():
    OUT.mkdir(parents=True, exist_ok=True); REPORT.mkdir(parents=True, exist_ok=True)
    db_path = OUT / "interaction_triggers.sqlite3"
    if db_path.exists(): db_path.unlink()
    db = sqlite3.connect(db_path)
    db.executescript("""
      PRAGMA journal_mode=OFF;
      PRAGMA synchronous=OFF;
      CREATE TABLE triggers (
        id TEXT PRIMARY KEY, module TEXT NOT NULL, module_sha256 TEXT NOT NULL,
        source_path TEXT NOT NULL, line INTEGER NOT NULL, function_symbol TEXT,
        trigger_kind TEXT NOT NULL, operation TEXT NOT NULL, callee TEXT NOT NULL,
        expression TEXT NOT NULL, callback_shape TEXT NOT NULL, code_excerpt TEXT NOT NULL
      );
      CREATE INDEX trigger_kind ON triggers(trigger_kind, operation);
      CREATE INDEX trigger_function ON triggers(function_symbol);
      CREATE INDEX trigger_callee ON triggers(callee);
    """)
    modules = json.loads((INDEX / "lua_modules.json").read_text(encoding="utf-8"))
    states, emitted = collections.Counter(), set()
    for module in modules:
        source_path = module.get("source_path", ""); path = ROOT / source_path
        if not path.is_file(): states["missing"] += 1; continue
        try: source = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError): states["unreadable"] += 1; continue
        states["available"] += 1; masked = mask_noncode(source)
        definitions = [(m.start(), m.group(1)) for m in FUNCTION_RE.finditer(masked)]
        for pattern, kind, op_group in ((EVENT_RE, "event", 1), (ASYNC_RE, "async_or_callback", 1), (BRIDGE_RE, "bridge", 1)):
            for match in pattern.finditer(masked):
                pos = match.start(); owner = None
                for start, symbol in definitions:
                    if start <= pos: owner = symbol
                    else: break
                callee = match.group(op_group)
                operation = callee if kind == "event" else ("lua_to_runtime_or_module" if kind == "bridge" else "schedule_or_callback")
                line = line_at(source, pos); end = source.find("\n", pos); end = len(source) if end < 0 else end
                excerpt = source[source.rfind("\n", 0, pos) + 1:end].strip()[:600]
                tail = masked[match.end():match.end() + 180]
                shape = "inline_function" if re.search(r"\bfunction\b", tail) else ("named_or_expression" if kind != "event" else "none")
                expression = source[pos:min(len(source), pos + 240)].split("\n", 1)[0].strip()
                ident = stable_id(module.get("sha256", ""), pos, kind, callee, expression)
                if ident in emitted: continue
                emitted.add(ident)
                db.execute("INSERT INTO triggers VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", (ident, module.get("name", ""), module.get("sha256", ""), source_path, line, owner, kind, operation, callee, expression, shape, excerpt))
    db.commit()
    summary = {
        "title": "阶段二玩家交互触发索引",
        "method": "对全部 Lua 模块进行字符串/注释屏蔽后的源码扫描，并按最近命名函数记录触发点；结果是定位候选，不等同于运行时必然执行",
        "modules": len(modules), "source_states": dict(states),
        "trigger_rows": db.execute("SELECT count(*) FROM triggers").fetchone()[0],
        "by_kind": {kind: count for kind, count in db.execute("SELECT trigger_kind,count(*) FROM triggers GROUP BY trigger_kind")},
        "by_operation": {f"{kind}/{operation}": count for kind, operation, count in db.execute("SELECT trigger_kind,operation,count(*) FROM triggers GROUP BY trigger_kind,operation")},
        "by_callback_shape": {shape: count for shape, count in db.execute("SELECT callback_shape,count(*) FROM triggers GROUP BY callback_shape")},
        "database": str(db_path.relative_to(ROOT)).replace("\\", "/"),
        "limitations": ["函数归属使用最近命名函数；匿名闭包和动态函数值需结合 AST/运行时继续确认。", "事件名、回调参数和延迟参数可能由表达式计算，当前保留原始行作为证据。"],
    }
    (REPORT / "stage2_interaction_triggers_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    db.close(); print(json.dumps(summary, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
