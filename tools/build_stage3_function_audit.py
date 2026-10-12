"""Build a source-function to leadership-document coverage audit.

This is a completeness gate, not a claim that a text mention explains a
function. It deliberately reports exact source function identifiers and leaves
manual review status visible for every function.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE3 = ROOT / "analysis_output" / "logic_recovery" / "stage3"
DOCS = STAGE3 / "mkdocs_site" / "docs"
OUT = ROOT / "analysis_output" / "logic_recovery" / "stage3"

MODULES = {
    "ItemSpread": STAGE3 / "Board_Model_Item_ItemSpread.lua",
    "MainBoardModel": STAGE3 / "Board_Model_Board_MainBoardModel.lua",
    "BaseActionBoardModel": STAGE3 / "Board_Model_Board_BaseActionBoardModel.lua",
    "BaseBoardModel": STAGE3 / "014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua",
    "LuckyProduceModel": STAGE3 / "937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua",
    "ItemSwallow": STAGE3 / "Board_Model_Item_ItemSwallow.lua",
    "ItemTransform": STAGE3 / "Board_Model_Item_ItemTransform.lua",
    "BaseOrder": STAGE3 / "Board_Model_Order_BaseOrder.lua",
    "MainOrder": STAGE3 / "Board_Model_Order_MainOrder.lua",
    "MainOrderModel": STAGE3 / "Board_Model_Order_MainOrderModel.lua",
    "SlotOrderModel": STAGE3 / "Board_Model_Order_SlotOrderModel.lua",
    "BaseOrderCell": STAGE3 / "Board_View_Order_BaseOrderCell.lua",
}

FUNC_RE = re.compile(r"^function\s+([\w.]+(?::[\w_]+)?)\s*\(")
CALL_RE = re.compile(r"\b(?:self|[A-Za-z_]\w*)\s*:\s*([A-Za-z_]\w*)\s*\(")
DOT_CALL_RE = re.compile(r"\b([A-Za-z_]\w*(?:\.[A-Za-z_]\w+)*)\s*\(")
TOKEN_RE = re.compile(r"\b(?:Spread_[A-Za-z0-9_]+|Lucky[A-Za-z0-9_]*|Order[A-Za-z0-9_]*|Bubble[A-Za-z0-9_]*|ItemSpreadState\.[A-Za-z_]+|BoardEventType\.[A-Za-z_]+|EEventType\.[A-Za-z_]+|m_[A-Za-z][A-Za-z0-9_]*)\b")


def source_functions() -> list[dict]:
    records: list[dict] = []
    for module, path in MODULES.items():
        if not path.exists():
            records.append({"module": module, "path": str(path), "missing_source": True})
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        starts = []
        for number, line in enumerate(lines, 1):
            match = FUNC_RE.match(line.strip())
            if not match:
                continue
            starts.append((number, match.group(1)))
        for index, (number, identifier) in enumerate(starts):
            end = (starts[index + 1][0] - 1) if index + 1 < len(starts) else len(lines)
            body = "\n".join(lines[number - 1:end])
            calls = sorted({m.group(1) for m in CALL_RE.finditer(body) if m.group(1) not in {"Create", "Init"}})
            dotted_calls = sorted({m.group(1) for m in DOT_CALL_RE.finditer(body) if not m.group(1).endswith(("if", "for", "while"))})
            tokens = sorted(set(TOKEN_RE.findall(body)))
            records.append({
                "module": module,
                "identifier": identifier,
                "path": str(path.relative_to(ROOT)).replace("\\", "/"),
                "line": number,
                "end_line": end,
                "body_lines": end - number + 1,
                "direct_method_calls": calls,
                "qualified_calls": dotted_calls[:80],
                "logic_tokens": tokens[:120],
                "source": "source-confirmed",
            })
    return records


def docs_text() -> str:
    chunks = []
    if DOCS.exists():
        for path in DOCS.rglob("*.md"):
            chunks.append(path.read_text(encoding="utf-8", errors="replace"))
    return "\n".join(chunks)


def classify(identifier: str) -> str:
    name = identifier.split(":")[-1].split(".")[-1]
    if name in {"OnTap", "_TrySpread", "CheckSpreadState", "CheckSpreadPosAndAuto", "CheckEnergy"}:
        return "generator-entry-and-gates"
    if "Spread" in name or "Energy" in name or "Recovery" in name or "Timer" in name:
        return "generator-lifecycle-and-position"
    if "Lucky" in name or "Conti" in name or "Free" in name:
        return "lucky"
    if "Order" in name or "Reward" in name or "Deliver" in name:
        return "orders"
    if "Merge" in name or "Drag" in name or "Affect" in name or "Bubble" in name or "Coin" in name:
        return "merge"
    return "shared-board-or-support"


def build() -> tuple[list[dict], dict]:
    text = docs_text()
    records = source_functions()
    for record in records:
        if record.get("missing_source"):
            record["documentation_status"] = "unavailable"
            continue
        identifier = record["identifier"]
        method = identifier.split(":")[-1]
        exact = identifier in text
        qualified_module = f"{record['module']}:{method}"
        qualified = qualified_module in text
        bare = re.search(rf"(?<![\w_]){re.escape(method)}(?![\w_])", text) is not None
        record["category"] = classify(identifier)
        record["mentioned_exactly"] = exact or qualified
        record["mentioned_bare"] = bare
        record["documentation_status"] = "mentioned" if (exact or qualified) else "unmentioned"
        record["review_required"] = True
    summary = {}
    for category in sorted({r.get("category", "missing") for r in records}):
        group = [r for r in records if r.get("category", "missing") == category]
        summary[category] = {
            "functions": len(group),
            "exactly_mentioned": sum(r.get("mentioned_exactly", False) for r in group),
            "unmentioned": sum(r.get("documentation_status") == "unmentioned" for r in group),
        }
    return records, summary


def main() -> None:
    records, summary = build()
    payload = {
        "game": "Gossip Harbor 3.98.10",
        "purpose": "stage3 source-function coverage gate",
        "source_modules": {name: str(path.relative_to(ROOT)).replace("\\", "/") for name, path in MODULES.items()},
        "summary": summary,
        "functions": records,
        "interpretation": "mentioned_exactly is only a navigation aid; extracted call and token fields are static leads, not proof of runtime reachability. Every function remains review_required until its trigger, branches, side effects, configuration and evidence are documented.",
    }
    json_path = OUT / "stage3_function_audit.json"
    json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    lines = [
        "# 阶段三逐函数核销审计",
        "",
        "这份清单把已恢复核心模块的每个 Lua 函数列出，并检查领导汇报文档是否至少出现了精确函数名。出现函数名不等于逻辑已经解释；`review_required` 在人工逐函数审阅完成前保持为 true。",
        "",
        f"函数总数：{len(records)}",
        "",
        "## 分类统计",
        "",
        "| 分类 | 函数数 | 文档精确提及 | 未提及 |",
        "|---|---:|---:|---:|",
    ]
    for category, data in summary.items():
        lines.append(f"| {category} | {data['functions']} | {data['exactly_mentioned']} | {data['unmentioned']} |")
    lines.extend(["", "## 未精确提及函数", "", "| 模块 | 函数 | 源码位置 | 类别 |", "|---|---|---|---|"])
    for record in records:
        if record.get("documentation_status") == "unmentioned":
            lines.append(f"| `{record['module']}` | `{record['identifier']}` | `{record['path']}:{record['line']}` | {record['category']} |")
    lines.extend(["", "## 直接关联索引（静态线索）", "", "每个函数记录源码区间、方法调用、限定调用和逻辑关键词。它们用于安排人工审阅，不等同于动态调用图，也不证明每个关键词在所有路径都生效。", "", "| 模块 | 函数 | 源码区间 | 直接方法调用 | 逻辑关键词 |", "|---|---|---|---|---|"])
    for record in records:
        if record.get("missing_source"):
            continue
        calls = ", ".join(f"`{x}`" for x in record.get("direct_method_calls", [])[:8]) or "-"
        tokens = ", ".join(f"`{x}`" for x in record.get("logic_tokens", [])[:10]) or "-"
        lines.append(f"| `{record['module']}` | `{record['identifier']}` | `{record['line']}-{record['end_line']}` | {calls} | {tokens} |")
    lines.extend(["", "## 使用口径", "", "- `source-confirmed` 表示函数来自已恢复源码。",
                  "- `mentioned` 只表示文档中出现了函数名，不证明触发链、分支、状态、副作用和配表已经完整解释。",
                  "- `unmentioned` 必须在阶段三出口前归属到操作链、后台入口、工具代码、遗留逻辑或明确的未追踪项。"])
    (OUT / "STAGE3_FUNCTION_AUDIT.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {OUT / 'STAGE3_FUNCTION_AUDIT.md'}")


if __name__ == "__main__":
    main()
