# 计数扣减与保存

普通 Lucky 命中时，`luckyLeftSpreadCount -= 1` 并保存；只要不是免费 Lucky，`totalLeftSpreadCount -= 1` 并保存。免费 Lucky 不走总机会扣减。

**结论**：下一次抽样使用已经改变的分母和配额，所以不能复刻为独立伯努利概率。**源码**：`Try2ProduceLuckyItem`、`_SetLuckyLeftSpreadCount`、`_SetTotalLeftSpreadCount`。证据 `source-confirmed`。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：A 没有命中 Lucky，所以只消耗普通机会，Lucky 配额留到下次；B 命中 Lucky，既消耗普通机会，也用掉本周期的一次 Lucky 配额。玩家能感受到的差别是 B 的奖励更特殊，且后续 Lucky 更难再次出现。

### 代入本页的值

A（免费未命中）把 `tl_105` 从 60 减为 59，`ll_105` 保持 1；B（Lucky 命中）把 `tl_105` 减为 59、`ll_105` 减为 0。于是 A 后下一次 Lucky 概率为 `1/59`，B 后本周期不再有 Lucky 配额。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- Lucky 包内配置及活动变体：LuckyProduceModel:_LoadFileConfig → _GetLevelFitConfig → Try2ProduceLuckyItem；按 generator、等级区间选择记录，再用 lucky_chance 重装机会池。


<!-- generator-configs:end -->
