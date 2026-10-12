"""Index random selection, weighting, shuffling, and candidate mutation in Lua."""
from __future__ import annotations

import bisect
import hashlib
import json
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LUA_ROOT = ROOT / "analysis_data" / "logic_index" / "lua" / "decoded"
OUT = ROOT / "analysis_data" / "logic_index" / "stage2"
REPORT = ROOT / "analysis_output" / "logic_recovery" / "stage2"

FUNCTION_RE = re.compile(r"^\s*(?:local\s+)?function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(", re.M)
CALL_RE = re.compile(r"(?P<name>(?:Table\.)?(?:ListRandomSelectOne|ListRandomSelectN|ListAlwaysRandomSelectN|ListWeightSelectOne)|MathUtil\.RandomN|(?:math\.)?random|MathUtil\.Random|Random\.Range|GetMathRandomNumber|table\.remove|table\.insert|table\.sort|table\.shuffle|shuffle)\s*\(")
CONFIG_RE = re.compile(r"\b(?P<field>[A-Za-z_]\w*(?:Weight|_Weight|WeightType|_WeightType))\b")
NONCODE_RE = re.compile(r"--\[(=*)\[.*?\]\1\]|--[^\r\n]*|\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*'|\[(=*)\[.*?\]\2\]", re.S)

def mask_noncode(source: str) -> str:
    return NONCODE_RE.sub(lambda m: "".join("\n" if c == "\n" else " " for c in m.group()), source)

def matching_paren(masked: str, opening: int):
    depth = 0
    for i in range(opening, len(masked)):
        if masked[i] == "(": depth += 1
        elif masked[i] == ")":
            depth -= 1
            if depth == 0: return i
    return None

def split_args(raw: str, masked: str):
    out, start, p, b, c = [], 0, 0, 0, 0
    for i, ch in enumerate(masked):
        if ch == "(": p += 1
        elif ch == ")": p -= 1
        elif ch == "[": b += 1
        elif ch == "]": b -= 1
        elif ch == "{": c += 1
        elif ch == "}": c -= 1
        elif ch == "," and p == b == c == 0:
            out.append(raw[start:i].strip()); start = i + 1
    tail = raw[start:].strip()
    if tail or raw.strip(): out.append(tail)
    return out

def stable(*parts):
    return hashlib.sha256("\0".join(map(str, parts)).encode()).hexdigest()

def main():
    OUT.mkdir(parents=True, exist_ok=True); REPORT.mkdir(parents=True, exist_ok=True)
    db_path = OUT / "random_mechanisms.sqlite3"
    if db_path.exists(): db_path.unlink()
    db = sqlite3.connect(db_path)
    db.executescript("""
      PRAGMA journal_mode=OFF;
      CREATE TABLE mechanisms (
        id TEXT PRIMARY KEY, module TEXT NOT NULL, module_sha256 TEXT NOT NULL,
        function_symbol TEXT, source_path TEXT NOT NULL, line INTEGER NOT NULL,
        mechanism_kind TEXT NOT NULL, api_name TEXT NOT NULL, candidate_expression TEXT,
        quantity_expression TEXT, weight_expression TEXT, removal_evidence TEXT NOT NULL,
        replacement_status TEXT NOT NULL, certainty TEXT NOT NULL, code_excerpt TEXT NOT NULL
      );
      CREATE TABLE config_fields (
        id TEXT PRIMARY KEY, module TEXT NOT NULL, source_path TEXT NOT NULL, line INTEGER NOT NULL,
        function_symbol TEXT, field_name TEXT NOT NULL, context TEXT NOT NULL, code_excerpt TEXT NOT NULL
      );
      CREATE TABLE unresolved (
        id INTEGER PRIMARY KEY, source_path TEXT NOT NULL, line INTEGER NOT NULL,
        expression TEXT NOT NULL, reason TEXT NOT NULL, code_excerpt TEXT NOT NULL
      );
    """)
    counts = {}
    for source in sorted(LUA_ROOT.glob("*/decompiled.lua")):
        text = source.read_text(encoding="utf-8", errors="replace")
        masked = mask_noncode(text)
        lines = text.splitlines(); starts = [0]
        for m in re.finditer("\n", text): starts.append(m.end())
        funcs = [(m.start(), m.group(1)) for m in FUNCTION_RE.finditer(masked)]
        module = source.parent.name
        sha = hashlib.sha256(text.encode()).hexdigest()
        def current(pos):
            prior = [x for x in funcs if x[0] <= pos]
            return prior[-1][1] if prior else None
        # Calls are parsed with balanced parentheses so nested candidate expressions remain intact.
        for m in CALL_RE.finditer(masked):
            end = matching_paren(masked, m.end() - 1)
            if end is None:
                line = bisect.bisect_right(starts, m.start())
                db.execute("INSERT INTO unresolved VALUES(NULL,?,?,?,?,?)", (str(source), line, m.group("name"), "unbalanced call", lines[line-1] if line <= len(lines) else ""))
                continue
            raw_args = text[m.end():end]
            arg_mask = masked[m.end():end]
            args = split_args(raw_args, arg_mask)
            name = m.group("name")
            line = bisect.bisect_right(starts, m.start())
            fn = current(m.start())
            excerpt = lines[line-1] if line <= len(lines) else ""
            kind = "random_uniform"
            candidate = args[0] if args else ""
            quantity = args[1] if len(args) > 1 else ""
            weight = ""
            removal = "none"
            replacement = "unknown"
            certainty = "candidate"
            if "Weight" in name:
                kind = "weighted"
                weight = candidate
                replacement = "unknown"
            elif name == "table.remove":
                kind = "candidate_remove"
                candidate = args[0] if args else ""
                removal = "explicit_table_remove"
                replacement = "without_replacement_candidate_mutation"
                certainty = "high"
            elif name in ("table.insert", "table.sort", "table.shuffle", "shuffle"):
                kind = "candidate_mutation"
                replacement = "candidate_mutation"
            elif name in ("ListRandomSelectN", "Table.ListRandomSelectN", "ListAlwaysRandomSelectN", "Table.ListAlwaysRandomSelectN"):
                kind = "random_n"
                # The helper implementation is not assumed here; callers are linked to any nearby remove.
            # Look in the same function body window for deletion of the selected candidate.
            fn_start = next((p for p, n in reversed(funcs) if p <= m.start()), 0)
            fn_end = next((p for p, n in funcs if p > m.start()), len(text))
            body = masked[fn_start:fn_end]
            if name != "table.remove" and re.search(r"table\s*\.\s*remove\s*\(", body):
                removal = "same_function_table_remove"
                replacement = "likely_without_replacement"
                certainty = "medium"
            if name in ("math.random", "random", "MathUtil.Random", "Random.Range", "GetMathRandomNumber"):
                kind = "random_uniform"
            db.execute("INSERT INTO mechanisms VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (
                stable(module, m.start(), name), module, sha, fn, str(source), line, kind, name,
                candidate, quantity, weight, removal, replacement, certainty, excerpt))
            counts[kind] = counts.get(kind, 0) + 1
        for m in CONFIG_RE.finditer(masked):
            line = bisect.bisect_right(starts, m.start())
            fn = current(m.start())
            excerpt = lines[line-1] if line <= len(lines) else ""
            field = m.group("field")
            # Keep config fields that are likely selection configuration, including literal table definitions.
            db.execute("INSERT INTO config_fields VALUES(?,?,?,?,?,?,?,?)", (
                stable(module, "config", m.start(), field), module, str(source), line, fn, field,
                "field_or_literal_table", excerpt))
    db.execute("CREATE INDEX idx_mechanisms_kind ON mechanisms(mechanism_kind)")
    db.execute("CREATE INDEX idx_mechanisms_function ON mechanisms(function_symbol)")
    db.execute("CREATE INDEX idx_config_field ON config_fields(field_name)")
    # The shared Table helper has a recovered implementation: ListRandomSelectN
    # removes each selected element from the input list, so its callers inherit
    # without-replacement semantics (and source-list mutation) when N is smaller.
    db.execute("""UPDATE mechanisms SET removal_evidence='shared_helper_table_remove',
        replacement_status='without_replacement', certainty='high'
        WHERE api_name='Table.ListRandomSelectN'""")
    db.execute("""UPDATE mechanisms SET removal_evidence='shared_helper_deepcopy_remove',
        replacement_status='without_replacement_source_preserved', certainty='high'
        WHERE api_name='Table.ListAlwaysRandomSelectN'""")
    db.commit()
    summary = {
        "database": str(db_path), "mechanism_rows": db.execute("SELECT count(*) FROM mechanisms").fetchone()[0],
        "config_field_rows": db.execute("SELECT count(*) FROM config_fields").fetchone()[0],
        "unresolved_rows": db.execute("SELECT count(*) FROM unresolved").fetchone()[0],
        "by_kind": dict(db.execute("SELECT mechanism_kind,count(*) FROM mechanisms GROUP BY mechanism_kind")),
        "by_replacement_status": dict(db.execute("SELECT replacement_status,count(*) FROM mechanisms GROUP BY replacement_status")),
        "by_certainty": dict(db.execute("SELECT certainty,count(*) FROM mechanisms GROUP BY certainty")),
        "weighted_calls": db.execute("SELECT count(*) FROM mechanisms WHERE mechanism_kind='weighted'").fetchone()[0],
        "explicit_candidate_removals": db.execute("SELECT count(*) FROM mechanisms WHERE removal_evidence='explicit_table_remove'").fetchone()[0],
        "same_function_removal_candidates": db.execute("SELECT count(*) FROM mechanisms WHERE removal_evidence='same_function_table_remove'").fetchone()[0],
    }
    (REPORT / "stage2_random_mechanisms_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    md = ["# 随机与抽样机制索引", "", f"扫描 Lua 模块：{len(list(LUA_ROOT.glob('*/decompiled.lua')))}", f"机制记录：{summary['mechanism_rows']}", f"权重相关记录：{summary['weighted_calls']}", f"明确 `table.remove` 删除候选：{summary['explicit_candidate_removals']}", "", "## 已恢复的共享算法", "- `Table.ListRandomSelectN(source, selectCount)`：若 `selectCount >= #source` 直接返回 source；否则每次调用 `MathUtil.Random(#source)` 取 1-based 索引，将元素加入 results，再执行 `table.remove(source,index)`。因此 N 小于候选数时无放回且原地缩短 source；N 不小于候选数时返回整个 source。", "- `Table.ListAlwaysRandomSelectN(source, selectCount)`：先 `Table.DeepCopy(source)`，最多循环 `min(#source,selectCount)` 次，每次随机索引后从拷贝删除；无放回但不修改调用方 source。", "- `MathUtil.RandomN(n, selectCount)`：维护已选索引 map；第 i 次在 `1..n-i+1` 取随机位置，再按已选位置向右校正成原数组索引并标记，返回不重复索引列表。", "- `Table.ListRandomSelectOne(source)`：空表返回 nil，否则调用 `MathUtil.Random(#source)` 返回一个元素，不删除 source；重复调用允许重复结果。", "- `Table.ListWeightSelectOne(source, weightKey)`：默认字段 `Weight`，先求权重总和，要求总和大于 0；再取 1 到总和的整数随机数，按累计权重区间返回元素，不删除 source。", "- `MathUtil.Random(l,r)`：先取 `math.random()` 的 `[0,1)` 浮点值；单参数返回 `floor(CurRandom*l)+1`，双参数返回 `l+floor(CurRandom*(r-l+1))`，因此整数端点均包含。测试模式可由 `GM.TestModel:SetMathRandomLR` 把浮点区间改为 `[fCurLeft,fCurRight]`，默认 `[0,1]`。", "", "## 判定口径", "- `ListRandomSelectN` 已依据共享 helper 源码证据标为 without_replacement。", "- 其他删除点只有在随机索引和候选集合关系清楚时才升级为无放回；单独出现 `table.remove` 只证明候选表被修改。", "", "## 分类", json.dumps(summary["by_kind"], ensure_ascii=False, indent=2)]
    (REPORT / "STAGE2_RANDOM_MECHANISMS.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    db.close()
    print(json.dumps(summary, ensure_ascii=False, indent=2))

if __name__ == "__main__": main()
