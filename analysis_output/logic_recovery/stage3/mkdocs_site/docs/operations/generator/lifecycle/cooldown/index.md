# CD、加速与恢复

CD 使用服务器时间字段 `m_startTimer`。加速费用按剩余时长比例向上取整，最低 1 宝石；恢复分支补回 `m_itemRestNumber` 并减少 `m_storageRestNumber`。

**字段/配表**：`m_startTimer`、`m_itemRecoveryDuration`、`m_storageRecoveryDuration`、`Spread_ItemRecoveryDuration`、`Spread_StorageRecoveryDuration`。**源码**：`UpdatePerSecond`、CD Buff 处理。Buff 叠加顺序和离线补时 `runtime-pending`。

点击结束后的系统通知见入口与通知分支，它不改变冷却计时。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：一次点击使食品袋次数未满，就开始恢复计时；只要仍有次数，玩家可以继续点击，并非计时开始就全部禁用。下面的耗尽场景才会暂时无法产出，恢复到期后重新获得一轮次数，同时扣除储备。

### 代入本页的值

A 演示 `serverTime=T`、`m_startTimer=nil`：扣次至 79 后 UpdatePerSecond 写 `m_startTimer=T`。配置 105 的物品恢复 30 秒、储备恢复 60 秒；物品恢复时 79→80，储备 240→239。实际 tick 时间需回放。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>
