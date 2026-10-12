"""Run the terminal main-board simulation described in SIMULATION_SPEC.md.

The engine is deliberately event based. Configuration-derived mechanics and
simulation assumptions are kept separate in the output metadata so that the
results can be reproduced and audited.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import csv
import json
import math
import random
import statistics
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "analysis_data" / "json"
OUTPUT = ROOT / "analysis_output"
START_SECONDS = 10 * 3600
DAY_SECONDS = 86400
TOTAL_GOLD_TARGET = 1_551_042
SEEDS = list(range(2026092701, 2026092711))

# Calibrated from the supplied gameplay recording. The recording was sampled
# at 2 fps over the main-board-visible intervals; 333 motion bursts gave a
# median of 1.0 s and mean of 1.27 s. No touch overlay reliably distinguished
# producer taps from merges, so both use the same observed active-operation
# mean rather than inventing a type-specific split.
ACTION_TIME_SECONDS = 1.27
VIDEO_CALIBRATION = {
    "source": "share_video_tmp_3dfafdc66440676599f91a1d8c4b6bf01",
    "sample_fps": 2,
    "main_board_motion_bursts": 333,
    "motion_burst_mean_seconds": 1.27,
    "motion_burst_median_seconds": 1.0,
    "motion_burst_p75_seconds": 1.5,
    "excluded_blank_and_non_main_board": True,
    "producer_merge_split": "not identifiable from recording",
}

PLAYER_LABELS = {
    "zero": "0氪金玩家",
    "mid": "中氪金玩家",
    "top": "顶氪金玩家",
}

RANDOM_KIND = {1: "Random1", 2: "Random2", 3: "Random3", 4: "Random4", 9: "Random5New"}

SLOTS = [
    (1, 1),
    (2, 2),
    (3, 2),
    (4, 3),
    (5, 4),
    (8, 9),
]


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def weighted_choice(rng: random.Random, rows: list, weight):
    weights = [max(0.0, float(weight(row))) for row in rows]
    total = sum(weights)
    if not rows or total <= 0:
        return None
    point = rng.random() * total
    acc = 0.0
    for row, value in zip(rows, weights):
        acc += value
        if point < acc:
            return row
    return rows[-1]


@dataclass
class ProducerState:
    code: str
    cost_energy: int
    batch_max: int
    item_duration: int
    item_speedup: int
    storage_max: int
    storage_duration: int
    storage_speedup: int
    outputs: list[tuple[str, int]]
    batch_remaining: int
    storage_remaining: int
    ready_time: int = 0
    cooldown_kind: str | None = None

    def recover(self, now: int) -> None:
        if self.ready_time and now >= self.ready_time:
            if self.cooldown_kind == "storage":
                self.storage_remaining = self.storage_max
            self.batch_remaining = min(self.batch_max, self.storage_remaining)
            self.ready_time = 0
            self.cooldown_kind = None

    def available(self, now: int) -> bool:
        self.recover(now)
        return self.batch_remaining > 0 and self.storage_remaining > 0

    def consume(self, now: int) -> None:
        self.batch_remaining -= 1
        self.storage_remaining -= 1
        if self.storage_remaining == 0:
            self.cooldown_kind = "storage"
            self.ready_time = now + self.storage_duration
        elif self.batch_remaining == 0:
            self.cooldown_kind = "item"
            self.ready_time = now + self.item_duration

    def accelerate_cost(self, now: int) -> int:
        self.recover(now)
        if not self.ready_time or not self.cooldown_kind:
            return 0
        remaining = max(0, self.ready_time - now)
        if self.cooldown_kind == "storage":
            return math.ceil(self.storage_speedup * remaining / self.storage_duration)
        return math.ceil(self.item_speedup * remaining / self.item_duration)


class Simulation:
    def __init__(
        self,
        player_type: str,
        seed: int,
        config: dict,
        max_actions: int | None = None,
        record_events: bool = False,
    ):
        self.player_type = player_type
        self.seed = seed
        self.rng = random.Random(seed)
        self.config = config
        self.now = START_SECONDS
        self.energy = 100
        self.energy_recovery_progress = 0
        self.gold = 0
        self.gold_earned = 0
        self.main_gold_spent = 0
        self.task_index = 0
        self.level = 1
        self.exp = 0
        self.inventory = Counter()
        self.secondary_805_charges = 0
        self.orders: dict[int, dict] = {}
        self.slot_next_eligible = {slot: 0 for slot, _ in SLOTS}
        self.slot_next_eligible[15] = 60
        self.baseline_timer_started = True
        self.force_scan_time: int | None = None
        self.last_completed_codes: set[str] = set()
        self.shop: dict[int, dict] = {}
        self.bubbles: dict[str, dict] = {}
        self.last_shop_day = -1
        self.last_snapshot_day = -1
        self.daily_rows = []
        self.record_events = record_events
        self.timeline_events = []
        self.completed = False
        self.error: str | None = None
        self.action_count = 0
        self.max_actions = max_actions
        self.stats = Counter()
        self.order_counts = Counter()
        self.diamonds = Counter()
        self.production = defaultdict(Counter)
        self.merge_counts = Counter()
        self.producers = self._make_producers()
        self.output_to_producers = defaultdict(list)
        for state in self.producers.values():
            for code, weight in state.outputs:
                if code.isdigit() and 1 <= int(code) // 100 <= 20:
                    self.output_to_producers[int(code) // 100].append((state, weight))
        self._refresh_shop(0)
        self.scan_orders("initialization")

    def _record_event(self, event_type: str, **details) -> None:
        if not self.record_events:
            return
        self.timeline_events.append({
            "time": round(self.now, 2),
            "day": self.day + 1,
            "second_of_day": round(self.now % DAY_SECONDS, 2),
            "type": event_type,
            "energy": self.energy,
            "gold_balance": self.gold,
            "diamonds_spent_total": sum(self.diamonds.values()),
            **details,
        })

    def _make_producers(self) -> dict[str, ProducerState]:
        result = {}
        for code in self.config["producer_codes"]:
            row = self.config["models"][code]
            outputs = []
            for entry in row.get("Spread_Weight", []):
                item, raw_weight = entry.rsplit("-", 1)
                outputs.append((item, int(raw_weight)))
            batch = int(row["Spread_ItemMaxNumber"])
            storage = int(row.get("Spread_StorageMaxNumber") or batch)
            result[code] = ProducerState(
                code=code,
                cost_energy=int(row.get("Spread_CostEnergy", 0)),
                batch_max=batch,
                item_duration=int(row.get("Spread_ItemRecoveryDuration") or 0),
                item_speedup=int(row.get("Spread_ItemSpeedUpCost") or 0),
                storage_max=storage,
                storage_duration=int(row.get("Spread_StorageRecoveryDuration") or 0),
                storage_speedup=int(row.get("Spread_StorageSpeedUpCost") or 0),
                outputs=outputs,
                batch_remaining=batch,
                storage_remaining=storage,
            )
        return result

    @property
    def day(self) -> int:
        return int(self.now // DAY_SECONDS)

    def _expire_bubbles(self) -> None:
        for code in [code for code, row in self.bubbles.items() if row["expires"] <= self.now]:
            del self.bubbles[code]

    def _record_days_through(self, day_exclusive: int) -> None:
        for day in range(self.last_snapshot_day + 1, day_exclusive):
            if day < 0:
                continue
            self.daily_rows.append({
                "day": day + 1,
                "date": (datetime(2026, 1, 1) + timedelta(days=day)).date().isoformat(),
                "player_type": self.player_type,
                "run_id": self.seed,
                "cumulative_gold_earned": self.gold_earned,
                "cumulative_main_tasks_completed": self.task_index,
                "cumulative_main_gold_spent": self.main_gold_spent,
                "cumulative_orders_completed": sum(self.order_counts.values()),
                "cumulative_diamonds_spent": sum(self.diamonds.values()),
                "cumulative_energy_spent": self.stats["energy_spent"],
                "cumulative_energy_natural": self.stats["energy_natural"],
                "cumulative_energy_bought": self.stats["energy_bought"],
                "energy_remaining": self.energy,
            })
            self.last_snapshot_day = day

    def advance_to(self, target: float) -> None:
        if target < self.now:
            return
        old_day = self.day
        delta = target - self.now
        if self.energy < 100 and delta:
            total = self.energy_recovery_progress + delta
            gain = total // 120
            self.energy_recovery_progress = total % 120
            if gain:
                actual_gain = min(gain, 100 - self.energy)
                self.energy += actual_gain
                self.stats["energy_natural"] += actual_gain
                if self.energy >= 100:
                    self.energy_recovery_progress = 0
        self.now = target
        self._expire_bubbles()
        new_day = self.day
        if new_day > old_day:
            self._record_days_through(new_day)
            for day in range(max(old_day + 1, self.last_shop_day + 1), new_day + 1):
                self._refresh_shop(day)
        for producer in self.producers.values():
            producer.recover(self.now)

    def advance_action(self, seconds: float = ACTION_TIME_SECONDS) -> None:
        self.action_count += 1
        if self.action_count % 100_000 == 0:
            print(
                f"    progress actions={self.action_count:,} day={self.day + 1:,} "
                f"tasks={self.task_index:,} gold={self.gold_earned:,}",
                flush=True,
            )
        if self.max_actions is not None and self.action_count >= self.max_actions:
            self.error = f"max_actions={self.max_actions} reached"
        self.advance_to(self.now + seconds)

    def _refresh_shop(self, day: int) -> None:
        if day <= self.last_shop_day:
            return
        self.shop.clear()
        for slot in range(1, 7):
            candidates = [row for row in self.config["shop_rows"] if slot in (row.get("shop_slots") or [])]
            chosen = weighted_choice(self.rng, candidates, lambda row: row.get("shop_weight") or 0)
            if chosen:
                self.shop[slot] = {
                    "code": chosen["item_type"],
                    "remaining": int(chosen.get("shop_count") or 1),
                    "price": int(chosen["shop_diamonds"]),
                }
        self.last_shop_day = day
        self.stats["shop_natural_refreshes"] += 1

    def _order_candidates(self, minimum: int, maximum: int, slot: int, excluded_series: set[int]) -> list[dict]:
        rows = []
        active_codes = {req["code"] for order in self.orders.values() for req in order["requirements"]}
        for row in self.config["order_rows"]:
            level = row["level"]
            series = row["series"]
            if not minimum <= level <= maximum or series in excluded_series:
                continue
            forbidden = row.get("order_forbidden_slots") or []
            if slot in forbidden:
                continue
            rows.append(row)
        preferred = [row for row in rows if row["item_type"] not in active_codes]
        return preferred or rows

    def _create_random_order(self, slot: int, type_id: int) -> dict | None:
        cfg = self.config["random_by_type"][type_id]
        filt = cfg["Filters"][-1]
        amounts = cfg.get("ItemAmounts") or {"OneItemWeight": 30, "TwoItemsWeight": 30, "ThreeItemsWeight": 40}
        count_pick = weighted_choice(
            self.rng,
            [1, 2, 3],
            lambda value: amounts[{1: "OneItemWeight", 2: "TwoItemsWeight", 3: "ThreeItemsWeight"}[value]],
        )
        requirements = []
        excluded_series = set()
        for index, prefix in enumerate(("First", "Second", "Third")):
            if index >= count_pick:
                break
            minimum = int(filt.get(prefix + "Min", 1))
            maximum = int(filt.get(prefix + "Max", minimum))
            candidates = self._order_candidates(minimum, maximum, slot, excluded_series)
            if not candidates:
                candidates = self._order_candidates(minimum, maximum, slot, set())
            if not candidates:
                return None
            chosen = weighted_choice(
                self.rng,
                candidates,
                lambda row: (row.get("order_weight") or 0)
                / ((row.get("order_repeat_weight_decrease") or 1) if row["item_type"] in self.last_completed_codes else 1),
            )
            requirements.append({"code": chosen["item_type"], "count": 1})
            excluded_series.add(chosen["series"])
        return {
            "kind": RANDOM_KIND[type_id], "slot": slot, "type": type_id,
            "requirements": requirements, "created_time": round(self.now, 2),
        }

    def _create_baseline_order(self) -> dict | None:
        reserved = Counter()
        for order in self.orders.values():
            for req in order["requirements"]:
                reserved[req["code"]] += req["count"]
        candidates = []
        for row in self.config["baseline_rows"]:
            count = int(row["recommended_number"])
            if self.inventory[row["item_type"]] - reserved[row["item_type"]] >= count:
                candidates.append(row)
        if not candidates:
            return None
        chosen = self.rng.choice(candidates)
        return {
            "kind": "Baseline", "slot": 15, "type": 0,
            "requirements": [{"code": chosen["item_type"], "count": chosen["recommended_number"]}],
            "created_time": round(self.now, 2),
        }

    def scan_orders(self, reason: str) -> None:
        self.stats[f"scan_{reason}"] += 1
        while True:
            created = 0
            for slot, type_id in SLOTS:
                if slot in self.orders or self.now < self.slot_next_eligible[slot]:
                    continue
                order = self._create_random_order(slot, type_id)
                if order:
                    self.orders[slot] = order
                    created += 1
                    self.stats["orders_created"] += 1
            if 15 not in self.orders and self.now >= self.slot_next_eligible[15]:
                order = self._create_baseline_order()
                if order:
                    self.orders[15] = order
                    created += 1
                    self.stats["orders_created"] += 1
            if not created:
                break
        self._schedule_force_scan_if_empty()

    def _schedule_force_scan_if_empty(self) -> None:
        if self.orders:
            self.force_scan_time = None
            return
        next_times = [value for value in self.slot_next_eligible.values() if value > self.now]
        self.force_scan_time = min(next_times) if next_times else self.now

    def _force_scan_due(self) -> bool:
        return not self.orders and self.force_scan_time is not None and self.now >= self.force_scan_time

    def _requirements_met(self, order: dict) -> bool:
        return all(self.inventory[req["code"]] >= req["count"] for req in order["requirements"])

    def _order_gold(self, order: dict) -> int:
        price = 0
        for req in order["requirements"]:
            item = self.config["items"][req["code"]]
            field = "order_baseline_coin_value" if order["kind"] == "Baseline" else "order_coin_value"
            price += int(item[field]) * req["count"]
        return price

    def _producer_expected_base_per_energy(self, producer: ProducerState, series: int) -> float:
        total_weight = sum(weight for _, weight in producer.outputs)
        expected_base = sum(
            weight * 2 ** (int(code) % 100 - 1)
            for code, weight in producer.outputs
            if code.isdigit() and int(code) // 100 == series
        ) / total_weight
        if producer.cost_energy == 0:
            return math.inf
        return expected_base / producer.cost_energy

    def _order_production_energy_estimate(self, order: dict) -> float:
        """Estimate raw producer energy from zero inventory.

        This diagnostic deliberately follows mother output probabilities. It is
        not the order-efficiency denominator because co-products retain value.
        """
        needs_by_series: dict[int, dict[str, int]] = {}
        for req in order["requirements"]:
            item = self.config["items"][req["code"]]
            series = int(item["series"])
            entry = needs_by_series.setdefault(series, {"base": 0, "max_level": 0})
            entry["base"] += int(req["count"]) * 2 ** (int(item["level"]) - 1)
            entry["max_level"] = max(entry["max_level"], int(item["level"]))

        expected_energy = 0.0
        for series, need in needs_by_series.items():
            producer = self._producer_for_series(series)
            if producer is None:
                return math.inf
            base_per_energy = self._producer_expected_base_per_energy(producer, series)
            if math.isinf(base_per_energy):
                continue
            if base_per_energy <= 0:
                return math.inf
            expected_energy += need["base"] / base_per_energy
        return expected_energy

    def _order_priority_energy(self, order: dict) -> float:
        """Return the order-system base-equivalent energy denominator.

        Order priority values a requested level-L item as 2**(L-1) level-1
        pieces. This matches the order quantification table and avoids charging
        an order for all clicks on a mother that also produces useful co-products.
        """
        return sum(
            int(req["count"]) * 2 ** (int(self.config["items"][req["code"]]["level"]) - 1)
            for req in order["requirements"]
        )

    def _order_priority(self, order: dict) -> tuple:
        gold = self._order_gold(order)
        energy = self._order_priority_energy(order)
        efficiency = gold / energy if energy > 0 and math.isfinite(energy) else (math.inf if energy == 0 else 0)
        return (-efficiency, -gold, energy, order["slot"])

    def _ordered_orders(self) -> list[dict]:
        return sorted(self.orders.values(), key=self._order_priority)

    def _submit_one(self) -> bool:
        ordered = self._ordered_orders()
        if not ordered or not self._requirements_met(ordered[0]):
            return False
        order = ordered[0]
        for req in order["requirements"]:
            self.inventory[req["code"]] -= req["count"]
        price = self._order_gold(order)
        self.gold += price
        self.gold_earned += price
        self.stats["gold_earned"] += price
        self.order_counts[order["kind"]] += 1
        self.last_completed_codes = {req["code"] for req in order["requirements"]}
        slot = order["slot"]
        priority_energy = self._order_priority_energy(order)
        production_energy = self._order_production_energy_estimate(order)
        efficiency = price / priority_energy if priority_energy > 0 and math.isfinite(priority_energy) else None
        requirement_details = []
        for req in order["requirements"]:
            item = self.config["items"][req["code"]]
            requirement_details.append({
                "code": req["code"], "name": item.get("item_name", req["code"]),
                "series": item["series"], "level": item["level"], "count": req["count"],
            })
        if order["kind"] == "Baseline":
            self.slot_next_eligible[slot] = self.now + 60
        else:
            refresh = self.config["random_by_type"][order["type"]]["RefreshTime"]
            self.slot_next_eligible[slot] = self.now + int(refresh)
        del self.orders[slot]
        self._record_event(
            "order_complete", subtype=order["kind"], slot=slot, gold=price,
            requirements=requirement_details, expected_total_energy=priority_energy,
            estimated_production_energy=production_energy,
            gold_energy_ratio=efficiency, created_time=order["created_time"],
            completion_seconds=round(self.now - order["created_time"], 2),
        )
        self.advance_action()
        self._advance_main_tasks()
        self.scan_orders("order_complete")
        return True

    def _advance_main_tasks(self) -> None:
        start_index = self.task_index
        start_spent = self.main_gold_spent
        while self.task_index < len(self.config["tasks"]):
            task = self.config["tasks"][self.task_index]
            cost = int(task["cost"])
            if self.gold < cost:
                break
            self.gold -= cost
            self.main_gold_spent += cost
            self.task_index += 1
            old_level = self.level
            for reward in task.get("rewards", []):
                if reward.startswith("exp-"):
                    self.exp += int(reward.split("-", 1)[1])
            while self.level - 1 < len(self.config["level_costs"]) and self.exp >= self.config["level_costs"][self.level - 1]:
                self.exp -= self.config["level_costs"][self.level - 1]
                self.level += 1
            for _ in range(self.level - old_level):
                self.scan_orders("level_up")
            if self.task_index >= len(self.config["tasks"]):
                self.completed = True
                break
        if self.task_index > start_index:
            self._record_event(
                "main_progress",
                tasks_advanced=self.task_index - start_index,
                tasks_completed=self.task_index,
                gold_spent=self.main_gold_spent - start_spent,
            )

    def _inventory_base(self, series: int, max_level: int) -> int:
        return sum(
            count * (2 ** (int(code) % 100 - 1))
            for code, count in self.inventory.items()
            if code.isdigit() and int(code) // 100 == series and int(code) % 100 <= max_level
        )

    def _needed_requirement(self) -> tuple[dict, dict] | None:
        for order in self._ordered_orders():
            for req in order["requirements"]:
                if self.inventory[req["code"]] < req["count"]:
                    return order, req
        return None

    def _spawn_bubble(self, code: str) -> None:
        row = self.config["items"].get(code)
        if not row or not row.get("bubble_available") or code in self.bubbles:
            return
        if self.rng.random() * 100 >= float(row.get("bubble_chance_percent") or 0):
            return
        self.bubbles[code] = {"expires": self.now + 60, "price": int(row["bubble_diamonds"])}
        self.stats["bubbles_spawned"] += 1

    def _merge_one_for(self, req: dict) -> bool:
        row = self.config["items"][req["code"]]
        series, target_level = row["series"], row["level"]
        for level in range(1, target_level):
            code = str(series * 100 + level)
            if self.inventory[code] >= 2:
                result = str(series * 100 + level + 1)
                self.inventory[code] -= 2
                self.inventory[result] += 1
                self.merge_counts[str(series)] += 1
                self.advance_action()
                self._spawn_bubble(result)
                return True
        return False

    def _prepare_805(self) -> bool:
        if self.inventory["805"] > 0:
            self.inventory["805"] -= 1
            self.secondary_805_charges += 12
            return True
        for level in range(1, 5):
            code = str(800 + level)
            if self.inventory[code] >= 2:
                result = str(801 + level)
                self.inventory[code] -= 2
                self.inventory[result] += 1
                self.merge_counts["8"] += 1
                self.advance_action()
                self._spawn_bubble(result)
                return True
        return False

    def _buy_relevant_bubble(self) -> bool:
        if self.player_type == "zero":
            return False
        needed = self._needed_requirement()
        if not needed:
            return False
        _, req = needed
        target = self.config["items"][req["code"]]
        choices = []
        for code, bubble in self.bubbles.items():
            row = self.config["items"].get(code)
            if row and row["series"] == target["series"] and row["level"] <= target["level"]:
                choices.append((bubble["price"], -row["level"], code))
        if not choices:
            return False
        price, _, code = min(choices)
        self.inventory[code] += 1
        self.diamonds["bubble_items"] += price
        del self.bubbles[code]
        row = self.config["items"][code]
        self._record_event(
            "payment", subtype="bubble_items", diamonds=price, code=code,
            item_name=row.get("item_name", code), series=row["series"], level=row["level"], quantity=1,
        )
        self.advance_action()
        return True

    def _buy_relevant_shop(self) -> bool:
        if self.player_type == "zero":
            return False
        needed = self._needed_requirement()
        if not needed:
            return False
        _, req = needed
        target = self.config["items"][req["code"]]
        needed_base = req["count"] * 2 ** (target["level"] - 1)
        deficit = needed_base - self._inventory_base(target["series"], target["level"])
        choices = []
        for slot, shop in self.shop.items():
            if shop["remaining"] <= 0:
                continue
            row = self.config["items"].get(shop["code"])
            if not row or row["series"] != target["series"] or row["level"] > target["level"]:
                continue
            contribution = 2 ** (row["level"] - 1)
            if contribution <= deficit:
                choices.append((shop["price"] / contribution, -row["level"], slot))
        if not choices:
            return False
        _, _, slot = min(choices)
        shop = self.shop[slot]
        self.inventory[shop["code"]] += 1
        shop["remaining"] -= 1
        self.diamonds["shop_items"] += shop["price"]
        self._record_event(
            "payment", subtype="shop_items", diamonds=shop["price"], code=shop["code"], shop_slot=slot,
            item_name=self.config["items"][shop["code"]].get("item_name", shop["code"]),
            series=self.config["items"][shop["code"]]["series"],
            level=self.config["items"][shop["code"]]["level"], quantity=1,
        )
        self.advance_action()
        return True

    def _producer_for_series(self, series: int) -> ProducerState | None:
        choices = self.output_to_producers.get(series, [])
        if not choices:
            return None
        expected = []
        for producer, _ in choices:
            base_per_energy = self._producer_expected_base_per_energy(producer, series)
            expected.append((-base_per_energy, producer.code, producer))
        return min(expected)[2]

    def _click_producer(self, producer: ProducerState) -> None:
        chosen = weighted_choice(self.rng, producer.outputs, lambda row: row[1])
        code = chosen[0]
        producer.consume(self.now)
        self.energy -= producer.cost_energy
        self.stats["energy_spent"] += producer.cost_energy
        self.inventory[code] += 1
        self.production[producer.code][code] += 1
        self.production[producer.code]["clicks"] += 1
        self.advance_action()

    def _click_805(self) -> None:
        chosen = weighted_choice(self.rng, [("901", 95), ("902", 5)], lambda row: row[1])
        self.secondary_805_charges -= 1
        self.energy -= 1
        self.stats["energy_spent"] += 1
        self.inventory[chosen[0]] += 1
        self.production["805"][chosen[0]] += 1
        self.production["805"]["clicks"] += 1
        self.advance_action()

    def _buy_energy(self) -> bool:
        daily_count_key = f"energy_buys_day_{self.day}"
        count = self.stats[daily_count_key]
        if self.player_type == "zero":
            if count >= 1:
                return False
            price = 10
        elif self.player_type == "mid":
            if count >= 3:
                return False
            price = (10, 20, 40)[count]
        else:
            price = (10, 20, 40, 80, 160)[min(count, 4)]
        self.stats[daily_count_key] += 1
        self.stats["energy_buys"] += 1
        self.stats["energy_bought"] += 100
        self.energy += 100
        self.energy_recovery_progress = 0
        self.diamonds["energy"] += price
        self._record_event(
            "payment", subtype="energy", diamonds=price, energy_purchased=100,
            purchase_index_of_day=count + 1,
        )
        self.advance_action()
        return True

    def _accelerate(self, producer: ProducerState, req: dict) -> None:
        cost = producer.accelerate_cost(self.now)
        self.diamonds["producer_speedup"] += cost
        self.stats["producer_speedups"] += 1
        self.production[producer.code]["speedups"] += 1
        self.production[producer.code]["speedup_diamonds"] += cost
        self._record_event(
            "payment", subtype="producer_speedup", diamonds=cost, producer=producer.code,
            target=req["code"], cooldown_seconds_removed=round(max(0, producer.ready_time - self.now), 2),
        )
        producer.ready_time = self.now
        producer.recover(self.now)
        self.advance_action()

    def _drain_free_one(self) -> bool:
        producer = self.producers.get("1010")
        if producer and producer.available(self.now):
            self._click_producer(producer)
            return True
        return False

    def process_session(self, full_session: bool) -> None:
        iterations = 0
        while not self.completed and not self.error:
            iterations += 1
            if iterations > 2_000_000:
                self.error = "session iteration guard"
                break
            if self._force_scan_due():
                self.force_scan_time = None
                self.scan_orders("force_empty")
                continue
            if self._submit_one():
                continue
            needed = self._needed_requirement()
            if needed and self._merge_one_for(needed[1]):
                continue
            if self._buy_relevant_shop():
                continue
            if self._buy_relevant_bubble():
                continue
            if self._drain_free_one():
                continue
            if not full_session:
                break
            if not needed:
                if not self.orders:
                    self._schedule_force_scan_if_empty()
                break
            _, req = needed
            target = self.config["items"][req["code"]]
            if target["series"] == 9:
                if self.secondary_805_charges:
                    if self.energy < 1:
                        if self._buy_energy():
                            continue
                        break
                    self._click_805()
                    continue
                if self._prepare_805():
                    continue
            producer = self._producer_for_series(target["series"])
            if producer is None:
                self.error = f"no producer for series {target['series']}"
                break
            if not producer.available(self.now):
                if self.player_type == "top":
                    self._accelerate(producer, req)
                    continue
                break
            if self.energy < producer.cost_energy:
                if self._buy_energy():
                    continue
                break
            self._click_producer(producer)

    def next_login_after(self) -> int:
        day = self.day
        second = self.now % DAY_SECONDS
        for hour in range(10, 20):
            candidate = day * DAY_SECONDS + hour * 3600
            if candidate > self.now:
                return candidate
        return (day + 1) * DAY_SECONDS + 10 * 3600

    def next_event(self) -> tuple[int, str]:
        # Offline time advances recovery and eligibility, but never wakes the
        # player for active operations or diamond spending.
        return self.next_login_after(), "login"

    def run(self, max_days: int = 100_000) -> dict:
        self._record_event("login", subtype="scheduled")
        self.process_session(True)
        while not self.completed and not self.error and self.day < max_days:
            target, kind = self.next_event()
            self.advance_to(target)
            if kind == "login":
                self._record_event("login", subtype="scheduled")
                self.process_session(True)
        if not self.completed and not self.error:
            self.error = f"max_days={max_days} reached"
        self._record_days_through(self.day + 1)
        return self.result()

    def result(self) -> dict:
        inventory = []
        for code, count in sorted(self.inventory.items(), key=lambda row: (int(row[0]) if row[0].isdigit() else 10**9, row[0])):
            if count <= 0:
                continue
            item = self.config["items"].get(code, {})
            inventory.append({
                "code": code,
                "name": item.get("item_name", code),
                "series": item.get("series"),
                "level": item.get("level"),
                "count": count,
                "base_equivalent": count * (2 ** (item.get("level", 1) - 1)),
            })
        producer_rows = []
        for code, state in sorted(self.producers.items(), key=lambda row: int(row[0])):
            state.recover(self.now)
            producer_rows.append({
                "code": code,
                "batch_remaining": state.batch_remaining,
                "storage_remaining": state.storage_remaining,
                "cooldown_kind": state.cooldown_kind,
                "cooldown_remaining": max(0, state.ready_time - self.now),
            })
        diamond_total = sum(self.diamonds.values())
        return {
            "player_type": self.player_type,
            "player_label": PLAYER_LABELS[self.player_type],
            "seed": self.seed,
            "completed": self.completed,
            "error": self.error,
            "completion_seconds": self.now - START_SECONDS,
            "completion_days": (self.now - START_SECONDS) / DAY_SECONDS,
            "completion_timestamp": (datetime(2026, 1, 1, 10) + timedelta(seconds=self.now - START_SECONDS)).isoformat(),
            "tasks_completed": self.task_index,
            "level": self.level,
            "gold_earned": self.gold_earned,
            "gold_spent": self.main_gold_spent,
            "gold_remaining": self.gold,
            "energy_spent": self.stats["energy_spent"],
            "energy_natural": self.stats["energy_natural"],
            "energy_bought": self.stats["energy_bought"],
            "energy_buys": self.stats["energy_buys"],
            "energy_remaining": self.energy,
            "diamonds": {
                "energy": self.diamonds["energy"],
                "shop_items": self.diamonds["shop_items"],
                "bubble_items": self.diamonds["bubble_items"],
                "shop_refresh": 0,
                "producer_speedup": self.diamonds["producer_speedup"],
                "total": diamond_total,
            },
            "orders_completed": dict(self.order_counts),
            "actions": self.action_count,
            "scans": {key.removeprefix("scan_"): value for key, value in self.stats.items() if key.startswith("scan_")},
            "production": {code: dict(values) for code, values in self.production.items()},
            "merges_by_series": dict(self.merge_counts),
            "inventory": inventory,
            "producers": producer_rows,
            "unexpired_bubbles": [{"code": code, **row} for code, row in self.bubbles.items()],
            "daily": self.daily_rows,
            "timeline_events": self.timeline_events,
        }


def build_config() -> dict:
    pricing = load_json(OUTPUT / "diamond_pricing_analysis.json")
    progress = load_json(OUTPUT / "f2p_progress_data.json")
    models = load_json(DATA / "ItemModelConfig.json")
    random_cfg = load_json(DATA / "OrderRandomConfig.json")
    model_by_code = {row["Type"]: row for row in models}
    items = {row["item_type"]: row for row in pricing["rows"]}
    producer_codes = []
    for series in pricing["series"]:
        mothers = series.get("mother_producers") or []
        if mothers:
            producer_codes.append(max(mothers, key=lambda row: int(row["type"]))["type"])
    order_rows = [row for row in pricing["rows"] if row.get("order_available") and (row.get("order_weight") or 0) > 0]
    baseline_rows = []
    raw_order_items = {row["Code"]: row for row in load_json(DATA / "OrderItemConfig.json")}
    for code, raw in raw_order_items.items():
        if raw.get("RecommendedNumber") and code in items:
            baseline_rows.append({
                **items[code],
                "recommended_number": int(raw["RecommendedNumber"]),
                "recommended_price": int(raw.get("RecommendedPrice", raw["Price"])),
            })
    tasks = [{"cost": node["cost"], "rewards": node.get("rewards", [])} for node in progress["nodes"]]
    level_costs = [int(row["cost_exp"]) for row in progress["level_rewards"]]
    return {
        "models": model_by_code,
        "items": items,
        "producer_codes": producer_codes,
        "order_rows": order_rows,
        "baseline_rows": baseline_rows,
        "random_by_type": {row["Type"]: row for row in random_cfg},
        "shop_rows": [row for row in pricing["rows"] if row.get("shop_available")],
        "tasks": tasks,
        "level_costs": level_costs,
    }


def summarize(results: list[dict]) -> dict:
    summaries = []
    metrics = [
        "completion_days", "gold_earned", "energy_spent", "energy_bought",
        "energy_buys", "actions",
    ]
    for player_type in PLAYER_LABELS:
        rows = [row for row in results if row["player_type"] == player_type]
        if not rows:
            continue
        summary = {"player_type": player_type, "player_label": PLAYER_LABELS[player_type], "runs": len(rows)}
        for metric in metrics:
            values = [row[metric] for row in rows]
            summary[metric] = {
                "mean": statistics.fmean(values),
                "median": statistics.median(values),
                "min": min(values),
                "max": max(values),
            }
        for category in ("energy", "shop_items", "bubble_items", "shop_refresh", "producer_speedup", "total"):
            values = [row["diamonds"][category] for row in rows]
            summary[f"diamonds_{category}"] = {
                "mean": statistics.fmean(values), "median": statistics.median(values), "min": min(values), "max": max(values)
            }
        summaries.append(summary)
    return {"players": summaries}


def select_typical_day(result: dict) -> dict:
    events = result.get("timeline_events", [])
    by_day: dict[int, list[dict]] = defaultdict(list)
    for event in events:
        by_day[int(event["day"])].append(event)
    if not by_day:
        raise ValueError("representative run has no timeline events")

    first_day, last_day = min(by_day), max(by_day)
    eligible_days = [day for day in sorted(by_day) if first_day < day < last_day]
    if not eligible_days:
        eligible_days = sorted(by_day)
    event_types = ("order_complete", "payment", "main_progress")
    counts = {
        day: {event_type: sum(event["type"] == event_type for event in by_day[day]) for event_type in event_types}
        for day in eligible_days
    }
    medians = {
        event_type: statistics.median(counts[day][event_type] for day in eligible_days)
        for event_type in event_types
    }
    complete_days = [day for day in eligible_days if all(counts[day][event_type] > 0 for event_type in event_types)]
    candidates = complete_days or eligible_days

    def distance(day: int) -> tuple[float, int]:
        score = sum(
            abs(counts[day][event_type] - medians[event_type]) / max(1.0, medians[event_type])
            for event_type in event_types
        )
        return score, day

    selected_day = min(candidates, key=distance)
    selected_events = sorted(by_day[selected_day], key=lambda event: (event["second_of_day"], event["type"]))
    subtype_counts = Counter(
        event.get("subtype", event["type"])
        for event in selected_events
        if event["type"] == "payment"
    )
    return {
        "player_type": result["player_type"],
        "player_label": result["player_label"],
        "seed": result["seed"],
        "day": selected_day,
        "date": (datetime(2026, 1, 1) + timedelta(days=selected_day - 1)).date().isoformat(),
        "selection_method": "排除首尾日后，选择订单完成、支付、主线推进三类事件计数最接近各自日中位数的日期；优先要求三类事件均出现。",
        "median_event_counts": medians,
        "event_counts": Counter(event["type"] for event in selected_events),
        "payment_subtype_counts": subtype_counts,
        "events": selected_events,
    }


def write_typical_days(results: list[dict], output_path: Path) -> None:
    representative_results = [
        result for result in results
        if result["seed"] == SEEDS[0] and result.get("timeline_events")
    ]
    if not representative_results:
        raise ValueError("no representative runs contain timeline events")
    payload = {
        "selection_method": "每类玩家使用首个固定种子；排除首尾日后，选择订单完成、支付、主线推进三类事件计数最接近各自日中位数的日期，并优先要求三类事件均出现。",
        "players": [select_typical_day(result) for result in representative_results],
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def write_outputs(results: list[dict], output_path: Path, daily_output_path: Path) -> None:
    OUTPUT.mkdir(exist_ok=True)
    compact_results = []
    daily_output_path.parent.mkdir(parents=True, exist_ok=True)
    with daily_output_path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=[
            "day", "date", "player_type", "run_id", "cumulative_gold_earned",
            "cumulative_main_tasks_completed", "cumulative_main_gold_spent",
            "cumulative_orders_completed", "cumulative_diamonds_spent",
            "cumulative_energy_spent", "cumulative_energy_natural",
            "cumulative_energy_bought", "energy_remaining",
        ])
        writer.writeheader()
        for result in results:
            writer.writerows(result["daily"])
            compact_results.append({
                key: value for key, value in result.items() if key not in {"daily", "timeline_events"}
            })
    payload = {
        "metadata": {
            "spec": "SIMULATION_SPEC.md",
            "version": "Gossip Harbor 3.98.10 local Lua_Config snapshot",
            "seeds": SEEDS,
            "runs": len(results),
            "created_by": "tools/run_terminal_simulation.py",
            "known_approximations": [
                "Random orders use the last Filter unconditionally and retain candidate weights/slot exclusions.",
                "Bubble sampling uses configured base BubbleChance with neutral unavailable remote multipliers.",
                "Daily shop samples one weighted configured item per slot at 00:00.",
                "Producer inventory is modeled as batch and total click capacities with configured recovery durations.",
                "Active operation time is calibrated from the supplied gameplay recording; producer taps and merges use the same mean because the recording has no reliable action-type marker.",
                "Order choice is recalculated after every action using order gold divided by base-equivalent order energy; producer-probability energy is retained as a separate diagnostic estimate.",
            ],
            "video_calibration": VIDEO_CALIBRATION,
        },
        "summary": summarize(results),
        "runs": compact_results,
    }
    output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def run_one(job: tuple[str, int, int, int | None, bool]) -> dict:
    player, seed, max_days, max_actions, record_events = job
    config = build_config()
    print(f"running {player} seed={seed}", flush=True)
    result = Simulation(
        player, seed, config, max_actions=max_actions, record_events=record_events
    ).run(max_days)
    print(
        f"  completed={result['completed']} days={result['completion_days']:.2f} "
        f"tasks={result['tasks_completed']} diamonds={result['diamonds']['total']} error={result['error']}",
        flush=True,
    )
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--player", choices=list(PLAYER_LABELS) + ["all"], default="all")
    parser.add_argument("--seed", type=int)
    parser.add_argument("--max-days", type=int, default=100_000)
    parser.add_argument("--max-actions", type=int)
    parser.add_argument("--jobs", type=int, default=1)
    parser.add_argument("--output", type=Path, default=OUTPUT / "terminal_simulation_results.json")
    parser.add_argument("--daily-output", type=Path)
    parser.add_argument("--typical-days-output", "--typical-day-output", dest="typical_days_output", type=Path)
    args = parser.parse_args()
    players = list(PLAYER_LABELS) if args.player == "all" else [args.player]
    seeds = [args.seed] if args.seed is not None else SEEDS
    representative_seed = SEEDS[0]
    jobs = [
        (
            player,
            seed,
            args.max_days,
            args.max_actions,
            args.typical_days_output is not None and seed == representative_seed,
        )
        for player in players for seed in seeds
    ]
    if args.jobs > 1 and len(jobs) > 1:
        with concurrent.futures.ProcessPoolExecutor(max_workers=args.jobs) as pool:
            results = list(pool.map(run_one, jobs))
    else:
        results = [run_one(job) for job in jobs]
    results.sort(key=lambda row: (list(PLAYER_LABELS).index(row["player_type"]), row["seed"]))
    daily_output = args.daily_output
    if daily_output is None:
        if args.output.resolve() == (OUTPUT / "terminal_simulation_results.json").resolve():
            daily_output = OUTPUT / "terminal_simulation_daily.csv"
        else:
            daily_output = args.output.with_name(f"{args.output.stem}_daily.csv")
    if args.typical_days_output is not None:
        write_typical_days(results, args.typical_days_output)
    write_outputs(results, args.output, daily_output)
    print(f"wrote {args.output}")
    print(f"wrote {daily_output}")
    if args.typical_days_output is not None:
        print(f"wrote {args.typical_days_output}")


if __name__ == "__main__":
    main()
