# Decremental 的具体选择

`m_weightType==Decremental` 时调用 `Table.ListWeightSelectOne(m_codeWeightPairs)`，按当前 `Weight` 总和在累计区间中取一个整数；抽中后立即 `Weight -= 1`，减到 0 就 `table.remove`，并保存母体属性。因此候选池会在每次成功生成代码时变化，等价于按权重展开后的无放回逐份消费；它与 Lucky 机会池是两个独立状态。自动缓存时，`GetAutoSpreadDecrementalRemainTypes` 会把每条剩余权重展开成代码列表。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明递减池抽中候选后如何降低其后续出现机会，直到候选被移除。

### 代入本页的值

假设 `m_weightType=2`、递减规则为每次命中后权重减 1。候选 201 初始权重 5，第一次命中后变为 4；若类型为 1，则不进入递减逻辑，权重仍为 5。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->
