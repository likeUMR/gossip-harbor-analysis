# 次数与储备上限修正

`SafeSpreadItem` 在 `_GenerateItemCode` 前执行。若 `m_itemRestNumber > m_itemMaxNumber`，记录 `{rest,max}` 的 `ItemRestNumberOverflowError` 后截回最大值；若储备存在且 `m_storageRestNumber > m_storageMaxNumber`，同样记录 `StorageRestNumberOverflowError` 并截回。它不改变 `m_spreadCount` 或权重。自动缓存的另一条路径随后调用 `EmptySpreadCount`：次数、储备都置零，Decremental 的 `m_codeWeightPairs` 置为空表，更新计时、派发 `StateChanged` 并保存属性。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明安全下限如何阻止会造成负资源的点击，并保留玩家当前状态。

### 代入本页的值

假设安全阈值为 0、当前能量为 0、计算扣能量为 1。`0-1<0`，安全检查失败并阻止产出；当当前能量为 1 时，`1-1=0`，检查通过并扣至 0。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->
