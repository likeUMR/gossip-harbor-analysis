# 数值安全修正

`SafeSpreadItem` 在真正生成代码前检查两组持久化数值：`m_itemRestNumber` 不能大于 `m_itemMaxNumber`，`m_storageRestNumber` 不能大于 `m_storageMaxNumber`。超过上限时先记录对应 BI 错误，再把数值截回上限；它不会补次数，也不会改变权重池。

自动缓存完成后调用 `EmptySpreadCount`，把剩余次数和储备同时置零；Decremental 母体还会清空 `m_codeWeightPairs`。因此“异常上限修正”和“正常耗尽清空”是两个不同阶段。

**源码**：`SafeSpreadItem`、`EmptySpreadCount`。**字段**：`m_itemRestNumber`、`m_itemMaxNumber`、`m_storageRestNumber`、`m_storageMaxNumber`、`m_codeWeightPairs`。

具体上限、日志与清空字段见[次数与储备底层修正](detail.md)。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例扣除后仍不低于安全下限，因此点击成功；若扣除会让能量低于下限，玩家会看到资源不足反馈，产出和状态都保持不变。

### 代入本页的值

假设安全下限为 0、当前能量为 1、扣除量为 1。计算 `1-1=0`，满足 `>=0`，安全检查通过，点击继续并把能量扣到 0；本例因此演示了安全边界允许刚好扣空的情况。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
