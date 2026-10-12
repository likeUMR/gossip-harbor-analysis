"""Build the auditable Stage 3 board-operation manifest.

The manifest deliberately separates source-confirmed facts from runtime checks.
It is a compact index for the three requested player operations; the prose report
adds the human-readable explanation and edge-case interpretation.
"""
from __future__ import annotations

import json
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "analysis_output" / "logic_recovery" / "stage3"
OUT.mkdir(parents=True, exist_ok=True)


def module_row(conn: sqlite3.Connection, name: str):
    return conn.execute(
        "select id, location from entities where kind='lua_module' and name=?", (name,)
    ).fetchone()


def main() -> None:
    conn = sqlite3.connect(ROOT / "analysis_data/logic_index/stage2/logic_index.sqlite3")
    names = [
        "Board.Model.Item.ItemSpread",
        "Board.Model.Board.MainBoardModel",
        "Board.Model.Board.BaseBoardModel",
        "Board.Model.Board.BaseActionBoardModel",
        "Board.Model.Item.ItemSwallow",
        "Board.Model.Item.ItemTransform",
        "Board.Model.Order.MainOrderModel",
        "Board.Model.Order.SlotOrderModel",
        "Board.View.Order.BaseOrderCell",
        "LuckyProduce.Model.LuckyProduceModel",
    ]
    modules = {}
    for name in names:
        row = module_row(conn, name)
        if row:
            modules[name] = {
                "entity_id": row[0],
                "location": row[1],
                "decompiled_source": str(
                    ROOT
                    / "analysis_data/logic_index/lua/decoded"
                    / row[0].split(":", 1)[1]
                    / "decompiled.lua"
                ),
            }

    items = json.loads((ROOT / "analysis_data/json/ItemModelConfig.json").read_text(encoding="utf-8"))
    orders = json.loads((ROOT / "analysis_data/json/OrderItemConfig.json").read_text(encoding="utf-8"))
    weight_types = {"1": "Fixed", "2": "Decremental", "3": "OrderItem", "4": "ChestCustomItem", "5": "SmartItem"}
    spread_items = [x for x in items if any(k.startswith("Spread_") for k in x)]
    manifest = {
        "game": "Gossip Harbor 3.98.10",
        "scope": ["母体点击/产出", "合成", "订单交付"],
        "modules": modules,
        "config_summary": {
            "item_model_rows": len(items),
            "spread_item_rows": len(spread_items),
            "merge_rows": sum("MergedType" in x for x in items),
            "bubble_chance_rows": sum(x.get("BubbleChance", 0) > 0 for x in items),
            "spread_weight_type_counts": {
                weight_types.get(str(k), str(k)): sum(x.get("Spread_WeightType") == k for x in items)
                for k in sorted({x.get("Spread_WeightType") for x in items if "Spread_WeightType" in x})
            },
            "order_item_rows": len(orders),
            "order_diff_score_min": min(x["DiffScore"] for x in orders),
            "order_diff_score_max": max(x["DiffScore"] for x in orders),
        },
        "operations": [
            {
                "id": "board_generator_tap",
                "label": "点击母体棋子",
                "entry": "ItemSpread:OnTap",
                "chain": [
                    "CheckSpreadState", "CheckSpreadPosAndAuto", "CheckEnergy",
                    "GenerateItemCode", "SpreadCostEnergy", "MainBoardModel:SpreadItem",
                    "TryRemoveSelf", "TryUseCDBuff",
                ],
                "branches": ["普通加权产出", "递减池", "订单导向", "箱子自定义", "SmartItem", "Lucky", "Disco", "能量增益", "鱼网智能产出", "CD/恢复", "棋盘满/能量不足"],
                "evidence": "source_confirmed_static; runtime_identity_and_server_flags_require_stage3_replay",
            },
            {
                "id": "board_merge",
                "label": "拖拽同类棋子合成",
                "entry": "MainBoardModel:DragItem",
                "chain": [
                    "CanItemMerge", "MainBoardModel:_DoMergeItem -> inherited BaseBoardModel:_DoMergeItem", "ReplaceItem",
                    "ItemMerged event", "activity merge hooks", "Temp/Card/EnergyBubble/Bubble/Coin side effects",
                    "UpdateOrderState",
                ],
                "branches": ["特殊棋子 LevelUp/LevelDown", "普通合成", "活动临时棋子", "卡牌棋子", "能量气泡", "订单气泡概率", "最低链等级喷金币", "棋盘满"],
                "evidence": "source_confirmed_static; activity/server-controlled branches require runtime replay",
            },
            {
                "id": "board_order_delivery",
                "label": "点击订单交付",
                "entry": "BaseOrderCell:OnGoButtonClicked",
                "chain": [
                    "CanDeliver(codeCountMap)", "MainBoardModel:FinishOrder", "AcquireRewardsLogic",
                    "RemoveOrderRequirementItems(board-first, inventory-second)", "SlotOrderModel:FinishOrder",
                    "fill next orders", "UpdateOrderState", "FinishOrder event/network upload",
                ],
                "branches": ["特殊/分支订单", "主订单奖励", "亲密度礼物", "Buff/OrderBoost/CookingFrenzy奖励", "延迟奖励", "幸运订单触发", "难度累计分", "订单补位"],
                "evidence": "source_confirmed_static; server responses and asynchronous UI timing require runtime replay",
            },
        ],
        "acceptance_gaps": [
            "动态对象身份和继承分派需运行时确认",
            "服务端下发的 Lucky/Boost/活动开关需按真实账号状态回放",
            "异步回调、动画时序、网络失败重试需运行时记录",
            "原版与复刻版需进行同输入差分回放",
        ],
    }
    (OUT / "stage3_board_operation_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps({"output": str(OUT / "stage3_board_operation_manifest.json"), "operations": len(manifest["operations"])}, ensure_ascii=False))


if __name__ == "__main__":
    main()
