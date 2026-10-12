import csv
import json
import math
import struct
from collections import defaultdict
from functools import lru_cache
from pathlib import Path

import UnityPy


ROOT = Path(__file__).resolve().parents[1]
JSON_DIR = ROOT / "analysis_data" / "json"
TEXT_BUNDLE = next((ROOT / "analysis_data" / "bundles").rglob("text_*.bundle"))
OUTPUT_DIR = ROOT / "analysis_output"


def load_json(name: str):
    return json.loads((JSON_DIR / name).read_text(encoding="utf-8"))


def text_asset_bytes(bundle_path: Path, asset_name: str) -> bytes:
    env = UnityPy.load(str(bundle_path))
    obj = next(
        obj
        for obj in env.objects
        if obj.type.name == "TextAsset" and obj.read().m_Name == asset_name
    )
    raw = obj.get_raw_data()
    name_length = struct.unpack_from("<I", raw, 0)[0]
    value_offset = (4 + name_length + 3) & ~3
    value_length = struct.unpack_from("<I", raw, value_offset)[0]
    return raw[value_offset + 4 : value_offset + 4 + value_length]


def parse_weight(value: str) -> tuple[str, int]:
    item_type, weight = value.rsplit("-", 1)
    return item_type, int(weight)


def expected_fixed_batch_outputs(weighted_outputs: list[tuple[str, int]], charge: int) -> dict[int, float]:
    """Expected output for Fixed producers: weighted draw on every click; one charge per click."""
    relevant_series = sorted(
        {int(item_type) // 100 for item_type, _ in weighted_outputs if item_type.isdigit()}
    )
    series_index = {series: index for index, series in enumerate(relevant_series)}
    total_weight = sum(weight for _, weight in weighted_outputs)
    output_vectors = []
    for item_type, _ in weighted_outputs:
        vector = [0.0] * len(relevant_series)
        if item_type.isdigit():
            numeric_type = int(item_type)
            series = numeric_type // 100
            level = numeric_type % 100
            vector[series_index[series]] = 2 ** (level - 1)
        output_vectors.append(tuple(vector))

    per_click = [0.0] * len(relevant_series)
    for index, (_, weight) in enumerate(weighted_outputs):
        probability = weight / total_weight
        for output_index in range(len(relevant_series)):
            per_click[output_index] += probability * output_vectors[index][output_index]
    return {series: charge * per_click[index] for series, index in series_index.items()}


def main() -> None:
    models = load_json("ItemModelConfig.json")
    properties = load_json("ItemPropertyConfig.json")
    order_items = load_json("OrderItemConfig.json")
    translations = json.loads(text_asset_bytes(TEXT_BUNDLE, "game_text_cn").decode("utf-8"))

    model_by_type = {row["Type"]: row for row in models}
    property_by_type = {row["Type"]: row for row in properties}
    order_item_by_type = {row["Code"]: row for row in order_items}
    main_types = [
        item_type
        for item_type in model_by_type
        if item_type.isdigit() and 1 <= int(item_type) // 100 <= 20
    ]
    main_types.sort(key=int)

    producers_by_series = defaultdict(list)
    for model in models:
        producer_type = model["Type"]
        if not producer_type.isdigit() or not model.get("Spread_ItemSpeedUpCost"):
            continue
        weighted_outputs = [parse_weight(value) for value in model.get("Spread_Weight", [])]
        total_weight = sum(weight for _, weight in weighted_outputs)
        expected_count_by_type = {
            item_type: model["Spread_ItemMaxNumber"] * weight / total_weight
            for item_type, weight in weighted_outputs
            if item_type.isdigit()
        }
        if not total_weight or not model.get("Spread_ItemMaxNumber"):
            continue
        target_series = {
            int(item_type) // 100
            for item_type, _ in weighted_outputs
            if item_type.isdigit() and 1 <= int(item_type) // 100 <= 20
        }
        expected_by_series = expected_fixed_batch_outputs(
            weighted_outputs, model["Spread_ItemMaxNumber"]
        )
        total_weight = sum(weight for _, weight in weighted_outputs)
        output_pool = []
        for item_type, weight in weighted_outputs:
            if not item_type.isdigit():
                continue
            numeric_output = int(item_type)
            output_level = numeric_output % 100
            output_pool.append(
                {
                    "item_type": item_type,
                    "item_name": translations.get(f"item_{item_type}_name", item_type),
                    "series": numeric_output // 100,
                    "level": output_level,
                    "weight": weight,
                        "probability_percent": weight * 100 / total_weight,
                        "batch_inventory_decrement": weight,
                        "fresh_batch_actual_decrement": 1,
                    "base_equivalent": 2 ** (output_level - 1),
                }
            )
        for series in target_series:
            expected_base_per_drop = sum(
                weight * (2 ** ((int(item_type) % 100) - 1))
                for item_type, weight in weighted_outputs
                if item_type.isdigit() and int(item_type) // 100 == series
            ) / total_weight
            batch_base_output = expected_by_series[series]
            expected_target_items = {}
            series_output_levels = {
                int(item_type) % 100: count
                for item_type, count in expected_count_by_type.items()
                if int(item_type) // 100 == series
            }
            for target_level in range(1, 12):
                expected_target_items[str(target_level)] = sum(
                    count / (2 ** (target_level - output_level))
                    for output_level, count in series_output_levels.items()
                    if output_level <= target_level
                )
            storage_batches = model["Spread_StorageMaxNumber"] / model["Spread_ItemMaxNumber"]
            expected_diamonds_per_batch = (
                model["Spread_ItemSpeedUpCost"]
                + (model["Spread_StorageSpeedUpCost"] - model["Spread_ItemSpeedUpCost"]) / storage_batches
            )
            series_weights = defaultdict(int)
            for output_type, output_weight in weighted_outputs:
                if output_type.isdigit():
                    series_weights[int(output_type) // 100] += output_weight
            main_series = max(series_weights, key=series_weights.get)
            secondary_weight = total_weight - series_weights[main_series]
            producers_by_series[series].append(
                {
                    "type": producer_type,
                    "producer_series": int(producer_type) // 100,
                    "name": translations.get(f"item_{producer_type}_name", producer_type),
                    "batch_size": model["Spread_ItemMaxNumber"],
                    "storage_batches": storage_batches,
                    "energy_per_click": model["Spread_CostEnergy"],
                    "expected_energy_per_batch": model["Spread_ItemMaxNumber"] * model["Spread_CostEnergy"],
                    "expected_diamonds_per_batch": expected_diamonds_per_batch,
                    "speedup_cost": model["Spread_ItemSpeedUpCost"],
                    "item_recovery_seconds": model.get("Spread_ItemRecoveryDuration"),
                    "storage_max_number": model.get("Spread_StorageMaxNumber"),
                    "storage_recovery_seconds": model.get("Spread_StorageRecoveryDuration"),
                    "storage_speedup_cost": model.get("Spread_StorageSpeedUpCost"),
                    "item_diamonds_per_minute": (
                        model["Spread_ItemSpeedUpCost"] * 60 / model["Spread_ItemRecoveryDuration"]
                        if model.get("Spread_ItemRecoveryDuration")
                        else None
                    ),
                    "storage_diamonds_per_minute": (
                        model.get("Spread_StorageSpeedUpCost", 0) * 60 / model["Spread_StorageRecoveryDuration"]
                        if model.get("Spread_StorageRecoveryDuration")
                        else None
                    ),
                    "expected_base_per_drop": expected_base_per_drop,
                    "expected_base_per_cd": batch_base_output,
                    "expected_count_by_type": expected_count_by_type,
                    "expected_target_items": expected_target_items,
                    "total_base_per_cd": model["Spread_ItemMaxNumber"] * sum(
                        weight * (2 ** ((int(item_type) % 100) - 1))
                        for item_type, weight in weighted_outputs
                        if item_type.isdigit()
                    ) / total_weight,
                    "total_weight": total_weight,
                    "expected_charge_per_click": 1,
                    "expected_base_per_click": sum(
                        weight * (2 ** ((int(item_type) % 100) - 1))
                        for item_type, weight in weighted_outputs
                        if item_type.isdigit()
                    ) / total_weight,
                    "main_secondary_ratio": f"{series_weights[main_series]}:{secondary_weight}",
                    "output_pool": output_pool,
                    "diamonds_per_base": expected_diamonds_per_batch / batch_base_output,
                    "energy_per_base": (
                        model["Spread_ItemMaxNumber"] * model["Spread_CostEnergy"] / batch_base_output
                    ),
                }
            )

    for producer_rows in producers_by_series.values():
        producer_rows.sort(key=lambda row: int(row["type"]))

    # Type 805 is a disposable secondary generator. It has multiple charges,
    # produces one weighted item per charge, and disappears when its remaining
    # charges reach zero. Keep it separate from the ordinary recovering-CD model.
    special_conversions = []
    processed_seafood = model_by_type.get("805")
    if processed_seafood:
        weighted_outputs = [parse_weight(value) for value in processed_seafood.get("Spread_Weight", [])]
        total_weight = sum(weight for _, weight in weighted_outputs)
        if total_weight:
            output_pool = []
            expected_base = 0.0
            for item_type, weight in weighted_outputs:
                if not item_type.isdigit():
                    continue
                numeric_output = int(item_type)
                level = numeric_output % 100
                expected_base += weight * (2 ** (level - 1)) / total_weight
                output_pool.append({
                    "item_type": item_type,
                    "item_name": translations.get(f"item_{item_type}_name", item_type),
                    "series": numeric_output // 100,
                    "level": level,
                    "weight": weight,
                    "probability_percent": weight * 100 / total_weight,
                    "base_equivalent": 2 ** (level - 1),
                })
            upstream = next((p for p in producers_by_series.get(8, []) if p["type"] == "711"), None)
            upstream_low = next((p for p in producers_by_series.get(8, []) if p["type"] == "705"), None)
            configured_max_uses = processed_seafood.get("Spread_ItemMaxNumber")
            per_click_base = expected_base
            nominal_clicks = configured_max_uses
            nominal_output_counts = {
                item_type: nominal_clicks * weight / total_weight
                for item_type, weight in weighted_outputs
                if item_type.isdigit()
            }
            upstream_diamonds = (16 * upstream["diamonds_per_base"] if upstream else None)
            upstream_energy = (16 * upstream["energy_per_base"] if upstream else None)
            nominal_direct_energy = nominal_clicks * processed_seafood.get("Spread_CostEnergy", 0)
            nominal_total_energy = (
                upstream_energy + nominal_direct_energy if upstream_energy is not None else None
            )
            nominal_low_total_energy = (
                (16 * upstream_low["energy_per_base"] + nominal_direct_energy)
                if upstream_low is not None else None
            )
            special_conversions.append({
                "type": "805",
                "name": translations.get("item_805_name", "处理过的海鲜"),
                "input_item_type": "805",
                "input_item_name": translations.get("item_805_name", "处理过的海鲜"),
                "consumes_input": True,
                "kind": "disposable_secondary_generator",
                "disappears_after_exhaustion": True,
                "configured_max_uses": configured_max_uses,
                "actual_uses_variable": True,
                "uses_formula": "N = 实际生命周期内成功消耗的剩余次数；普通逐次点击且满额生成时 N=12",
                "expected_base_per_click": per_click_base,
                "expected_base_for_N": f"{per_click_base:g} × N",
                "nominal_clicks": nominal_clicks,
                "nominal_output_counts": nominal_output_counts,
                "expected_base_nominal": nominal_clicks * per_click_base,
                "cost_energy_per_click": processed_seafood.get("Spread_CostEnergy", 0),
                "nominal_direct_energy": nominal_direct_energy,
                "nominal_total_energy": nominal_total_energy,
                "nominal_low_total_energy": nominal_low_total_energy,
                "total_weight": total_weight,
                "output_pool": output_pool,
                "upstream_series": 8,
                "upstream_cost_per_input_diamonds": upstream_diamonds,
                "upstream_cost_per_input_energy": upstream_energy,
                "upstream_low_cost_per_input_diamonds": (
                    16 * upstream_low["diamonds_per_base"] if upstream_low else None
                ),
                "upstream_low_cost_per_input_energy": (
                    16 * upstream_low["energy_per_base"] if upstream_low else None
                ),
                "nominal_diamonds_per_expected_base": (
                    upstream_diamonds / (nominal_clicks * per_click_base)
                    if upstream_diamonds is not None else None
                ),
                "nominal_energy_per_expected_base": (
                    nominal_total_energy / (nominal_clicks * per_click_base)
                    if nominal_total_energy is not None else None
                ),
            })

    # Attach the 805 secondary route to each of its possible outputs.  This is
    # supplemental to the ordinary producer route: 901/902 can still be made
    # directly by their Series 9 producer, but they can also arrive through a
    # full 805 lifecycle generated from Series 8.
    secondary_by_output = {}
    for conversion in special_conversions:
        for output in conversion["output_pool"]:
            output_type = output["item_type"]
            expected_count = conversion["nominal_output_counts"].get(output_type, 0)
            expected_base_contribution = expected_count * output["base_equivalent"]
            secondary_by_output.setdefault(output_type, []).append(
                {
                    "source_type": conversion["type"],
                    "source_name": conversion["name"],
                    "upstream_series": conversion["upstream_series"],
                    "upstream_producer_type": "711",
                    "upstream_producer_name": "豪华海鲜柜",
                    "probability_percent": output["probability_percent"],
                    "nominal_clicks": conversion["nominal_clicks"],
                    "nominal_expected_count": expected_count,
                    "expected_base_contribution": expected_base_contribution,
                    "expected_base_nominal": conversion["expected_base_nominal"],
                    "upstream_cost_diamonds": conversion["upstream_cost_per_input_diamonds"],
                    "upstream_cost_energy": conversion["upstream_cost_per_input_energy"],
                    "nominal_total_energy": conversion["nominal_total_energy"],
                    "diamonds_per_expected_base": conversion["nominal_diamonds_per_expected_base"],
                    "energy_per_expected_base": conversion["nominal_energy_per_expected_base"],
                }
            )

    rows = []
    for item_type in main_types:
        model = model_by_type[item_type]
        prop = property_by_type.get(item_type, {})
        order_item = order_item_by_type.get(item_type)
        numeric_type = int(item_type)
        series = numeric_type // 100
        level = numeric_type % 100
        base_required = 2 ** (level - 1)
        producers = producers_by_series.get(series, [])
        low_producer = producers[0] if producers else None
        high_producer = producers[-1] if producers else None
        shop_available = bool(prop.get("Slot") and prop.get("ShopWeight", 0) > 0 and "Price" in prop)
        bubble_available = model.get("BubbleChance", 0) > 0 and "BubblePrice" in prop

        def producer_cost(producer):
            if producer is None:
                return None
            expected_items = producer.get("expected_target_items", {}).get(str(level))
            if expected_items:
                return producer["expected_diamonds_per_batch"] / expected_items
            return base_required * producer["diamonds_per_base"]

        def producer_energy(producer):
            if producer is None:
                return None
            expected_items = producer.get("expected_target_items", {}).get(str(level))
            if expected_items:
                return producer["expected_energy_per_batch"] / expected_items
            return base_required * producer["energy_per_base"]

        # For the luxury seafood cabinet, combine its direct Series 9 output
        # with the 805 route fed by the Series 8 output from the same batch.
        # The result is one expected cost per target item, not two displayed
        # alternatives.  Costs are allocated over base-equivalent output.
        combined_high_diamonds = producer_cost(high_producer)
        combined_high_energy = producer_energy(high_producer)
        combined_high_route = None
        secondary_low_diamonds = producer_cost(low_producer)
        secondary_low_energy = producer_energy(low_producer)
        secondary_low_route = None
        display_low_producer = low_producer
        if series == 9 and high_producer and special_conversions:
            conversion = special_conversions[0]
            # Series 9 merges recursively: two level-n pieces make one
            # level-(n+1) piece.  Level 1 can only use the 901 output;
            # level 2+ can use both 901 and the direct 902 output as base
            # equivalents, then divide by 2^(level-1).
            output_901 = conversion["nominal_output_counts"].get("901", 0)
            output_902 = conversion["nominal_output_counts"].get("902", 0)
            output_count = (
                output_901
                if level == 1
                else (output_901 + 2 * output_902) / base_required
            )
            low_upstream = conversion.get("upstream_low_cost_per_input_diamonds")
            low_upstream_energy = conversion.get("upstream_low_cost_per_input_energy")
            if low_upstream is not None and output_count:
                secondary_low_diamonds = low_upstream / output_count
                secondary_low_energy = (
                    (low_upstream_energy + conversion["nominal_direct_energy"])
                    / output_count
                )
                secondary_low_route = {
                    "expected_count": output_count,
                    "upstream_diamonds": low_upstream,
                    "total_energy": low_upstream_energy + conversion["nominal_direct_energy"],
                }
                display_low_producer = next(
                    (p for p in producers_by_series.get(8, []) if p["type"] == "705"),
                    low_producer,
                )
            upstream = next(
                (p for p in producers_by_series.get(8, []) if p["type"] == "711"),
                None,
            )
            if upstream:
                direct_901_count = high_producer["expected_base_per_cd"]
                secondary_805_count = upstream["expected_base_per_cd"] / 16
                secondary_901_count = (
                    output_901
                    * secondary_805_count
                )
                secondary_902_count = (
                    output_902
                    * secondary_805_count
                )
                total_901_equivalent = direct_901_count + secondary_901_count
                total_902_equivalent = secondary_902_count
                target_base_output = (
                    total_901_equivalent
                    if level == 1
                    else (total_901_equivalent + 2 * total_902_equivalent) / base_required
                )
                total_batch_diamonds = high_producer["expected_diamonds_per_batch"]
                total_batch_energy = (
                    high_producer["expected_energy_per_batch"]
                    + secondary_805_count * conversion["cost_energy_per_click"]
                    * conversion["nominal_clicks"]
                )
                if target_base_output:
                    item_multiplier = 1
                    combined_high_diamonds = (
                        total_batch_diamonds / target_base_output * item_multiplier
                    )
                    combined_high_energy = (
                        total_batch_energy / target_base_output * item_multiplier
                    )
                    combined_high_route = {
                        "direct_expected_count": direct_901_count if level == 1 else 0,
                        "secondary_expected_count": target_base_output,
                        "secondary_901_count": secondary_901_count,
                        "secondary_902_count": secondary_902_count,
                        "secondary_805_per_batch": secondary_805_count,
                        "target_base_output_per_batch": target_base_output,
                        "total_batch_diamonds": total_batch_diamonds,
                        "total_batch_energy": total_batch_energy,
                    }

        rows.append(
            {
                "series": series,
                "series_name": translations.get(f"item_{series * 100 + 1}_name", str(series)),
                "item_type": item_type,
                "item_name": translations.get(f"item_{item_type}_name", item_type),
                "level": level,
                "base_items_required": base_required,
                "shop_available": shop_available,
                "shop_diamonds": prop.get("Price") if shop_available else None,
                "shop_slots": prop.get("Slot") if shop_available else None,
                "bubble_available": bubble_available,
                "bubble_diamonds": prop.get("BubblePrice") if bubble_available else None,
                "bubble_chance_percent": model.get("BubbleChance", 0) if bubble_available else None,
                "selling_price": model.get("SellingPrice"),
                "order_diff_score": order_item.get("DiffScore") if order_item else None,
                "order_weight": order_item.get("Weight") if order_item else None,
                "order_difficulty_level": order_item.get("DifficultyLevel") if order_item else None,
                "order_repeat_weight_decrease": order_item.get("RepeatWeightDecrease") if order_item else None,
                "order_forbidden_slots": order_item.get("ForbiddenSlot") if order_item else None,
                "bubble_price_sale": prop.get("BubblePriceSale"),
                "shop_count": prop.get("ShopCount"),
                "shop_weight": prop.get("ShopWeight"),
                "rare": model.get("Rare"),
                "protect_level": model.get("ProtectLevel"),
                "order_available": order_item is not None,
                "order_coin_value": order_item.get("Price") if order_item else None,
                "order_baseline_coin_value": (
                    order_item.get("RecommendedPrice", order_item.get("Price")) if order_item else None
                ),
                "order_unlock_level": order_item.get("UnlockLevel") if order_item else None,
                "order_coin_is_contextual": bool(
                    order_item and order_item.get("RecommendedPrice") is not None
                    and order_item.get("RecommendedPrice") != order_item.get("Price")
                ),
                "bubble_order_coins_per_diamond": (
                    order_item.get("Price") / prop.get("BubblePrice")
                    if order_item and bubble_available and prop.get("BubblePrice")
                    else None
                ),
                "producer_available": bool(producers),
                "low_producer": display_low_producer,
                "high_producer": high_producer,
                "producer_low_diamonds": secondary_low_diamonds,
                "producer_high_diamonds": combined_high_diamonds,
                "producer_low_energy": secondary_low_energy,
                "producer_high_energy": combined_high_energy,
                "secondary_low_route": secondary_low_route,
                "combined_high_route": combined_high_route,
                "secondary_producers": secondary_by_output.get(item_type, []),
            }
        )

    series_summary = []
    for series in range(1, 21):
        series_rows = [row for row in rows if row["series"] == series]
        producers = producers_by_series.get(series, [])
        all_producers = {}
        for producer_list in producers_by_series.values():
            for producer in producer_list:
                all_producers[producer["type"]] = producer
        mother_producers = sorted(
            [producer for producer in all_producers.values() if producer["producer_series"] == series],
            key=lambda row: int(row["type"]),
        )
        series_summary.append(
            {
                "series": series,
                "name": series_rows[0]["series_name"],
                "item_count": len(series_rows),
                "shop_item_count": sum(row["shop_available"] for row in series_rows),
                "bubble_item_count": sum(row["bubble_available"] for row in series_rows),
                "producer_item_count": sum(row["producer_available"] for row in series_rows),
                "low_producer": producers[0] if producers else None,
                "high_producer": producers[-1] if producers else None,
                "mother_producers": mother_producers,
            }
        )

    output = {
        "version": "Gossip Harbor 3.98.10",
        "scope": "Main-board numeric item series 1-20",
        "methodology": {
            "shop": "Price, only when Slot is configured and ShopWeight > 0",
            "bubble": "BubblePrice, only when ItemModelConfig.BubbleChance > 0",
            "producer": "Per refreshed batch, full-price diamond cost = ItemSpeedUpCost + (StorageSpeedUpCost - ItemSpeedUpCost) / (StorageMaxNumber / ItemMaxNumber). For a target level L, expected usable target pieces are computed recursively from direct outputs at levels <= L: a level-k output contributes 1 / 2^(L-k) target pieces; higher-level outputs are not treated as divisible into lower-level pieces. Target-item diamonds and energy divide the batch cost by that expected target-piece count.",
            "weighting": "Fixed producers draw from the configured weighted list on every click. Weight_i determines probability Weight_i / sum(Weight), not inventory consumption. On the normal click path itemRestNumber decreases by exactly 1; the batch therefore allows ItemMaxNumber clicks. Outputs from other series still consume the same batch inventory.",
            "inventory": "At initial/opened state itemRestNumber = ItemMaxNumber and storageRestNumber = StorageMaxNumber. On the normal click path each click subtracts exactly 1 from itemRestNumber. When itemRestNumber is zero, the ordinary ItemRecoveryDuration runs; after it, itemRestNumber resets to ItemMaxNumber and storageRestNumber decreases by ItemMaxNumber. When storageRestNumber reaches zero, StorageRecoveryDuration runs and both layers refill to their configured maxima.",
            "exclusions": "Theoretical long-run full-price acceleration of every item and storage cooldown; excludes free waiting, partially elapsed cooldown discounts, buffs, board constraints, and value of other-series outputs. Energy counts configured CostEnergy per click; actual play may differ.",
            "order_coin": "Standard order coin value is the sum of OrderItemConfig.Price for each required piece. Baseline orders use RecommendedPrice when present. Player level controls eligibility, not the configured value; buffs and special order modes may alter the final reward.",
            "cooldown_price": "For the active phase, remaining_fraction = max(0, (phase_end - server_time) / phase_duration). Current diamond cost = max(ceil(remaining_fraction * phase_speedup_cost), 1). Opened state uses ItemSpeedUpCost unless storageRestNumber is zero, in which case it uses StorageSpeedUpCost; initializing/opening use their own configured costs.",
            "second_order": "Type 805 (处理过的海鲜) is a disposable secondary generator, not a one-shot conversion. Its configured ItemMaxNumber is 12 and each normal click costs CostEnergy=1, draws the 901/902 pool independently at 95%/5%, and consumes one remaining charge; it disappears only when remaining charges reach zero. For an actual lifecycle with N successful charge consumptions, expected 901/902 counts are 0.95N/0.05N and expected level-1-equivalent output is 1.05N. N=12 is the nominal full-charge case. The generic CosetRestNumber function has a multi-decrement branch, but the decompiled evidence does not show ordinary Type 805 clicks, ordinary item/storage cooldowns, or energy acceleration passing k>1; do not infer a multi-charge 805 path without a confirmed caller. Upstream cost is the cost of producing one level-5 Series 8 item (16 base items).",
        },
        "special_conversions": special_conversions,
        "series": series_summary,
        "rows": rows,
    }

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUTPUT_DIR / "diamond_pricing_analysis.json").write_text(
        json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    csv_path = OUTPUT_DIR / "diamond_pricing_analysis.csv"
    try:
        file = csv_path.open("w", encoding="utf-8-sig", newline="")
    except PermissionError:
        csv_path = OUTPUT_DIR / "diamond_pricing_analysis_updated.csv"
        file = csv_path.open("w", encoding="utf-8-sig", newline="")
    with file:
        fieldnames = [
            "series", "series_name", "item_type", "item_name", "level", "base_items_required",
            "shop_available", "shop_diamonds", "shop_slots", "bubble_available", "bubble_diamonds",
            "bubble_chance_percent", "selling_price", "order_diff_score", "order_weight",
            "order_difficulty_level", "order_repeat_weight_decrease", "order_forbidden_slots",
            "bubble_price_sale", "shop_count", "shop_weight", "rare", "protect_level",
            "order_available", "order_coin_value",
            "order_baseline_coin_value", "bubble_order_coins_per_diamond", "producer_available",
            "low_producer_type", "low_producer_name",
            "order_unlock_level", "order_coin_is_contextual", "producer_low_diamonds", "high_producer_type",
            "high_producer_name", "producer_high_diamonds",
            "producer_low_energy", "producer_high_energy",
        ]
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            low = row["low_producer"] or {}
            high = row["high_producer"] or {}
            writer.writerow(
                {
                    **{key: row.get(key) for key in fieldnames},
                    "shop_slots": ",".join(map(str, row["shop_slots"] or [])),
                    "low_producer_type": low.get("type"),
                    "low_producer_name": low.get("name"),
                    "producer_low_diamonds": round(row["producer_low_diamonds"], 6) if row["producer_low_diamonds"] is not None else None,
                    "high_producer_type": high.get("type"),
                    "high_producer_name": high.get("name"),
                    "producer_high_diamonds": round(row["producer_high_diamonds"], 6) if row["producer_high_diamonds"] is not None else None,
                    "producer_low_energy": round(row["producer_low_energy"], 6) if row["producer_low_energy"] is not None else None,
                    "producer_high_energy": round(row["producer_high_energy"], 6) if row["producer_high_energy"] is not None else None,
                }
            )
    print(f"Wrote {len(rows)} rows across {len(series_summary)} series to {OUTPUT_DIR}; CSV: {csv_path.name}")


if __name__ == "__main__":
    main()
