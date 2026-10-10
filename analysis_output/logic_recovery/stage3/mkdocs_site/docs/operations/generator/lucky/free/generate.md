# 阈值队列生成

特殊模式按能量区间配置生成阈值。每个区间调用 `MathUtil.RandomN(rangeSize, min(rangeSize, extra_lucky))`，得到互不重复的位置，排序后加上区间起点并追加到 `elpec` 队列。

**状态**：`elpec`、能量区间索引。**配置**：`energy_cost.range_entry`、`extra_lucky`。**源码**：`_AddFreeLuckyProduceEnergyCostCount`。`RandomN` 不放回位置语义 `source-confirmed`。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例沿用已存在的阈值状态；本次资格判断不重新生成阈值队列。

### 代入本页的值

演示 `_CanFreeLuckyProduce()` 为 false；没有采集本例账号的 `energy_cost`/`extra_lucky` 生效值，故不编造 `elpec` 阈值数字。阈值生成需单独记录 PropertyConsumed 回调及能量区间。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
