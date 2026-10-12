# 连续状态写入

`_TriggerContiLuckyProduce` 写入 `clpit`（目标类型）、`clpmc`（最大次数）、`clpc=0`（当前次数），并把 `clpeet` 设置为服务器时间加 10 秒。

**源码**：`_TriggerContiLuckyProduce`。**状态**：`clpit`、`clpmc`、`clpc`、`clpeet`。期限使用服务器时间，不能用客户端本地时间替代。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例在一次 Lucky 产出后建立了连续资格，下一次点击同一食品袋时会优先消费这份资格。玩家会看到连续的 Lucky 结果；资格用完或超过有效时间后，点击恢复普通机会判断。

### 代入本页的值

假设服务器时间 `T=1000`，触发函数传入最大次数 `N=2`。写入 `clpit="105"`、`clpmc=2`、`clpc=0`、`clpeet=1010`；下一次同母体点击先验证 `1000<=1010`，通过后才允许连续消费。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- 连续 Lucky 服务器字段：_CalculateLuckyProduceConfigIndex 按 energy_cost.range_entry 选段；_Try2TriggerContiLuckyProduce 直接读取 triple_lucky_chance / double_lucky_chance。


<!-- generator-configs:end -->
