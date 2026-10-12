"""Build the standalone HTML report for the terminal main-board simulation."""

from __future__ import annotations

import base64
import csv
import json
import statistics
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "analysis_output"
DAY_SECONDS = 86_400
RESULTS_PATH = OUTPUT / "terminal_simulation_results.json"
F2P_DATA_PATH = OUTPUT / "f2p_progress_data.json"
DAILY_PATH = OUTPUT / "terminal_simulation_daily.csv"
REPORT_PATH = OUTPUT / "gossip_harbor_terminal_simulation.html"
GOLD_CHART_PATH = OUTPUT / "terminal_simulation_cumulative_gold.png"
TASK_CHART_PATH = OUTPUT / "terminal_simulation_main_tasks.png"
TYPICAL_DAYS_PATH = OUTPUT / "terminal_simulation_typical_days.json"
TYPICAL_DAY_CHART_PATHS = {
    player: OUTPUT / f"terminal_simulation_typical_day_{player}.png"
    for player in ("zero", "mid", "top")
}


def stats(values: list[float]) -> dict[str, float]:
    return {
        "mean": statistics.mean(values),
        "median": statistics.median(values),
        "min": min(values),
        "max": max(values),
    }


def build_chart_series(results: dict, daily_path: Path) -> tuple[dict, int]:
    raw: dict[str, dict[int, dict[int, tuple[int, int]]]] = defaultdict(lambda: defaultdict(dict))
    with daily_path.open(encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            raw[row["player_type"]][int(row["run_id"])][int(row["day"])] = (
                int(row["cumulative_gold_earned"]),
                int(row["cumulative_main_tasks_completed"]),
            )

    run_lookup = {(run["player_type"], run["seed"]): run for run in results["runs"]}
    max_day = max(int(run["completion_days"]) + 1 for run in results["runs"])
    chart = {}
    for player in ("zero", "mid", "top"):
        run_ids = sorted(raw[player])
        metrics = {"gold": [], "tasks": []}
        final_values = {
            run_id: (run_lookup[(player, run_id)]["gold_earned"], run_lookup[(player, run_id)]["tasks_completed"])
            for run_id in run_ids
        }
        for day in range(1, max_day + 1):
            day_gold = []
            day_tasks = []
            for run_id in run_ids:
                value = raw[player][run_id].get(day)
                if value is None:
                    latest_day = max(raw[player][run_id])
                    if day > latest_day:
                        value = final_values[run_id]
                    else:
                        prior = [d for d in raw[player][run_id] if d <= day]
                        value = raw[player][run_id][max(prior)] if prior else (0, 0)
                day_gold.append(value[0])
                day_tasks.append(value[1])
            for key, values in (("gold", day_gold), ("tasks", day_tasks)):
                metrics[key].append([
                    round(statistics.mean(values), 2),
                    min(values),
                    max(values),
                ])
        chart[player] = metrics
    return chart, max_day


def build_inventory_summary(results: dict) -> list[dict]:
    rows = []
    for player in ("zero", "mid", "top"):
        runs = [run for run in results["runs"] if run["player_type"] == player]
        item_meta = {}
        inventories = []
        for run in runs:
            inventory = {item["code"]: item for item in run["inventory"]}
            inventories.append(inventory)
            for item in run["inventory"]:
                item_meta[item["code"]] = item
        for code, meta in sorted(item_meta.items(), key=lambda pair: (pair[1]["series"], pair[1]["level"])):
            counts = [inventory.get(code, {}).get("count", 0) for inventory in inventories]
            equivalents = [inventory.get(code, {}).get("base_equivalent", 0) for inventory in inventories]
            rows.append({
                "player_type": player,
                "code": code,
                "name": meta["name"],
                "series": meta["series"],
                "level": meta["level"],
                "count": stats(counts),
                "base_equivalent": stats(equivalents),
            })
    return rows


def build_static_chart(chart: dict, metric: str, output_path: Path) -> None:
    import matplotlib.pyplot as plt
    from matplotlib.ticker import FuncFormatter, MaxNLocator

    plt.rcParams.update({
        "font.family": "sans-serif",
        "font.sans-serif": ["Microsoft YaHei", "SimHei", "Arial"],
        "axes.unicode_minus": False,
        "font.size": 10,
    })
    players = {
        "zero": ("0氪金玩家", "#167552"),
        "mid": ("中氪金玩家", "#3876b9"),
        "top": ("顶氪金玩家", "#b65d14"),
    }
    title = "日期 - 累计金币获取" if metric == "gold" else "日期 - 主线完成次数"
    unit = "累计金币" if metric == "gold" else "累计完成主线任务数"
    fig, axes = plt.subplots(1, 2, figsize=(16, 6), dpi=160)
    for axis, (limit, panel_title) in zip(axes, ((None, "完整周期"), (365, "前 365 天"))):
        for player, (label, color) in players.items():
            values = chart[player][metric]
            count = len(values) if limit is None else min(limit, len(values))
            days = list(range(1, count + 1))
            means = [row[0] for row in values[:count]]
            lows = [row[1] for row in values[:count]]
            highs = [row[2] for row in values[:count]]
            axis.fill_between(days, lows, highs, color=color, alpha=0.11, linewidth=0)
            axis.plot(days, means, color=color, linewidth=1.9, label=label)
        axis.set_title(panel_title, fontsize=12, fontweight="bold", pad=10)
        axis.set_xlabel("模拟日期（第 N 天）")
        axis.set_ylabel(unit)
        axis.set_xlim(1, count)
        axis.set_ylim(bottom=0)
        axis.grid(axis="y", color="#dfe7e2", linewidth=0.8)
        axis.spines[["top", "right"]].set_visible(False)
        axis.spines[["left", "bottom"]].set_color("#aebbb4")
        axis.yaxis.set_major_locator(MaxNLocator(nbins=6))
        axis.yaxis.set_major_formatter(FuncFormatter(lambda value, _: f"{value:,.0f}"))
    handles, labels = axes[0].get_legend_handles_labels()
    fig.legend(handles, labels, loc="upper center", bbox_to_anchor=(0.5, 0.925), frameon=False, ncol=3)
    fig.suptitle(f"{title}（10 局均值与最小值-最大值范围）", fontsize=15, fontweight="bold", y=0.98)
    fig.text(0.5, 0.015, "实线为 10 个固定种子的均值，半透明带为样本最小值至最大值；已完成玩家保持在最终值。", ha="center", color="#607068")
    fig.tight_layout(rect=(0.02, 0.055, 0.99, 0.87), w_pad=3)
    fig.savefig(output_path, bbox_inches="tight", facecolor="white")
    plt.close(fig)


def build_typical_day_chart(typical_day: dict, output_path: Path) -> None:
    import matplotlib.pyplot as plt
    from matplotlib.lines import Line2D

    plt.rcParams.update({
        "font.family": "sans-serif",
        "font.sans-serif": ["Microsoft YaHei", "SimHei", "Arial"],
        "axes.unicode_minus": False,
        "font.size": 10,
    })
    styles = {
        "order_complete": ("o", "订单完成", "#167552", 2),
        "payment": ("v", "钻石支付", "#b65d14", 1),
        "main_progress": ("s", "剧情推进", "#3876b9", 0),
    }
    events = sorted(typical_day["events"], key=lambda event: (event["second_of_day"], event["type"]))
    login_events = [event for event in events if event["type"] == "login"]
    key_events = [event for event in events if event["type"] in styles]
    session_count = max(1, len(login_events))
    fig_height = max(7.6, 2.0 + session_count * 0.58)
    fig = plt.figure(figsize=(19, fig_height), dpi=160)
    grid = fig.add_gridspec(1, 2, width_ratios=(4.35, 1.65), wspace=0.08)
    axis = fig.add_subplot(grid[0, 0])
    detail_axis = fig.add_subplot(grid[0, 1])

    dense_day = len(key_events) > 200
    for event in login_events:
        hour = event["second_of_day"] / 3600
        axis.axvline(hour, color="#87958e", linewidth=1.0, linestyle=(0, (3, 4)), zorder=0)
        axis.text(hour, 2.52, f"{int(hour):02d}:{int(hour % 1 * 60):02d}", rotation=90,
                  ha="right", va="top", fontsize=7, color="#68756f")
    for kind, (marker, _, color, lane) in styles.items():
        selected = [event for event in events if event["type"] == kind]
        is_dense_payment = dense_day and kind == "payment"
        xs = [event["second_of_day"] / 3600 for event in selected]
        if selected:
            axis.vlines(
                xs, lane - 0.22, lane + 0.22, color=color,
                linewidth=0.55 if is_dense_payment else 0.9,
                alpha=0.20 if is_dense_payment else 0.42, zorder=2,
            )
        axis.scatter(
            xs, [lane] * len(selected),
            marker=marker,
            s=11 if is_dense_payment else (30 if dense_day else 42),
            color=color,
            alpha=0.32 if is_dense_payment else 0.92,
            edgecolors="none" if is_dense_payment else "white",
            linewidths=0 if is_dense_payment else 0.7,
            zorder=3 if is_dense_payment else 4,
        )

    # Every key event remains a plotted node. Labels are sampled on busy days; the
    # complete details, including energy, remain available in the exported JSON.
    if len(key_events) <= 15:
        labelled_events = key_events
    else:
        labelled_events = []
        for kind, quota in {"order_complete": 7, "payment": 4, "main_progress": 7}.items():
            selected = [event for event in key_events if event["type"] == kind]
            if len(selected) <= quota:
                labelled_events.extend(selected)
            elif selected:
                indices = sorted({round(index * (len(selected) - 1) / (quota - 1)) for index in range(quota)})
                labelled_events.extend(selected[index] for index in indices)
        labelled_events.sort(key=lambda event: event["second_of_day"])

    lane_label_levels = defaultdict(int)
    for event in labelled_events:
        x = event["second_of_day"] / 3600
        _, _, color, lane = styles[event["type"]]
        level = lane_label_levels[event["type"]] % 3
        lane_label_levels[event["type"]] += 1
        if event["type"] == "order_complete":
            label = f"{event['subtype']}\n体力 {event['energy']:g}"
            offset, va = 12 + level * 15, "bottom"
        elif event["type"] == "payment":
            label = f"{event['diamonds']:,}钻\n体力 {event['energy']:g}"
            offset, va = -(12 + level * 15), "top"
        else:
            label = f"+{event['tasks_advanced']}任务\n体力 {event['energy']:g}"
            offset, va = -(12 + level * 15), "top"
        axis.annotate(
            label, (x, lane), xytext=(0, offset), textcoords="offset points",
            ha="center", va=va, fontsize=6.5, color=color, linespacing=1.05,
            bbox={"boxstyle": "round,pad=0.12", "facecolor": "white", "edgecolor": "none", "alpha": 0.78},
            zorder=5,
        )
    if events:
        first_hour = max(0, int(min(event["second_of_day"] for event in events) // 3600) - 1)
        last_hour = min(24, int(max(event["second_of_day"] for event in events) // 3600) + 2)
    else:
        first_hour, last_hour = 0, 24
    tick_step = 1 if last_hour - first_hour <= 14 else 2
    axis.set_xlim(first_hour, last_hour)
    ticks = list(range(first_hour, last_hour + 1, tick_step))
    axis.set_xticks(ticks, [f"{hour:02d}:00" for hour in ticks])
    axis.set_ylim(-0.62, 2.62)
    axis.set_yticks([0, 1, 2], ["剧情推进", "钻石支付", "订单完成"])
    axis.set_ylabel("事件类型")
    axis.set_xlabel("一天中的时间")
    axis.grid(axis="x", color="#e2e9e5", linewidth=0.8)
    axis.grid(axis="y", color="#edf1ef", linewidth=0.8)
    axis.spines[["top", "right"]].set_visible(False)
    axis.spines[["left", "bottom"]].set_color("#aebbb4")
    counts = typical_day["event_counts"]
    handles = [
        Line2D([0], [0], marker=marker, color="none", markerfacecolor=color, markeredgecolor="white",
               markersize=8, label=f"{label}（{counts.get(kind, 0)}）")
        for kind, (marker, label, color, _) in styles.items()
    ]
    handles.insert(0, Line2D([0], [0], color="#87958e", linestyle=(0, (3, 4)), label="计划登录"))
    axis.legend(handles=handles, loc="upper left", ncol=2, frameon=False)

    sessions = []
    for index, login in enumerate(login_events):
        # Report each row as the interval ending at this login: this makes the
        # energy pair meaningful (previous整点 -> current整点) instead of
        # comparing a login snapshot with the last recorded action in a session.
        current_time = login["second_of_day"]
        previous_login = login_events[index - 1] if index > 0 else None
        if previous_login is None:
            start = current_time
            session_events = []
            energy_text = f"起始体力 {login['energy']:g}"
        else:
            start = previous_login["second_of_day"]
            session_events = [
                event for event in events
                if start <= event["second_of_day"] < current_time
                and event["type"] != "login"
            ]
            energy_text = f"体力 {previous_login['energy']:g} -> {login['energy']:g}"
        orders = [event for event in session_events if event["type"] == "order_complete"]
        payments = [event for event in session_events if event["type"] == "payment"]
        progress = [event for event in session_events if event["type"] == "main_progress"]
        order_groups: dict[str, list[dict]] = defaultdict(list)
        for event in orders:
            order_groups[event["subtype"]].append(event)
        order_text = "；".join(
            f"{kind} {len(group)}单/{sum(event['gold'] for event in group):,}金"
            for kind, group in sorted(order_groups.items())
        ) or "无"
        payment_groups = defaultdict(list)
        payment_labels = {
            "energy": "体力", "shop_items": "商店", "bubble_items": "气泡", "producer_speedup": "加速",
        }
        for event in payments:
            payment_groups[event["subtype"]].append(event["diamonds"])
        payment_text = "；".join(
            f"{payment_labels.get(kind, kind)} {len(values)}次/{sum(values):,}钻"
            for kind, values in sorted(payment_groups.items())
        ) or "无"
        progress_text = (
            f"{sum(event['tasks_advanced'] for event in progress):,}任务/"
            f"{sum(event['gold_spent'] for event in progress):,}金"
            if progress else "无"
        )
        sessions.append(
            f"{int(current_time // 3600):02d}:{int(current_time % 3600 // 60):02d}  "
            f"{energy_text}\n"
            f"订单  {order_text}\n"
            f"支付  {payment_text}\n"
            f"主线  {progress_text}"
        )
    detail_axis.axis("off")
    detail_axis.set_title("各次上线事件明细", loc="left", fontsize=11, fontweight="bold", pad=10)
    detail_axis.text(
        0, 1, "\n\n".join(sessions), transform=detail_axis.transAxes,
        ha="left", va="top", fontsize=7.7, linespacing=1.30, wrap=True,
        bbox={"boxstyle": "round,pad=0.55", "facecolor": "#f5f8f6", "edgecolor": "#d9e2dd"},
    )
    fig.suptitle(
        f"{typical_day['player_label']}典型日：第 {typical_day['day']} 天（{typical_day['date']}）",
        fontsize=16, fontweight="bold", y=0.985,
    )
    fig.text(
        0.5,
        0.015,
        f"固定种子 {typical_day['seed']} · 全部关键事件按类型落点；体力保存在节点数据中，合成操作不单独记录。",
        ha="center",
        color="#607068",
    )
    fig.subplots_adjust(left=0.055, right=0.985, top=0.91, bottom=0.10)
    fig.savefig(output_path, facecolor="white")
    plt.close(fig)


def main() -> None:
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--results", type=Path, default=RESULTS_PATH)
    parser.add_argument("--f2p-data", type=Path, default=F2P_DATA_PATH)
    parser.add_argument("--daily", type=Path, default=DAILY_PATH)
    parser.add_argument("--report", type=Path, default=REPORT_PATH)
    parser.add_argument("--gold-chart", type=Path, default=GOLD_CHART_PATH)
    parser.add_argument("--tasks-chart", type=Path, default=TASK_CHART_PATH)
    parser.add_argument("--typical-days", "--typical-day", dest="typical_days", type=Path, default=TYPICAL_DAYS_PATH)
    args = parser.parse_args()
    results = json.loads(args.results.read_text(encoding="utf-8"))
    f2p = json.loads(args.f2p_data.read_text(encoding="utf-8"))
    if any(run["gold_spent"] != f2p["total_gold"] or run["tasks_completed"] != f2p["task_count"] for run in results["runs"]):
        raise ValueError("Story cost data differs from completed simulation runs")
    chart, max_day = build_chart_series(results, args.daily)
    build_static_chart(chart, "gold", args.gold_chart)
    build_static_chart(chart, "tasks", args.tasks_chart)
    typical_days = json.loads(args.typical_days.read_text(encoding="utf-8"))
    typical_day_lookup = {row["player_type"]: row for row in typical_days["players"]}
    for player, output_path in TYPICAL_DAY_CHART_PATHS.items():
        build_typical_day_chart(typical_day_lookup[player], output_path)
    inventory_summary = build_inventory_summary(results)
    payload = {
        "metadata": results["metadata"],
        "summary": results["summary"],
        "runs": results["runs"],
        "chart": chart,
        "max_day": max_day,
        "inventory_summary": inventory_summary,
        "typical_days": typical_days,
        "story": {
            "task_count": f2p["task_count"],
            "story_days": f2p["story_days"],
            "total_gold": f2p["total_gold"],
            "days": [{key: day[key] for key in ("day", "tasks", "cost", "cumulative")} for day in f2p["days"]],
            "nodes": [{key: node[key] for key in ("day", "id", "cost", "cumulative")} for node in f2p["nodes"]],
        },
    }
    data = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    gold_image = base64.b64encode(args.gold_chart.read_bytes()).decode("ascii")
    task_image = base64.b64encode(args.tasks_chart.read_bytes()).decode("ascii")
    typical_day_images = {
        player: base64.b64encode(path.read_bytes()).decode("ascii")
        for player, path in TYPICAL_DAY_CHART_PATHS.items()
    }
    html = (TEMPLATE
            .replace("__REPORT_DATA__", data)
            .replace("__GOLD_CHART_IMAGE__", gold_image)
            .replace("__TASK_CHART_IMAGE__", task_image)
            .replace("__TYPICAL_DAY_ZERO_IMAGE__", typical_day_images["zero"])
            .replace("__TYPICAL_DAY_MID_IMAGE__", typical_day_images["mid"])
            .replace("__TYPICAL_DAY_TOP_IMAGE__", typical_day_images["top"]))
    html = html.replace(
        "免费母体冷却完毕会立即唤起操作，即使当时离线。",
        "免费母体冷却完毕后等待下一次计划登录，不会在凌晨或其它离线时段唤醒玩家。",
    ).replace(
        "每次动作后按订单金币除以从零库存生产整单的预期体力排序，优先处理比值最高的订单。",
        "每次动作后按订单金币除以等级等价值排序体力，优先处理比值最高的订单；母体概率生产体力只作为诊断值。",
    )
    args.report.write_text(html, encoding="utf-8")
    print(f"Wrote {args.report} ({args.report.stat().st_size:,} bytes)")


TEMPLATE = r'''<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Gossip Harbor 主棋盘终极模拟</title>
<style>
:root{--bg:#f4f7f5;--surface:#fff;--ink:#17211c;--muted:#607068;--line:#d9e2dd;--green:#167552;--green2:#49a67e;--orange:#b65d14;--blue:#3876b9;--red:#b84c4c}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:14px/1.55 system-ui,-apple-system,"Segoe UI","Microsoft YaHei",sans-serif;letter-spacing:0}header{background:#153f31;color:white;padding:30px 24px 26px}.wrap{width:min(1440px,calc(100% - 32px));margin:auto}h1{font-size:28px;line-height:1.2;margin:0 0 8px}header p{margin:0;color:#dcebe5}.nav{display:flex;gap:8px;flex-wrap:wrap;margin-top:18px}.nav a{color:white;text-decoration:none;border:1px solid #70988a;padding:6px 10px;border-radius:4px}main{padding:20px 0 42px}section{margin:0 0 26px}h2{font-size:20px;margin:0 0 12px}h3{font-size:16px;margin:0 0 8px}.lead{font-size:15px;max-width:1050px}.notice{border-left:4px solid var(--orange);background:#fff7ef;padding:12px 14px;margin:14px 0}.kpis{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}.kpi,.panel{background:var(--surface);border:1px solid var(--line);border-radius:7px}.kpi{padding:16px}.kpi strong{display:block;font-size:24px;line-height:1.2;margin:5px 0;color:var(--green)}.kpi span,.small{color:var(--muted)}.grid2{display:grid;grid-template-columns:1fr 1fr;gap:14px}.panel{padding:16px}.chart-head{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:8px}.seg{display:flex;border:1px solid var(--line);border-radius:5px;overflow:hidden;flex:none}.seg button{border:0;border-right:1px solid var(--line);background:#fff;padding:6px 9px;cursor:pointer}.seg button:last-child{border:0}.seg button.active{background:var(--green);color:#fff}.chart-wrap{position:relative;height:330px}.chart-wrap canvas{width:100%;height:100%;display:block}.legend{display:flex;gap:14px;flex-wrap:wrap;margin-top:8px;color:var(--muted)}.legend i{display:inline-block;width:12px;height:3px;margin-right:5px;vertical-align:middle}.table-wrap{overflow:auto;max-height:520px;border:1px solid var(--line);border-radius:6px;background:#fff}table{border-collapse:collapse;width:100%;min-width:760px}th,td{padding:8px 10px;border-bottom:1px solid #e8eeea;text-align:left;white-space:nowrap}th{position:sticky;top:0;background:#eef4f1;z-index:1;font-weight:600}td.num,th.num{text-align:right}tr:hover td{background:#f7faf8}.controls{display:flex;gap:10px;align-items:end;flex-wrap:wrap;margin:0 0 10px}.controls label{display:grid;gap:3px;color:var(--muted)}select,input{height:34px;border:1px solid #bdc9c3;border-radius:4px;background:#fff;padding:0 9px;color:var(--ink)}.breakdown{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}.bar-row{display:grid;grid-template-columns:88px 1fr 92px;gap:8px;align-items:center;margin:8px 0}.bar{height:9px;background:#e8eeea;border-radius:3px;overflow:hidden}.bar b{display:block;height:100%;background:var(--green2)}.method{columns:2;column-gap:32px}.method p{break-inside:avoid;margin:0 0 12px}.tag{display:inline-block;padding:2px 6px;border-radius:3px;font-size:12px;background:#e7f2ed;color:#126246;margin-right:5px}.tag.assume{background:#fff0df;color:#94500f}.tag.limit{background:#fbe9e9;color:#943d3d}footer{color:var(--muted);border-top:1px solid var(--line);padding:18px 0 30px}code{font-family:ui-monospace,Consolas,monospace}.nowrap{white-space:nowrap}@media(max-width:900px){.kpis,.breakdown,.grid2{grid-template-columns:1fr}.method{columns:1}.chart-wrap{height:280px}}@media(max-width:560px){.wrap{width:min(100% - 20px,1440px)}header{padding:24px 10px 20px}h1{font-size:23px}.kpi strong{font-size:21px}.panel{padding:12px}.chart-head{display:block}.seg{margin-top:8px;width:max-content}.chart-wrap{height:250px}.bar-row{grid-template-columns:72px 1fr 78px}}
.static-chart{margin:0 0 14px;padding:10px;background:#fff;border:1px solid var(--line);border-radius:7px}.static-chart img{display:block;width:100%;height:auto}.static-chart figcaption{padding:6px 4px 0;color:var(--muted)}
.tabs{display:flex;gap:4px;border-bottom:1px solid var(--line);margin:0 0 20px;overflow-x:auto}.tab{border:0;border-bottom:2px solid transparent;background:transparent;padding:10px 16px;white-space:nowrap;cursor:pointer;font:inherit;color:var(--muted)}.tab[aria-selected="true"]{border-bottom-color:var(--green);color:var(--green);font-weight:650}.tab-panel[hidden]{display:none}.story-stats{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px;margin:12px 0 20px}.story-bars{display:flex;align-items:end;gap:2px;height:200px;min-width:850px;border-bottom:1px solid #829b96}.story-bars i{flex:1;min-width:2px;background:var(--green)}.story-bars i:hover{background:var(--orange)}.story-chart-scroll{overflow-x:auto}.story-table td{white-space:normal}.story-table td.num{white-space:nowrap}.setting-list{margin:0;padding-left:21px}.setting-list li{margin:0 0 9px}.setting-list strong{color:var(--ink)}@media(max-width:700px){.story-stats{grid-template-columns:1fr}.tabs{margin-left:-2px;margin-right:-2px}.tab{padding:10px 12px}}
</style>
</head>
<body>
<header><div class="wrap"><h1>Gossip Harbor 主棋盘终极模拟</h1><p>全解锁、无限棋盘、只含 Baseline 与 Random 订单；3 类策略 × 10 个固定种子</p></div></header>
<main class="wrap">
<nav class="tabs" role="tablist" aria-label="报告内容"><button class="tab" type="button" role="tab" id="tab-results" aria-controls="panel-results" aria-selected="true" data-tab="results">模拟结果</button><button class="tab" type="button" role="tab" id="tab-settings" aria-controls="panel-settings" aria-selected="false" data-tab="settings">模拟设定</button><button class="tab" type="button" role="tab" id="tab-story" aria-controls="panel-story" aria-selected="false" data-tab="story">剧情金币需求</button></nav>
<div class="tab-panel" id="panel-results" role="tabpanel" aria-labelledby="tab-results">
<section id="summary"><h2>模拟结论</h2><p class="lead">以下结果使用实际游玩视频校准后的主动操作时长。顶氪、中氪和 0 氪策略的完成时间与钻石消耗见下方汇总，具体数值按 10 个固定种子计算。</p><div class="notice"><strong>解释边界：</strong>这不是正常新玩家预测。所有 Series 从开局解锁、拥有满级母体、棋盘无限，且钻石无预算；结果只用于隔离比较三种消费策略。</div><div class="kpis" id="kpis"></div></section>
<section id="charts"><h2>累计进度</h2><figure class="static-chart"><img src="data:image/png;base64,__GOLD_CHART_IMAGE__" alt="日期与累计金币获取统计图"><figcaption>日期 - 累计金币获取。左侧为完整周期，右侧放大前 365 天。</figcaption></figure><figure class="static-chart"><img src="data:image/png;base64,__TASK_CHART_IMAGE__" alt="日期与主线完成次数统计图"><figcaption>日期 - 主线完成次数。左侧为完整周期，右侧放大前 365 天。</figcaption></figure><div class="grid2"><div class="panel"><div class="chart-head"><div><h3>累计金币交互图</h3><div class="small">10 局均值；阴影为最小值至最大值</div></div><div class="seg" data-chart="gold"><button data-range="365">前 365 天</button><button class="active" data-range="full">全周期</button></div></div><div class="chart-wrap"><canvas id="goldChart"></canvas></div><div class="legend"></div></div><div class="panel"><div class="chart-head"><div><h3>主线完成次数交互图</h3><div class="small">10 局均值；完成后水平延伸至共同终点</div></div><div class="seg" data-chart="tasks"><button data-range="365">前 365 天</button><button class="active" data-range="full">全周期</button></div></div><div class="chart-wrap"><canvas id="tasksChart"></canvas></div><div class="legend"></div></div></div><p class="small">横轴为模拟第 N 天。完整逐日、逐局数据见 <code>terminal_simulation_daily.csv</code>。</p></section>
<section id="typical-day"><h2>三类玩家的典型一天</h2><p class="lead">订单完成、钻石支付和剧情推进分别显示在三条事件轨道上；登录时点作为背景参考，右侧按每次上线汇总事件类型、数量与金额。体力不绘制为曲线，仍保存在每个事件节点的数据中。</p><figure class="static-chart"><img src="data:image/png;base64,__TYPICAL_DAY_ZERO_IMAGE__" alt="0氪玩家典型日事件时间线"><figcaption>0 氪玩家代表局。</figcaption></figure><figure class="static-chart"><img src="data:image/png;base64,__TYPICAL_DAY_MID_IMAGE__" alt="中氪玩家典型日事件时间线"><figcaption>中氪玩家代表局。</figcaption></figure><figure class="static-chart"><img src="data:image/png;base64,__TYPICAL_DAY_TOP_IMAGE__" alt="顶氪玩家典型日事件时间线"><figcaption>顶氪玩家代表局。逐事件结构化数据见 <code>terminal_simulation_typical_days.json</code>。</figcaption></figure></section>
<section id="diamonds"><h2>钻石消耗构成</h2><div class="breakdown" id="diamondPanels"></div></section>
<section id="runs"><h2>30 局结果</h2><div class="controls"><label>玩家类型<select id="runPlayer"><option value="all">全部</option><option value="zero">0氪金玩家</option><option value="mid">中氪金玩家</option><option value="top">顶氪金玩家</option></select></label></div><div class="table-wrap"><table><thead><tr><th>玩家</th><th>种子</th><th class="num">完成天数</th><th class="num">金币获取</th><th class="num">体力消耗</th><th class="num">钻石合计</th><th class="num">订单数</th><th class="num">操作数</th></tr></thead><tbody id="runRows"></tbody></table></div></section>
<section id="inventory"><h2>最终库存</h2><div class="grid2"><div class="panel"><h3>10 局汇总</h3><div class="controls"><label>玩家类型<select id="invSummaryPlayer"><option value="zero">0氪金玩家</option><option value="mid">中氪金玩家</option><option value="top">顶氪金玩家</option></select></label></div><div class="table-wrap"><table><thead><tr><th>棋子</th><th class="num">等级</th><th class="num">数量均值</th><th class="num">中位数</th><th class="num">最小</th><th class="num">最大</th><th class="num">基础等价值均值</th></tr></thead><tbody id="invSummaryRows"></tbody></table></div></div><div class="panel"><h3>单局明细</h3><div class="controls"><label>玩家类型<select id="invPlayer"><option value="zero">0氪金玩家</option><option value="mid">中氪金玩家</option><option value="top">顶氪金玩家</option></select></label><label>固定种子<select id="invSeed"></select></label></div><div class="table-wrap"><table><thead><tr><th>Code</th><th>棋子</th><th class="num">Series</th><th class="num">等级</th><th class="num">数量</th><th class="num">基础等价值</th></tr></thead><tbody id="invRows"></tbody></table></div></div></div></section>
</div>
<div class="tab-panel" id="panel-settings" role="tabpanel" aria-labelledby="tab-settings" hidden>
<section><h2>模拟如何运行</h2><div class="grid2"><article class="panel"><h3>起点与终点</h3><ul class="setting-list"><li>每局从第 1 天 10:00 开始，初始金币 0、体力 100、普通棋子库存为空。</li><li>所有 Series、订单槽、商店与气泡开局解锁，每个 Series 拥有最高级母体；棋盘和库存没有容量限制。</li><li>金币足够时立即按配置顺序支付主线任务，完成 4,192 项、287 个剧情日后结束；任务奖励不进入模拟。</li><li>三类策略使用相同的 10 个固定随机种子，共 30 局。</li></ul></article><article class="panel"><h3>时间与订单</h3><ul class="setting-list"><li>每天计划在 10:00–19:00 的整点上线；会话持续到没有可执行的零体力动作且体力不足以下次生产。</li><li>体力低于 100 时每 120 秒自然回复 1 点；点击、合成、购买和交单等主动操作平均各耗时 1.27 秒。</li><li>免费母体冷却完毕会立即唤起操作，即使当时离线。</li><li>只生成五类 Random 和 Baseline 订单；最后一个 Filter 固定生效。订单在初始化、交单、升级或无订单 Force 扫描时补位；CD 到期本身不会自动生成订单。</li><li>每次动作后按订单金币除以从零库存生产整单的预期体力排序，优先处理比值最高的订单。</li></ul></article></div></section>
<section><h2>三类钻石策略</h2><div class="grid2"><article class="panel"><h3>0 氪策略</h3><p>每天首次体力耗尽时花 10 钻购买 100 体力；此后当天不再购买。不买商店或气泡棋子，也不加速母体。名称中的“0 氪”不表示零钻石消耗。</p></article><article class="panel"><h3>中氪策略</h3><p>每天前三次体力耗尽分别花 10、20、40 钻购买 100 体力。会购买当前订单需要的商店或气泡棋子，以及可合成的低级版本；不加速母体。</p></article><article class="panel"><h3>顶氪策略</h3><p>体力耗尽就购买 100 体力，当日钻石阶梯为 10、20、40、80、160，之后每次 160。与中氪相同地购买订单棋子；当前最高优先级订单被所需母体冷却阻塞时立即加速。</p></article><article class="panel"><h3>全部策略共通</h3><p>不花钻石刷新商店。钻石没有来源、余额或预算限制；这里的玩家类型代表消费规则，不代表人民币金额。商店在自然日 00:00 按配置权重刷新。</p></article></div></section>
<section id="method"><h2>证据与结果边界</h2><div class="panel method"><p><span class="tag">配置确认</span>主线共 4,192 个任务，累计消耗 1,551,042 金币；母体产出、容量、冷却、订单需求和价格读取自 3.98.10 本地配置快照。</p><p><span class="tag">代码确认</span>事件模拟保留批次/总储量状态、订单完成与等级升级扫描、零订单 Force 扫描、00:00 商店自然刷新，以及每 120 秒恢复 1 体力。</p><p><span class="tag assume">模拟设定</span>最后一个 Filter 无条件生效；所有内容开局解锁；棋盘无限；主动操作每次 1.27 秒；免费母体冷却完成即唤起；不计活动、Buff 和主线奖励。</p><p><span class="tag assume">订单策略</span>每次动作后按订单金币/订单总体力需求排序，只尝试性价比最高者；总体力按从零库存生产完整订单的期望体力计算，不随当前库存变化。</p><p><span class="tag assume">消费白名单</span>所有类型均不钻石刷新商店。中氪和顶氪购买当前订单可用的商店/气泡棋子；只有顶氪会在所需母体冷却时立即加速。</p><p><span class="tag limit">远端缺口</span>普通气泡使用配置基础概率；无法恢复的远端动态倍率按中性值处理。商店每槽按已配置候选及权重抽样。</p><p><span class="tag limit">统计限制</span>每类只有 10 个固定种子，阴影是样本极差，不是置信区间。钻石只有消耗量，无来源、余额限制或人民币换算。</p></div></section>
</div>
<div class="tab-panel" id="panel-story" role="tabpanel" aria-labelledby="tab-story" hidden>
<section><h2>剧情推进的金币需求</h2><p class="lead">按 3.98.10 本地 <code>MainTaskConfig</code> 逐项汇总标称金币成本。模拟按这个顺序和成本付款；客户端以外的服务端价格调整尚未计入。</p><div class="story-stats"><article class="kpi"><span>剧情任务</span><strong id="storyTaskCount"></strong></article><article class="kpi"><span>剧情日节点</span><strong id="storyDayCount"></strong></article><article class="kpi"><span>累计金币需求</span><strong id="storyTotalGold"></strong></article></div><div class="panel"><h3>按剧情日分布</h3><div class="story-chart-scroll"><div id="storyBars" class="story-bars" role="img" aria-label="各剧情日标称金币需求"></div></div><p class="small">横轴：剧情日 1–287；柱高：当日金币，最高 <span id="storyMaxGold"></span>。悬停查看具体数值。</p></div></section>
<section><h2>剧情日明细</h2><div class="table-wrap"><table class="story-table"><thead><tr><th>剧情日</th><th class="num">任务数</th><th class="num">当日金币</th><th class="num">累计金币</th></tr></thead><tbody id="storyDays"></tbody></table></div></section>
<section><h2>任务金币查询</h2><div class="controls"><label>剧情日<input id="storyDayInput" type="number" min="1" step="1" value="1"></label></div><div class="table-wrap"><table class="story-table"><thead><tr><th>任务 ID</th><th class="num">花费金币</th><th class="num">累计金币</th></tr></thead><tbody id="storyNodes"></tbody></table></div></section>
</div>
</main><footer><div class="wrap">配置版本：Gossip Harbor 3.98.10 local Lua_Config snapshot · 构建脚本：<code>tools/build_terminal_simulation_report.py</code> · 原始结果：<code>terminal_simulation_results.json</code></div></footer>
<script>const DATA=__REPORT_DATA__;
const TYPES={zero:{label:'0氪金玩家',color:'#167552'},mid:{label:'中氪金玩家',color:'#3876b9'},top:{label:'顶氪金玩家',color:'#b65d14'}};const nf=new Intl.NumberFormat('zh-CN');const n1=x=>nf.format(Math.round(x*10)/10);const sum=o=>Object.values(o).reduce((a,b)=>a+b,0);
function summary(){document.getElementById('kpis').innerHTML=DATA.summary.players.map(p=>`<article class="kpi"><span>${p.player_label}</span><strong>${n1(p.completion_days.mean)} 天</strong><div>范围 ${n1(p.completion_days.min)}–${n1(p.completion_days.max)} 天</div><div class="small">平均钻石 ${nf.format(Math.round(p.diamonds_total.mean))} · 平均体力 ${nf.format(Math.round(p.energy_spent.mean))}</div></article>`).join('')}
function diamonds(){const keys=[['energy','体力'],['shop_items','商店棋子'],['bubble_items','气泡'],['producer_speedup','母体加速']];document.getElementById('diamondPanels').innerHTML=DATA.summary.players.map(p=>{const vals=keys.map(([k,l])=>[l,p['diamonds_'+k].mean]);const total=p.diamonds_total.mean;return `<article class="panel"><h3>${p.player_label}</h3><strong>${nf.format(Math.round(total))} 钻</strong>${vals.map(([l,v])=>`<div class="bar-row"><span>${l}</span><div class="bar"><b style="width:${total?v/total*100:0}%"></b></div><span class="num">${nf.format(Math.round(v))}</span></div>`).join('')}<div class="small">商店刷新：0 钻</div></article>`}).join('')}
function rgba(hex,a){const n=parseInt(hex.slice(1),16);return `rgba(${n>>16},${n>>8&255},${n&255},${a})`}
function chart(canvasId,metric,range){const canvas=document.getElementById(canvasId),box=canvas.getBoundingClientRect(),dpr=devicePixelRatio||1;canvas.width=Math.round(box.width*dpr);canvas.height=Math.round(box.height*dpr);const c=canvas.getContext('2d');c.scale(dpr,dpr);const W=box.width,H=box.height,p={l:58,r:16,t:12,b:38};const maxN=range==='365'?Math.min(365,DATA.max_day):DATA.max_day;let ymax=0;Object.keys(TYPES).forEach(t=>{const a=DATA.chart[t][metric];ymax=Math.max(ymax,a[Math.min(maxN,a.length)-1][2])});ymax*=1.04;const x=i=>p.l+i/(maxN-1)*(W-p.l-p.r),y=v=>p.t+(1-v/ymax)*(H-p.t-p.b);c.clearRect(0,0,W,H);c.font='12px system-ui';c.fillStyle='#607068';c.strokeStyle='#dfe7e2';c.lineWidth=1;for(let i=0;i<=4;i++){const v=ymax*i/4,yy=y(v);c.beginPath();c.moveTo(p.l,yy);c.lineTo(W-p.r,yy);c.stroke();c.fillText(metric==='gold'?compact(v):nf.format(Math.round(v)),4,yy+4)}for(let i=0;i<=4;i++){const day=1+Math.round((maxN-1)*i/4);c.fillText('第'+nf.format(day)+'天',Math.max(p.l,x(day-1)-24),H-12)}Object.entries(TYPES).forEach(([t,opt])=>{const a=DATA.chart[t][metric].slice(0,maxN);c.beginPath();a.forEach((v,i)=>{const xx=x(i),yy=y(v[2]);i?c.lineTo(xx,yy):c.moveTo(xx,yy)});for(let i=a.length-1;i>=0;i--)c.lineTo(x(i),y(a[i][1]));c.closePath();c.fillStyle=rgba(opt.color,.10);c.fill();c.beginPath();a.forEach((v,i)=>{const xx=x(i),yy=y(v[0]);i?c.lineTo(xx,yy):c.moveTo(xx,yy)});c.strokeStyle=opt.color;c.lineWidth=2;c.stroke()})}
function compact(v){return v>=1e6?(v/1e6).toFixed(1)+'M':v>=1e3?(v/1e3).toFixed(0)+'k':Math.round(v)}
function legends(){document.querySelectorAll('.legend').forEach(el=>el.innerHTML=Object.values(TYPES).map(t=>`<span><i style="background:${t.color}"></i>${t.label}</span>`).join(''))}
function renderRuns(){const f=document.getElementById('runPlayer').value;document.getElementById('runRows').innerHTML=DATA.runs.filter(r=>f==='all'||r.player_type===f).map(r=>`<tr><td>${r.player_label}</td><td>${r.seed}</td><td class="num">${r.completion_days.toFixed(2)}</td><td class="num">${nf.format(r.gold_earned)}</td><td class="num">${nf.format(r.energy_spent)}</td><td class="num">${nf.format(r.diamonds.total)}</td><td class="num">${nf.format(sum(r.orders_completed))}</td><td class="num">${nf.format(r.actions)}</td></tr>`).join('')}
function renderInvSummary(){const p=document.getElementById('invSummaryPlayer').value;document.getElementById('invSummaryRows').innerHTML=DATA.inventory_summary.filter(x=>x.player_type===p).map(x=>`<tr><td>${x.name} <span class="small">${x.code}</span></td><td class="num">${x.level}</td><td class="num">${n1(x.count.mean)}</td><td class="num">${n1(x.count.median)}</td><td class="num">${nf.format(x.count.min)}</td><td class="num">${nf.format(x.count.max)}</td><td class="num">${n1(x.base_equivalent.mean)}</td></tr>`).join('')}
function seeds(){const p=document.getElementById('invPlayer').value,sel=document.getElementById('invSeed');sel.innerHTML=DATA.runs.filter(r=>r.player_type===p).map(r=>`<option>${r.seed}</option>`).join('');renderInv()}
function renderInv(){const p=document.getElementById('invPlayer').value,s=+document.getElementById('invSeed').value,r=DATA.runs.find(x=>x.player_type===p&&x.seed===s);document.getElementById('invRows').innerHTML=(r?r.inventory:[]).map(x=>`<tr><td>${x.code}</td><td>${x.name}</td><td class="num">${x.series}</td><td class="num">${x.level}</td><td class="num">${nf.format(x.count)}</td><td class="num">${nf.format(x.base_equivalent)}</td></tr>`).join('')}
function drawAll(){document.querySelectorAll('.seg').forEach(seg=>{const active=seg.querySelector('.active');chart(seg.dataset.chart+'Chart',seg.dataset.chart,active.dataset.range)})}
const STORY=DATA.story;const storyDayInput=document.getElementById('storyDayInput');
function renderStory(){document.getElementById('storyTaskCount').textContent=nf.format(STORY.task_count);document.getElementById('storyDayCount').textContent=nf.format(STORY.story_days);document.getElementById('storyTotalGold').textContent=nf.format(STORY.total_gold);const max=Math.max(...STORY.days.map(d=>d.cost));document.getElementById('storyMaxGold').textContent=nf.format(max);document.getElementById('storyBars').innerHTML=STORY.days.map(d=>`<i title="剧情日 ${d.day}：${nf.format(d.cost)} 金币" style="height:${Math.max(1,d.cost/max*100)}%"></i>`).join('');document.getElementById('storyDays').innerHTML=STORY.days.map(d=>`<tr><td>${d.day}</td><td class="num">${d.tasks}</td><td class="num">${nf.format(d.cost)}</td><td class="num">${nf.format(d.cumulative)}</td></tr>`).join('');storyDayInput.max=STORY.days.at(-1).day;renderStoryDay()}
function renderStoryDay(){const day=Number(storyDayInput.value);document.getElementById('storyNodes').innerHTML=STORY.nodes.filter(n=>n.day===day).map(n=>`<tr><td>${n.id}</td><td class="num">${nf.format(n.cost)}</td><td class="num">${nf.format(n.cumulative)}</td></tr>`).join('')||'<tr><td colspan="3">请选择有效剧情日</td></tr>'}
function selectTab(name){document.querySelectorAll('.tab').forEach(b=>{const active=b.dataset.tab===name;b.setAttribute('aria-selected',String(active));b.tabIndex=active?0:-1});document.querySelectorAll('.tab-panel').forEach(p=>{p.hidden=p.id!==`panel-${name}`});if(name==='results')requestAnimationFrame(drawAll)}
document.querySelectorAll('.tab').forEach(b=>{b.onclick=()=>selectTab(b.dataset.tab);b.onkeydown=e=>{if(e.key!=='ArrowRight'&&e.key!=='ArrowLeft')return;const tabs=[...document.querySelectorAll('.tab')],next=tabs[(tabs.indexOf(b)+(e.key==='ArrowRight'?1:-1)+tabs.length)%tabs.length];next.focus();selectTab(next.dataset.tab)}});
document.querySelectorAll('.seg button').forEach(b=>b.onclick=()=>{b.parentElement.querySelectorAll('button').forEach(x=>x.classList.toggle('active',x===b));drawAll()});document.getElementById('runPlayer').onchange=renderRuns;document.getElementById('invSummaryPlayer').onchange=renderInvSummary;document.getElementById('invPlayer').onchange=seeds;document.getElementById('invSeed').onchange=renderInv;storyDayInput.oninput=renderStoryDay;window.addEventListener('resize',()=>{if(!document.getElementById('panel-results').hidden){clearTimeout(window._rt);window._rt=setTimeout(drawAll,100)}});summary();diamonds();legends();renderRuns();renderInvSummary();seeds();renderStory();requestAnimationFrame(drawAll);
</script></body></html>'''


if __name__ == "__main__":
    main()
