# Fixed

Fixed 不是一次点击固定一个代码，而是把母体类型（或 ItemStateCollection 状态）交给 `ItemFixedSpreadModel` 的固定池模型。`_GenerateItemCode` 先检查 GeneratorBoost SmartProduce 和 Smart Buff；智能产出有结果时优先采用，否则才进入固定池。固定池的候选不会因点击从 `m_codeWeightPairs` 删除，和 Decremental 的可变池不同。

**配表**：`Spread_WeightType=1`；食品袋 105 的普通池为 `201×35、202×2、301×5`。**源码**：`ItemSpread:_GenerateItemCode`、`_FixedGenerateItemCode`、`ItemFixedSpreadModel:GenerateItemCode`。活动对象和实际 SmartProduce 命中标记 `runtime-pending`。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-201.png" alt="普通产物 201" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：A 选中低阶面粉 201，同样的低阶物品可以连续出现。

### 代入本页的值

`Spread_WeightType=1`；候选 `201:35,202:2,301:5`，总权重 42。演示累计抽样点 20 落在首项；原始池不删除候选，下次仍是 35/42、2/42、5/42。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
