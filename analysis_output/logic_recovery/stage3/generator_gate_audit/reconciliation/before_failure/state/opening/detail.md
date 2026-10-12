# 开启中状态的具体判定

`OnOpen` 写入 `m_state=Opening`，`UpdatePerSecond` 为 `m_startTimer` 记录服务器时间并发送 `StateChanged`。计时未完成时，`CheckSpreadState` 命中 Opening，发送 `ItemOpening` 失败链并停止；到期由 `_UpdateRecoveryState` 将状态改为 Opened、清空 `m_startTimer`、派发 `ItemOpened` 和 `UpdateOpeningItem`。`GetSpeedUpCost` 在此阶段使用 `m_openSpeedUpCost`，不是恢复时长费用。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明开启中状态如何拦截点击：玩家等待开启完成，本次没有产物和能量消耗。

### 代入本页的值

假设 `m_state=2 (Opening)`。`2==Opening` 成立，发送 `ItemOpening` 并返回 false；状态改为 3 后该分支不再执行。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- 母体配置与包内变体：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->
