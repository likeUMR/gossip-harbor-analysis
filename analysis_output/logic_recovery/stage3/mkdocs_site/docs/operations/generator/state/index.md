# 状态检查

状态检查是 `OnTap → _TrySpread` 的第一道闸门。代码按固定顺序读取同一个 `ItemSpread` 实例：先处理明确的关闭/开启状态，再处理初始化或次数耗尽，只有全部通过才允许寻找落点。

## 实际执行顺序

1. `Closed`：派发 `SpreadFailed(ItemClosed)`，立即结束。
2. `Opening`：派发 `SpreadFailed(ItemOpening)`，立即结束。
3. `Initializing`，或 `m_itemRestNumber == 0`：可恢复母体派发 `SpreadFailed(ItemRecharging)`；一次性母体在这两种情况下都静默返回 false。本次失败不会删除它；正常产出后的删除由后面的销毁判断处理。
4. 其它情况视为 `Opened`，进入空位检查。

这里的“状态”不是独立布尔值：`m_state` 与 `m_itemRestNumber`、`m_startTimer` 共同决定点击结果。`UpdatePerSecond` 依据服务器时间把 Initializing/Opening 推进到 Opened，或把可恢复母体的次数补回；它不会改变本次点击的检查顺序。

左侧每个状态页继续说明进入条件、计时字段、失败事件和边界行为；底层页给出对应源码分支。

**源码入口**：`ItemSpread:CheckSpreadState`、`ItemSpread:UpdatePerSecond`、`ItemSpread:_UpdateRecoveryState`。**证据**：分支顺序 `source-confirmed`；实际账号计时、活动覆盖和前后台回放 `runtime-pending`。

失败发生在本阶段时立即通知棋盘、全局监听和震动，见失败事件。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例按状态检查顺序通过：食品袋不是关闭状态，也不在开启中或初始化中，且仍有可用次数。因此点击继续进入空位检查；玩家看到的是一次正常产出，而不是“正在开启”或“暂不可用”的提示。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>
