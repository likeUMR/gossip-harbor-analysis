# Super Lucky：奖励分类与表现

选中物品后检查它是否存在于 `config.super_items`。普通 Lucky 产生 `SuperLucky` 或 `Lucky`；免费 Lucky 产生 `FreeSuperLucky` 或 `FreeLucky`。这是产出类型标记，不会改变前面机会池是否扣减的结果。

**配置**：`LuckyProduceConfig.super_items`。**源码**：`_GetGenerateLuckyItem`。活动配置覆盖 `runtime-pending`。

<!-- lucky-classification-explanation:start -->

## 这一步做什么，不会增加什么

Super Lucky 是对**已经抽出的物品**进行分类，并选择对应表现。`super_items` 列出哪些物品采用 Super 分类；系统不从这份名单再次抽奖。分类本身不新增随机数，不重新消耗机会池、不另生成一件奖励，也不提升已经选中的物品等级。

### 按实际执行顺序分类

1. `_GetGenerateLuckyItem` 先从 `config.lucky_items` 抽取 `luckyItems`。Smart Produce 开启时使用临时 `Weight_Smart`，否则使用普通 `Weight`。
2. 先读取 `customSpreadType`。连续 Lucky 已传入 DoubleLucky / TripleLucky1 / TripleLucky2 时，直接保留，跳过下面的普通/Super分类。
3. 没有自定义类型时，检查 `luckyItems.Item` 是否在 `config.super_items` 中，再结合 `isFree` 设置类型。
4. 返回同一个 `luckyItems.Item` 与分类结果。该函数没有在物品池中扣除选中物品的权重；Super 分类也不修改之前的机会池计数。

| 已有连续自定义类型 | 免费资格 | 属于 super_items | 返回类型 |
|---|---|---|---|
| 有 | 任意 | 不再检查 | 原有 DoubleLucky / TripleLucky 类型 |
| 无 | 否 | 否 | Lucky |
| 无 | 否 | 是 | SuperLucky |
| 无 | 是 | 否 | FreeLucky |
| 无 | 是 | 是 | FreeSuperLucky |

```python
item = weighted_select(lucky_items, smart_weight_if_enabled)
if custom_type is not None:
    spread_type = custom_type
elif is_free:
    spread_type = "FreeSuperLucky" if item in super_items else "FreeLucky"
else:
    spread_type = "SuperLucky" if item in super_items else "Lucky"
return item, spread_type
```

### 为什么玩家会感觉它是一种更大的奖励？

已恢复视图代码给 SuperLucky / FreeSuperLucky 选择专用的上下层 Super 特效；棋盘视图选择 `sfxLuckyProduce2` 音效和 `ItemSpreadPromptLuckySuper` 提示。普通 Lucky 使用另一组表现。因此相同的一次产物生成会以不同方式强调给玩家。

分类依据是**抽中的原始物品**。之后 `ItemSpread:TryGenerateLuckyItem` 还可能按活动调整后的能量增益档沿 `MergedType` 升级物品，但不会在该函数内重新进行 Super 分类。复刻时应分别保存原始抽取结果、分类类型和最终落子代码。

### 活动追加奖励应怎样理解？

GeneratorBoost 监听 `ItemSpread` 事件。母体支持 GeneratorBoost 时，Lucky、SuperLucky、FreeLucky、FreeSuperLucky 都可进入 `TryExtraLuckyProduceItem`；该函数还要求 ExtraLuckyProduce Buff 生效并找到空格，才在该空格生成与本次最终产物同类型的物品，参数为 `costEnergy=false`、`spreadType=GeneratorBoostExtraLucky`。

这份追加奖励来自独立活动 Buff，不是 Super 分类独有的奖励，也不是又抽了一次 Super 奖池。新生成的物品仍进入棋盘事件链；该链全部消费者及实际账号活动状态需要进一步验证。

### 如何计算 Super 物品的占比？

没有连续自定义类型时，在“已经取得 Lucky 资格”的条件下，Super 分类占比为：`super_items 中候选物品的有效权重之和 / lucky_items 全部有效权重之和`。Smart 开启时使用修正后的有效权重，不能仍套原始权重。这个占比是已有物品抽样的结果分类，不是额外机会概率；若要算一次点击的最终概率，还需考虑资格路径、等级/活动配置与连续类型。

**底层证据**：LuckyProduceModel `_GetGenerateLuckyItem`（215–234）、`IsSuperLuckyProduce`（250–255）；ItemSpread `TryGenerateLuckyItem`；GeneratorBoostActivityModel `_OnItemSpread`、`TryExtraLuckyProduceItem`；MainBoardView 的产出音效分派与 `_PlayItemSpreadPrompt`；Super 特效分派。分类与上述消费者分支为 `source-confirmed`，实际活动配置、消费者完整闭包和原版表现回放为 `runtime-pending`。

<!-- lucky-classification-explanation:end -->

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-204.png" alt="Lucky 产物 204" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例抽到的 204 被识别为普通 Lucky 奖励，不是免费奖励，也不是更高阶的 Super 物品，因此按普通 Lucky 奖励展示给玩家。

### 代入本页的值

主案例沿用前文：抽到 204、`isFree=false`，204 不在 Super 名单内，因此返回普通 `Lucky`，不发生第二次抽样。下面保留两个独立对照场景，用来解释其它类型；它们不是主案例的后续步骤。

假设 `super_items={205}`，候选先抽到 205，且 `isFree=false`，因此它被判定为 SuperLucky ，物品仍来自前面已经完成的同一次抽取，并采用 Super 专用表现；没有进入独立奖池。为演示免费分支，再设下一次候选为 204、`isFree=true`，则判定为 FreeLucky，玩家领取免费奖励。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [Lucky 包内配置及活动变体](../chance/load.md#configuration-lucky)：LuckyProduceModel:_LoadFileConfig → _GetLevelFitConfig → Try2ProduceLuckyItem；按 generator、等级区间选择记录，再用 lucky_chance 重装机会池。


<!-- generator-configs:end -->
