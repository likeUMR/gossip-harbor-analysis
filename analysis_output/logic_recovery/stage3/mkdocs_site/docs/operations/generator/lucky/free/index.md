# 免费 Lucky

免费 Lucky 是机会判定未命中后的第二条资格路径。它不重新抽 `lucky_items`，而是检查能量消耗计数是否达到预先生成的阈值；达到后把本次改成 Lucky，并消费一个阈值。

- 阈值队列生成
- 阈值检查与消费
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例假设普通机会没有命中，但免费阈值队列中有 1 项已达到，因此免费资格检查命中并生成 1 个 Lucky 物品；另一个独立分支假设普通机会先命中，此时直接领取 Lucky 物品，不再重复检查免费资格。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>
