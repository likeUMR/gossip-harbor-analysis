# 基础消耗和倍增比率

需要能量时，`ItemSpread.GetCostEnergyNum(itemType)` 默认返回 `nCostNum=1,nEnergyBoostRatio=0`；若 `EnergyBoostModel:CanEnergyBoost(itemType)` 为真，则改读当前增益档的消耗和最大比率。这个最大消耗只用于 `HasEnoughEnergy` 的余额检查，并不等于最终扣除。`GenerateItemCode` 可能进一步改写比率，之后 `EnergyBoostModel.GetBoostCostNum(energyBoostRatio)` 才得到最终整数消耗。

`SpreadCheckEnergyRatioAndCode(code,maxEnergyBoostRatio,bCanEnergyBoost)` 只有在比率大于 0、分支允许增益且代码不是特殊前缀时执行。它先把比率设为最大值；若棋盘能提供订单缺口图，就从 `i=0` 到最大比率检查同一链上更高等级：只要目标等级存在订单缺口，或在“已有数量减订单需求”后为奇数且仍在可升级范围，就把比率截断为当前 `i` 并停止。随后循环 `i=1..energyBoostRatio`，每次把代码替换为其 `MergedType`，所以一次点击最多沿合成链升级指定次数。服务端 `FishNetProduceSmart` 还可能针对生鱼链按二进制等级缺口替换为更合适的等级；该动态开关与实际命中标记为 `runtime-pending`。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页是该阶段的第四层证据节点；沿用食品袋 105 的同一组案例输入，只展示当前节点涉及的算法和状态变化。

### 代入本页的值

本页没有新增运行时输入；具体字段以本页正文的源码和配表为准。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
