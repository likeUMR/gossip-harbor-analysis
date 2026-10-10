# 初始化字段、进度公式和恢复重置

`Init` 先深拷贝 `Spread_Weight`，再把次数和储备初始化为各自最大值。`Spread_InitDuration` 非空时状态为 `Initializing` 并立即 `UpdatePerSecond`；否则 `Spread_OpenDuration` 非空时状态为 `Closed`；否则直接 `Opened`。教程强制时长只对原本存在的 init/open/item-recovery/storage-recovery 字段替换。计时进度由 `elapsed = serverTime - m_startTimer`、`amount=min(elapsed/duration,1)` 得到；没有 duration 时记录完整字段诊断并把起点清空，duration 为 0 直接视为完成。`GetTimerDuration` 在 Initializing/Opening 读取对应阶段时长，在 Opened 依据 `m_storageRestNumber==0` 选择储备恢复或单轮恢复。完成后 `_UpdateRecoveryState` 要么转为 Opened，要么补满次数并扣除储备；储备耗尽时把起点推进一个 item recovery duration 再递归重算。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页是该阶段的第四层证据节点；沿用食品袋 105 的同一组案例输入，只展示当前节点涉及的算法和状态变化。

### 代入本页的值

本页没有新增运行时输入；具体字段以本页正文的源码和配表为准。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
