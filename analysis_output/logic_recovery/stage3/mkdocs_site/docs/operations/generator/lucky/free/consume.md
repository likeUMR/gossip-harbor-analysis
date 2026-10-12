# 阈值检查与消费

`_CanFreeLuckyProduce` 检查队首阈值是否已被当前能量消耗计数达到；命中后 `_PostProcessOnFreeLuckyProduce` 移除队首并保存队列。本次不减少 `tl_<sourceType>`。

**源码**：`_CanFreeLuckyProduce`、`_PostProcessOnFreeLuckyProduce`。**状态**：`elpec`、EnergyCostCount。每日重置和实际能量计数来源 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例已有 1 次免费 Lucky 资格，因此点击时直接消费资格并生成 1 个 Lucky 物品；普通机会和能量不会因为这次免费领取重复扣除。

### 代入本页的值

假设免费队列为 `[204]`，`_CanFreeLuckyProduce()` 返回 `true`。消费队首后队列变为空，`tl_105` 保持 60（免费产出不占普通机会），再用 Lucky 物品池抽出 204；若队列为空则函数直接返回 false。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- 免费 Lucky 服务器字段：LuckyProduceModel:_LoadOtherServerConfig 载入 luckyProduceConfig；_AddFreeLuckyProduceEnergyCostCount 读取 energy_cost.range_entry 与 extra_lucky。


<!-- generator-configs:end -->
