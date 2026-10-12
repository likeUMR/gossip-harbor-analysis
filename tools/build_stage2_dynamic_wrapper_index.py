"""Index direct effects in input wrapper functions whose callback target is dynamic.

This intentionally separates concrete effects in the wrapper from the unresolved
callee.  A UI/state/network operation found in the wrapper is evidence, but it
does not prove which object supplied a callback field.
"""
from __future__ import annotations

import hashlib
import json
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE2 = ROOT / "analysis_data/logic_index/stage2"
REPORT = ROOT / "analysis_output/logic_recovery/stage2"

EFFECTS = {
    "state_mutation": re.compile(r"(?:^|\s)(?:self|[A-Za-z_]\w*(?:\.[A-Za-z_]\w+)*)\s*\.\s*[A-Za-z_]\w*\s*=", re.M),
    "event_dispatch": re.compile(r"\b(?:EventDispatcher|EventUtil)\s*[:.]\s*(?:DispatchEvent|PostEvent|AddListener|RemoveListener)\s*\(", re.I),
    "network_call": re.compile(r"\b(?:ApiMessage|Api|Network|GM\s*\.\s*GameModel)\s*[:.]\s*[A-Za-z_]\w*\s*\(", re.I),
    "ui_effect": re.compile(r"\b(?:GM\s*\.\s*UIManager|UIUtil|SpriteUtil|DelayExecuteFuncInView|DOTween|AudioFileConfigName)\s*[:.]", re.I),
}
CALL = re.compile(r"\b(?:self|[A-Za-z_]\w*)(?:\.[A-Za-z_]\w+|:[A-Za-z_]\w+)+\s*\(")


def stable(*parts: object) -> str:
    return hashlib.sha256("\0".join(map(str, parts)).encode()).hexdigest()


def function_spans(lines: list[str]):
    """Return declaration name and conservative line span for Lua functions."""
    starts = []
    decl = re.compile(r"^\s*(?:local\s+)?function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(")
    for i, line in enumerate(lines):
        m = decl.match(line)
        if not m:
            continue
        depth = 0
        end = len(lines) - 1
        for j in range(i, len(lines)):
            code = re.sub(r"--.*$", "", lines[j])
            # This is only a boundary finder. Nested anonymous functions are
            # counted, while long strings and unusual syntax remain flagged by
            # the evidence quality field instead of being silently trusted.
            depth += len(re.findall(r"\bfunction\b|\bif\b|\bfor\b|\bwhile\b|\brepeat\b", code))
            depth -= len(re.findall(r"\bend\b|\buntil\b", code))
            if j > i and depth <= 0:
                end = j
                break
        starts.append((m.group(1), i, end))
    return starts


def main() -> None:
    gaps = json.loads((REPORT / "stage2_semantic_gaps.json").read_text(encoding="utf-8"))
    wanted = {g["function_symbol"] for g in gaps}
    out = STAGE2 / "dynamic_wrapper_effects.sqlite3"
    if out.exists():
        out.unlink()
    db = sqlite3.connect(out)
    db.executescript("""
      CREATE TABLE wrappers(id TEXT PRIMARY KEY,module TEXT,source_path TEXT,line INTEGER,
        function_symbol TEXT,quality TEXT,body TEXT);
      CREATE TABLE effects(id TEXT PRIMARY KEY,wrapper_id TEXT,effect_kind TEXT,line INTEGER,excerpt TEXT);
      CREATE TABLE dynamic_calls(id TEXT PRIMARY KEY,wrapper_id TEXT,line INTEGER,expression TEXT);
      CREATE INDEX wrapper_symbol ON wrappers(function_symbol);
    """)
    wrappers = []
    effects = []
    calls = []
    for src in sorted((ROOT / "analysis_data/logic_index/lua/decoded").glob("*/decompiled.lua")):
        lines = src.read_text(encoding="utf-8", errors="replace").splitlines()
        for symbol, start, end in function_spans(lines):
            candidates = {symbol, symbol.replace(":", ".")}
            if not (candidates & wanted):
                continue
            body = "\n".join(lines[start:end + 1])
            wid = stable(src, start, symbol)
            quality = "conservative_line_span"
            wrappers.append((wid, src.parent.name, str(src), start + 1, symbol, quality, body))
            for kind, pat in EFFECTS.items():
                for m in pat.finditer(body):
                    line = start + 1 + body[:m.start()].count("\n")
                    effects.append((stable(wid, kind, line, m.group(0)), wid, kind, line, m.group(0)[:240]))
            # Empty base hooks and guard-only handlers are meaningful evidence:
            # they prove that this class contributes no hidden click logic.
            meaningful = []
            for raw in lines[start + 1:end]:
                code = re.sub(r"--.*$", "", raw).strip()
                if not code or code in {"end", "then", "else"}:
                    continue
                if re.match(r"^(if|elseif|for|while|repeat|until)\b", code):
                    continue
                if re.match(r"^return\b", code):
                    continue
                meaningful.append(code)
            if not meaningful:
                effects.append((stable(wid, "explicit_noop", start + 1), wid, "explicit_noop", start + 1, "empty_or_guard_only_handler"))
            for m in CALL.finditer(body):
                line = start + 1 + body[:m.start()].count("\n")
                expr = m.group(0).strip()
                calls.append((stable(wid, line, expr), wid, line, expr))
    db.executemany("INSERT INTO wrappers VALUES(?,?,?,?,?,?,?)", wrappers)
    db.executemany("INSERT INTO effects VALUES(?,?,?,?,?)", effects)
    db.executemany("INSERT OR IGNORE INTO dynamic_calls VALUES(?,?,?,?)", calls)
    db.commit()
    summary = {
        "gap_functions_examined": len(wanted),
        "wrapper_functions_found": len(wrappers),
        "direct_effects": len(effects),
        "dynamic_calls": len(calls),
        "by_effect": dict(db.execute("SELECT effect_kind,count(*) FROM effects GROUP BY effect_kind")),
        "database": str(out.relative_to(ROOT)).replace("\\", "/"),
        "quality": "candidate_static_evidence",
        "limitations": [
            "Function boundaries are conservative line spans and should be checked against Lua AST/bytecode for unusual nested syntax.",
            "A direct effect proves the wrapper operation exists, but not the identity or lifetime of a dynamically supplied callback target.",
        ],
    }
    (REPORT / "stage2_dynamic_wrapper_effects_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (REPORT / "STAGE2_DYNAMIC_WRAPPER_EFFECTS.md").write_text(
        "# 动态包装器直接效果索引\n\n" + json.dumps(summary, ensure_ascii=False, indent=2) +
        "\n\n该索引把‘包装器中已经确定的效果’和‘被动态字段/配置表转交的目标仍未确定’分开记录。它不能替代对象身份、调用时序和运行时分支证明。\n",
        encoding="utf-8",
    )
    db.close()
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
