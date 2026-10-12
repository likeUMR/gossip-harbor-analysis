# 开启、加速和时间跳过的具体结算

`OnOpen` 只写入 `m_state=Opening`，随后由 `UpdatePerSecond` 决定是否建立 `m_startTimer`；它还发送 `ItemOpening` 并调用 `UpdateOpeningItem`。`_SpeedUp(false)` 先读取 `GetSpeedUpCost` 和宝石余额，不足时发 `BoardEventType.LackGem`（场景 `TimeSkip`）并立即返回；足够时调用 `PropertyDataManager:Consume(Gem,cost,SpeedUp,sourceCode)`。免费路径跳过宝石扣除。两条路径最后都调用 `OnTimeSkip`：没有显式 duration 时先把起点重置为当前服务器时间，再减去整个阶段时长，保存属性、播放音效、重新 `UpdatePerSecond`，并按 `Gem`/`ad`/`Buff` 写加速 BI。`TryUseCDBuff` 只有在支持 CD Buff、GeneratorBoost CD Buff 或测试免费开关之一成立，且 `m_itemRestNumber==0` 时才调用同一时间跳过；`OnTimeSkipInZeroRestNumber` 还要求对象是生成器、使用能量且属于主棋盘。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明等待时间达到边界后，母体如何从等待转为可产出或关闭，玩家何时可以再次点击。

### 代入本页的值

假设服务器时间 1000、开启时间 940、开放时长 120。计算 `1000-940=60<120`，仍在开放窗口；到 1061 时为 121，窗口结束并转入关闭处理。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- 母体配置与包内变体：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->
