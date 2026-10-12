# 能量需求布尔值的具体来源

`CheckEnergy` 首先调用 `CostEnergy()`；它返回初始化时读入的 `m_costEnergy`（来自 `Spread_CostEnergy == 1`），但教程可由 `TutorialBoardHelper.GetForcedCostEnergy()` 覆盖。随后 `CanSupportBoostDisco()` 若当前主棋盘的 Disco 支持该母体，就把局部变量 `costEnergy` 强制设为 false。这个布尔值只控制后续是否扣能量，不跳过状态和落点检查。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明配置如何决定本次点击是否需要能量，以及免能量活动如何改变玩家看到的资源结果。

### 代入本页的值

假设 `Spread_CostEnergy=1`、Disco 未生效。布尔式为 `costEnergy=(1==1)=true`，因此后续需要检查余额并扣除 1 点；若改为 `Spread_CostEnergy=0`，则结果为 `false`，跳过扣能量但仍继续检查落点。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。
- [Generator Boost 母体替换配置](../../overrides/activity/detail.md#configuration-generator-boost)：GeneratorBoostActivityModel:GetItemModelConfig → ReloadItemModelConfig；按 Buff 选择 MoreLuckyProduce / ExtraProduce 并替换 ItemDataModel 中的母体配置。


<!-- generator-configs:end -->
