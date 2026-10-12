"""Merge isolated per-seed simulation outputs into the standard report files."""

from __future__ import annotations

import csv
import json
from pathlib import Path

import run_terminal_simulation as simulation


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "analysis_output"


def main() -> None:
    result_files = sorted(OUTPUT.glob("tmp_*.json"))
    result_files = [path for path in result_files if not path.name.endswith("_typical.json")]
    payloads = [json.loads(path.read_text(encoding="utf-8")) for path in result_files]
    runs = [payload["runs"][0] for payload in payloads]
    runs.sort(key=lambda row: (list(simulation.PLAYER_LABELS).index(row["player_type"]), row["seed"]))

    daily_rows = []
    fieldnames = None
    for path in sorted(OUTPUT.glob("tmp_*_daily.csv")):
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            if fieldnames is None:
                fieldnames = reader.fieldnames
            daily_rows.extend(reader)
    daily_rows.sort(key=lambda row: (list(simulation.PLAYER_LABELS).index(row["player_type"]), int(row["run_id"]), int(row["day"])))

    metadata = payloads[0]["metadata"]
    metadata["runs"] = len(runs)
    metadata["known_approximations"][-1] = (
        "Order choice is recalculated after every action using order gold divided by "
        "base-equivalent order energy; producer-probability energy is retained as a "
        "separate diagnostic estimate."
    )
    result = {"metadata": metadata, "summary": simulation.summarize(runs), "runs": runs}
    (OUTPUT / "terminal_simulation_results.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    with (OUTPUT / "terminal_simulation_daily.csv").open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(daily_rows)

    typical_players = []
    for path in sorted(OUTPUT.glob("tmp_*_typical.json")):
        typical_players.extend(json.loads(path.read_text(encoding="utf-8"))["players"])
    typical_players.sort(key=lambda row: list(simulation.PLAYER_LABELS).index(row["player_type"]))
    (OUTPUT / "terminal_simulation_typical_days.json").write_text(
        json.dumps({
            "selection_method": "每类玩家使用首个固定种子；排除首尾日后，选择订单完成、支付、主线推进三类事件计数最接近各自日中位数的日期，并优先要求三类事件均出现。",
            "players": typical_players,
        }, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"merged runs={len(runs)} daily_rows={len(daily_rows)} typical_players={len(typical_players)}")


if __name__ == "__main__":
    main()
