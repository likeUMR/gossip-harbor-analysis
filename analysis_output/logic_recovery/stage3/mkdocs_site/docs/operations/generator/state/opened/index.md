# Opened：可产出

初始化或开启计时完成后，母体进入 Opened，才允许继续检查棋盘空位和能量。若剩余产出数不足，后续会启动 `m_itemRecoveryDuration` 或 `m_storageRecoveryDuration` 的恢复逻辑。

**字段**：`m_itemRestNumber`、`m_storageRestNumber`、恢复时长字段。**源码**：`UpdatePerSecond`、恢复处理。恢复补充的精确时机和服务器时间漂移属于 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：前面的状态检查都通过，食品袋被视为已打开且可操作，于是继续寻找落点。玩家接下来会看到物品被放到棋盘空位；这一步本身不产生随机奖励，也不扣资源。

### 代入本页的值

`CheckSpreadState()` 返回 true；这里不是另一次随机抽样。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>
