# Closed：关闭

只有配置了开启时长的母体可能以 Closed 初始。点击直接返回 `ItemClosed`，不进入空位和能量检查。

**字段/配表**：`Spread_OpenDuration`、开启状态字段。**源码**：`CheckSpreadState`。不同母体活动的初始状态覆盖 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例假设食品袋 105 处于关闭状态，因此点击会被拦截并显示关闭反馈；棋盘不会增加物品，能量和次数都保持不变。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>
