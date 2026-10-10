# Lucky、Disco 与产出改写

`GenerateItemCode` 的入口优先检查 Lucky；Lucky 成功就直接返回 Lucky 代码。未命中时，如果 Disco 支持当前母体，先尝试直接提供 Disco 代码；没有直接代码时仍标记 Disco 场景并把最大能量增益档提升到 3。普通产出生成后，`DealActivityLimit` 还可以再次由 Disco 改写代码和增益倍率，并把本次 `costCount` 改为 0。

这解释了为什么同一个母体在不同活动状态下可能出现不同代码、不同扣费和不同 BI 产出类型。

**源码**：`CheckLuckyProduce`、`TryGenerateLuckyItem`、`TryGenerateDiscoItem`、`DealActivityLimit`、`GenerateItemCode`。Lucky 的机会池和物品池见左侧 Lucky 分支；本页只说明它们在普通产出入口的执行优先级。

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
