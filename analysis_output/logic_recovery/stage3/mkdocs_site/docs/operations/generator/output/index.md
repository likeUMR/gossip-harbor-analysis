# 普通产出

Lucky 未命中（或 Lucky 活动不适用）后，`GenerateItemCode` 才进入普通产出。它先保存当前状态并调用 `_GenerateItemCode` 按 `Spread_WeightType` 分派；拿到原始代码后，再经过能量增益升级、活动改写、次数扣除和保存。也就是说，下面的五类页面解释的是“原始代码如何选”，不是最终落子代码的全部来源。

统一顺序是：

1. 教程强制代码（有值时直接返回）。
2. 按 `Fixed / Decremental / OrderItem / ChestCustomItem / SmartItem` 选择原始代码。
3. `SpreadCheckEnergyRatioAndCode` 根据订单缺口、棋盘已有数量和链等级决定能量增益次数，并沿 `MergedType` 链升级代码。
4. Disco 等活动执行 `DealActivityLimit`，可能改写代码并把次数消耗设为 0。
5. `CosetRestNumber` 扣母体次数，`UpdatePerSecond`、事件和存档随后执行。

分支页面：

- [Fixed](fixed/index.md)
- [Decremental](decremental/index.md)
- [OrderItem](order/index.md)
- [ChestCustomItem](chest/index.md)
- [SmartItem](smart/index.md)

能量升级、Lucky 产物和活动改写都可能使“原始候选”和“最终代码”不同；实现复刻时必须按上述顺序串接，不能只复刻五个候选池。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：A 没有 Lucky 资格，按食品袋的 Fixed 配置产出；B 已走 Lucky，跳过普通分派。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
