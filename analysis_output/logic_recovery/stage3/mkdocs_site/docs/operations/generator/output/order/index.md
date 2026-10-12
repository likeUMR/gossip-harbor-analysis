# OrderItem

用 `CalculateOrderCodeLackNumMap(false,true,false)` 得到订单缺口；候选权重为 `min(DiffScore,300)`，OrderBoost 缺口再乘 1000。尝试后删除候选，再尝试同链低等级输出，最后回退到已解锁且生成器有效的候选。

**配表**：`OrderItemConfig.DiffScore`、`Spread_StorageMaxNumber`；当前 74 行，DiffScore 2–3000。**语义**：候选显式移除，属于不放回。**源码**：`ItemSpread` OrderItem 分支、`MainOrderModel` 缺口计算。OrderBoost 激活 `runtime-pending`。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例不根据订单生成候选，不执行订单产出算法。

### 代入本页的值

`m_weightType=1`，与 `OrderItem=3` 不相等；订单难度分值不参与本次 Fixed 原始池抽样。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
