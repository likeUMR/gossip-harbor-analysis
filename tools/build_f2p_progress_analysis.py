"""Build story gold costs and the task inputs used by the simulation."""

import json
import subprocess
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LUA = ROOT / "analysis_data" / "lua-compatible.exe"
CONFIG = ROOT / "analysis_data" / "lua_modules" / "Data" / "Config"
OUTPUT = ROOT / "analysis_output"


def load_lua(name):
    result = subprocess.run(
        [str(LUA), str(ROOT / "tools" / "dump_lua_table.lua"), str(CONFIG / f"{name}.luac")],
        check=True,
        capture_output=True,
    )
    return json.loads(result.stdout.decode("utf-8"))


def main():
    tasks = load_lua("MainTaskConfig")
    levels = load_lua("LevelConfig")
    by_day = defaultdict(list)
    for task in tasks:
        by_day[task["day"]].append(task)

    days = []
    nodes = []
    cumulative = 0
    for day in sorted(by_day):
        entries = sorted(
            by_day[day],
            key=lambda task: task["id"] if isinstance(task["id"], int) else 10**9,
        )
        daily_cost = 0
        for task in entries:
            cost = int(task.get("cost", 0))
            daily_cost += cost
            cumulative += cost
            nodes.append({
                "day": day,
                "id": task["id"],
                "cost": cost,
                "cumulative": cumulative,
                "rewards": task.get("rewards", []),
            })
        days.append({
            "day": day,
            "tasks": len(entries),
            "cost": daily_cost,
            "cumulative": cumulative,
        })

    data = {
        "version": "3.98.10 local Lua_Config snapshot",
        "task_count": len(tasks),
        "story_days": len(days),
        "total_gold": cumulative,
        "days": days,
        "nodes": nodes,
        "level_rewards": [
            {"level": row["level"], "cost_exp": row["cost"], "rewards": row.get("rewards", [])}
            for row in levels
        ],
    }
    OUTPUT.mkdir(exist_ok=True)
    (OUTPUT / "f2p_progress_data.json").write_text(
        json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"{len(tasks)} tasks, {len(days)} story days, {cumulative} nominal gold")


if __name__ == "__main__":
    main()
