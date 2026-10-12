# 可产出状态的具体判定

`CheckSpreadState` 没有显式的 `Opened` 分支；只要不是 Closed/Opening/Initializing，且 `m_itemRestNumber` 不为 0，就返回 true。可恢复母体在次数耗尽时走同一个 `ItemRecharging` 分支；一次性母体耗尽则不发 Recharging，等待成功落子后的 `TryRemoveSelf` 删除。`GetTimerDuration` 在 Opened 状态根据 `m_storageRestNumber == 0` 选择储备恢复时长或单轮恢复时长。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明已打开状态如何放行点击：状态检查通过后进入落点查找，随后才可能生成物品。

### 代入本页的值

假设 `CheckSpreadState()` 读取到 `m_state=3`，与 `Opened` 相等，返回 true；这一步只是枚举比较，不产生随机数，也不改变次数。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- 母体配置与包内变体：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->
