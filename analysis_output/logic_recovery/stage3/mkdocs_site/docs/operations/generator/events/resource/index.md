# 资源与属性事件

成功扣能量通过 `PropertyDataManager:Consume` 进入 `PropertyConsumed` 链，Lucky 和 Boost 模型可监听并更新统计。源码为 `SpreadCostEnergy`、`LuckyProduceModel:_OnPropertyConsumed`。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。

具体调用、参数与时序见[资源事件底层说明](detail.md)。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例成功点击后，能量和可用次数都更新：玩家的能量少 1 点，母体可用次数少 1 次。余额不足时，这两项都保持原值。

### 代入本页的值

假设本次扣除能量 1、次数 1。资源事件按 `energy:10→9`、`spreadCount:0→1` 的顺序记录；若能量不足，`energy` 保持 0，资源事件和产出事件都不发送。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
