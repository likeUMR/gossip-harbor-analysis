# SmartItem

收集订单棋子候选，数量上限由 `Spread_StorageMaxNumber` 控制，调用 `SmartRewardHelper.GetCodesFor_ItemSpread`；消耗选中代码的 `DiffScore`，缺失时使用 1。

**配表**：`Spread_StorageMaxNumber`、订单候选和 `DiffScore`；当前 5 行。**源码**：`ItemSpread` SmartItem、`SmartRewardHelper`。FishNetProduceSmart `runtime-pending`。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例不是 SmartItem 母体。

### 代入本页的值

`m_weightType=1`，与 `SmartItem=5` 不相等。本分派与 Lucky 的 Smart 权重修正是两个不同入口。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
