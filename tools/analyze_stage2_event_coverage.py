"""Summarize static event registration and dispatch coverage."""
from __future__ import annotations
import json, sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "analysis_data" / "logic_index" / "stage2" / "event_graph.sqlite3"
OUT = ROOT / "analysis_output" / "logic_recovery" / "stage2" / "stage2_event_coverage.json"

def main():
    db = sqlite3.connect(DB)
    rows = db.execute("""
      SELECT event_name,
        SUM(operation='AddListener'), SUM(operation='RemoveListener'),
        SUM(operation='DispatchEvent'), SUM(operation='PostEvent'),
        COUNT(*)
      FROM event_sites WHERE event_name IS NOT NULL
      GROUP BY event_name ORDER BY event_name
    """).fetchall()
    coverage = []
    for name, listeners, removals, dispatches, posts, total in rows:
        status = "balanced"
        if listeners == 0 and (dispatches or posts): status = "dispatch_without_listener"
        elif listeners and not (dispatches or posts): status = "listener_without_dispatch"
        coverage.append({
            "event_name": name, "add_listener": listeners, "remove_listener": removals,
            "dispatch_event": dispatches, "post_event": posts, "total_sites": total, "status": status,
        })
    unresolved = db.execute("SELECT reason, COUNT(*) FROM unresolved GROUP BY reason").fetchall()
    result = {
        "title": "阶段二静态事件覆盖矩阵",
        "event_names": len(coverage),
        "status_counts": {status: sum(row["status"] == status for row in coverage) for status in sorted({row["status"] for row in coverage})},
        "unresolved_by_reason": {reason: count for reason, count in unresolved},
        "events": coverage,
        "limitations": [
            "静态平衡不代表运行时一定可达；对象生命周期、条件注册和服务端事件仍需场景验证。",
            "动态事件表达式不在静态事件名矩阵中，但已保留在 event_graph.sqlite3 的 unresolved 表。",
        ],
    }
    OUT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    db.close()
    print(json.dumps({k: result[k] for k in ("event_names", "status_counts", "unresolved_by_reason")}, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
