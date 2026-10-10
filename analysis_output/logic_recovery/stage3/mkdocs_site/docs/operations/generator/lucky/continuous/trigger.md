# 三连/二连触发判断

当前特殊模式配置存在时，先以 `Random(1,10000)` 判断三连；三连未命中才以同范围随机判断二连。三连写入最大连续次数 2，二连写入最大连续次数 1。

**配置**：`triple_lucky_chance`、`double_lucky_chance`。**源码**：`_Try2TriggerContiLuckyProduce`。两个判断不是并列独立同时执行，而是二连只在三连失败后执行。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例使用基础配置，没有断言本次触发二连或三连。

### 代入本页的值

基础 105 行确认的是 `lucky_chance` 和物品池；没有能量区间的实际配置快照，不能填写二连/三连概率。B 调用 `_Try2TriggerContiLuckyProduce("105")`，是否写入连续状态取决于实际配置。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
