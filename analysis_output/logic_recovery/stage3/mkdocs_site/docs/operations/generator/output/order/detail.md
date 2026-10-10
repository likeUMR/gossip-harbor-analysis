# OrderItem 的具体选择

`GetOrderItemCode` 先取当前订单缺口 `CalculateOrderCodeLackNumMap(false,true,false)`，读取订单加成缺口和 `OrderItemConfig.DiffScore`。每个缺口代码权重为 `min(DiffScore,300)`，处于 OrderBoost 的代码再乘 1000。先加权选一个目标订单代码并从候选表移除，再在 `m_codeWeightPairs` 中筛同链且等级低于该目标的代码，用 `ListRandomSelectOne` 均匀选具体产物；失败时尝试其它订单代码，最后回退到所有已解锁母体链。`CosetRestNumber` 对 OrderItem 使用选中配置项的 `Weight` 作为消耗次数。

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
