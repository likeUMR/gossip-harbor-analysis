# 能量余额比较与扣除

`CheckEnergy` 先用 `GetCostEnergyNum` 返回的最大档调用 `HasEnoughEnergy(boardModel:GetCostEnergyType(), maxCostCount)`；不足时设置 `popupBundleEnergyWindowForLackingEnergy=true`，发送 `BoardEventType.LackEnergy`，返回 false，次数和权重池都不变。通过时先把标记清 false，随后 `_TrySpread` 生成最终代码；`SpreadCostEnergy` 将棋盘能量类型映射为属性类型，按 `EnergyBoostModel.GetBoostCostNum(energyBoostRatio)` 调用 `PropertyDataManager:Consume(..., EBIType.SpreadItem, sourceCode)`，并记录实际扣除数。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明余额足够时扣除能量并继续落子，余额不足时在产出前失败。

### 代入本页的值

假设 `energy=3`、`cost=1`。先判断 `3>=1`，条件成立后调用 `Consume(1)`，余额变为 2，并写入 `m_testLastCostEnergyCount=1`；若输入改为 `energy=0`，`0>=1` 为假，直接返回 `false`，不生成物品。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。
- [能量增益适用母体](../boost/detail.md#configuration-energy-boost)：EnergyBoostModel:OnSyncDataFinished 直接 require EnergyBoostItemConfig，建立 m_mapTargetItemType；CanEnergyBoost 读取此适用集合。


<!-- generator-configs:end -->
