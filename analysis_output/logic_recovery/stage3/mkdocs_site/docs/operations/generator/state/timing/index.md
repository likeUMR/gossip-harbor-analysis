# 开启、加速与时间跳过

这组流程处理母体从关闭到可产出的等待，以及玩家用宝石、广告或活动 Buff 跳过等待的行为。它不生成棋子；它只改变 `m_startTimer`，再让统一的 `UpdatePerSecond` 重新结算状态。

## 执行顺序

1. `OnOpen` 把状态置为 `Opening`，立即调用 `UpdatePerSecond`，并通知棋盘当前有正在开启的母体。
2. 玩家点击加速时进入 `OnSpeedUp → _SpeedUp`。非免费加速先读取 `GetSpeedUpCost`，再检查宝石余额；不足只发送 `LackGem`，不改计时。
3. 宝石扣除或免费资格通过后，`OnTimeSkip` 把 `m_startTimer` 向服务器时间方向提前，并保存母体属性。
4. `UpdatePerSecond` 重新计算进度；进度达到 1 时由 `_UpdateRecoveryState` 转为 `Opened` 或补回恢复次数。
5. 点击链成功消耗完可恢复母体次数后，`TryUseCDBuff` 可能用 CD Buff、GeneratorBoost CD Buff 或测试免费开关再次跳过等待。

左侧的具体页给出费用、时间字段、事件和每个分支的精确副作用。

**源码**：`ItemSpread:OnOpen`、`OnSpeedUp`、`_SpeedUp`、`OnTimeSkip`、`TryUseCDBuff`、`OnTimeSkipInZeroRestNumber`。动态广告和活动对象身份标记为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例的开启等待尚未超过设定时长，食品袋仍处于可继续等待或产出的时间窗口，玩家在窗口内点击可以继续流程；超过时长后，母体转入关闭或恢复处理，点击会被拦截，直到重新打开。

### 代入本页的值

假设服务器时间 1000、开启时间 940、开放时长 120。计算 1000-940=60<120，状态仍是开放并允许产出；时间到 1061 时差值为 121，状态切换为关闭，点击返回 false。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
