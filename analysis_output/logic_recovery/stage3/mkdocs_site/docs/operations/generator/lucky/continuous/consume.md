# 连续状态消费与失效

`_CanContiLuckyProduce` 要求目标类型相同、当前次数小于最大次数且服务器时间未超过 `clpeet`；任一条件不满足就清除四个连续字段。命中后递增 `clpc` 并把有效期重新延长 10 秒。

**源码**：`_CanContiLuckyProduce`、`_PostProcessOnContiLuckyProduce`、`_CLearContiLuckyProduceData`。对象类型变化、超时和次数用尽均属于不同失效原因，应在回放中分开验证。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例开始时没有连续资格，因此不会直接连续产出，而是继续走普通的机会判断。若上一次点击已经留下同一食品袋的连续资格，下一次点击会优先消耗它并直接生成连续奖励。

### 代入本页的值

假设连续状态为 `clpit="105"、clpmc=2、clpc=0、clpeet=1010`，服务器时间 1005。母体匹配且 `1005<=1010`，消费后 `clpc=1`、期限刷新为 1015；若时间为 1016，资格失效并清除整组状态。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [连续 Lucky 服务器字段](trigger.md#configuration-continuous-lucky)：_CalculateLuckyProduceConfigIndex 按 energy_cost.range_entry 选段；_Try2TriggerContiLuckyProduce 直接读取 triple_lucky_chance / double_lucky_chance。


<!-- generator-configs:end -->
