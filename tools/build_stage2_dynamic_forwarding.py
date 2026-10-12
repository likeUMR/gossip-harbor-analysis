"""Trace calls made through dynamically held Lua object fields.

This complements callback-field discovery: `self.m_window:OnStarClicked()` is
not a callback assignment, but it is still an important edge in an input path.
The index records the receiver field, method name, local assignments and global
method-name candidates without pretending that a field's runtime object type is
known.
"""
from __future__ import annotations

import collections
import hashlib
import json
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE2 = ROOT / "analysis_data/logic_index/stage2"
REPORT = ROOT / "analysis_output/logic_recovery/stage2"

DECL = re.compile(r"^\s*(?:local\s+)?function\s+(?P<name>[A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\((?P<args>[^)]*)\)")
FIELD_CALL = re.compile(r"(?P<receiver>(?:self|[A-Za-z_]\w*)(?:\.[A-Za-z_]\w+)*)\s*:\s*(?P<method>[A-Za-z_]\w*)\s*\(")
FIELD_ASSIGN = re.compile(r"^\s*(?P<receiver>self(?:\.[A-Za-z_]\w+)+)\s*=\s*(?P<rhs>.+?)\s*$")


def stable(*parts: object) -> str:
    return hashlib.sha256("\0".join(map(str, parts)).encode()).hexdigest()


def spans(lines: list[str]):
    for i, line in enumerate(lines):
        m = DECL.match(line)
        if not m:
            continue
        depth = 0
        end = len(lines) - 1
        for j in range(i, len(lines)):
            code = re.sub(r"--.*$", "", lines[j])
            depth += len(re.findall(r"\bfunction\b|\bif\b|\bfor\b|\bwhile\b|\brepeat\b", code))
            depth -= len(re.findall(r"\bend\b|\buntil\b", code))
            if j > i and depth <= 0:
                end = j
                break
        yield m.group("name"), [x.strip() for x in m.group("args").split(",") if x.strip()], i, end


def main() -> None:
    out = STAGE2 / "dynamic_forwarding.sqlite3"
    if out.exists():
        out.unlink()
    db = sqlite3.connect(out)
    db.executescript("""
      CREATE TABLE functions(id TEXT PRIMARY KEY,module TEXT,source_path TEXT,function_symbol TEXT,line INTEGER,args_json TEXT);
      CREATE TABLE assignments(id TEXT PRIMARY KEY,module TEXT,source_path TEXT,function_symbol TEXT,line INTEGER,receiver TEXT,rhs TEXT,assignment_kind TEXT);
      CREATE TABLE calls(id TEXT PRIMARY KEY,module TEXT,source_path TEXT,function_symbol TEXT,line INTEGER,receiver TEXT,method TEXT,expression TEXT);
      CREATE TABLE links(id TEXT PRIMARY KEY,call_id TEXT,assignment_id TEXT,certainty TEXT);
      CREATE TABLE method_candidates(method TEXT PRIMARY KEY,candidate_count INTEGER,candidates_json TEXT);
      CREATE INDEX forwarding_call_key ON calls(module,receiver);
    """)
    functions, assignments, calls = [], [], []
    method_map: collections.defaultdict[str, list[str]] = collections.defaultdict(list)
    for src in sorted((ROOT / "analysis_data/logic_index/lua/decoded").glob("*/decompiled.lua")):
        lines = src.read_text(encoding="utf-8", errors="replace").splitlines()
        for symbol, args, start, end in spans(lines):
            fid = stable(src, start, symbol)
            module = src.parent.name
            functions.append((fid, module, str(src), symbol, start + 1, json.dumps(args)))
            method_map[symbol.rsplit(":", 1)[-1].rsplit(".", 1)[-1]].append(symbol)
            body = lines[start:end + 1]
            for offset, raw in enumerate(body):
                line_no = start + 1 + offset
                am = FIELD_ASSIGN.match(raw)
                if am:
                    rhs = am.group("rhs").strip()
                    kind = "parameter" if rhs in args else ("function_literal" if rhs.startswith("function") else "expression")
                    assignments.append((stable(src, line_no, am.group("receiver")), module, str(src), symbol, line_no, am.group("receiver"), rhs, kind))
                for cm in FIELD_CALL.finditer(raw):
                    receiver = cm.group("receiver")
                    if receiver == "self" or not ("m_" in receiver or "callback" in receiver.lower() or "window" in receiver.lower() or "button" in receiver.lower() or "trigger" in receiver.lower() or receiver.endswith(".parent") or receiver.endswith("parent")):
                        continue
                    method = cm.group("method")
                    expr = f"{receiver}:{method}"
                    calls.append((stable(src, line_no, cm.start(), expr), module, str(src), symbol, line_no, receiver, method, expr))
    db.executemany("INSERT INTO functions VALUES(?,?,?,?,?,?)", functions)
    db.executemany("INSERT OR IGNORE INTO assignments VALUES(?,?,?,?,?,?,?,?)", assignments)
    db.executemany("INSERT OR IGNORE INTO calls VALUES(?,?,?,?,?,?,?,?)", calls)
    for method, candidates in method_map.items():
        db.execute("INSERT INTO method_candidates VALUES(?,?,?)", (method, len(candidates), json.dumps(sorted(candidates))))
    by_field = collections.defaultdict(list)
    for row in assignments:
        by_field[(row[1], row[5])].append(row)
    certainty_counts = collections.Counter()
    for call in calls:
        linked = by_field.get((call[1], call[5]), [])
        if linked:
            for assignment in linked:
                cert = "same_module_field_assignment_candidate" if len(linked) > 1 else "same_module_field_assignment"
                db.execute("INSERT OR IGNORE INTO links VALUES(?,?,?,?)", (stable(call[0], assignment[0]), call[0], assignment[0], cert))
                certainty_counts[cert] += 1
        candidates = method_map.get(call[6], [])
        certainty_counts["method_unique" if len(candidates) == 1 else ("method_ambiguous" if candidates else "method_unresolved")] += 1
    db.commit()
    summary = {
        "functions": len(functions), "assignments": len(assignments), "calls": len(calls),
        "links": db.execute("SELECT count(*) FROM links").fetchone()[0],
        "by_certainty": dict(certainty_counts),
        "receiver_fields": db.execute("SELECT count(DISTINCT receiver) FROM calls").fetchone()[0],
        "database": str(out.relative_to(ROOT)).replace("\\", "/"),
        "limitations": [
            "Field assignment and method-name matches are static candidates; they do not establish runtime object identity or inheritance dispatch.",
            "Calls through table indexes, locals captured by closures and C# objects require separate bridge/runtime evidence.",
        ],
    }
    (REPORT / "stage2_dynamic_forwarding_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (REPORT / "STAGE2_DYNAMIC_FORWARDING.md").write_text("# 动态对象字段转发索引\n\n" + json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    db.close()
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
