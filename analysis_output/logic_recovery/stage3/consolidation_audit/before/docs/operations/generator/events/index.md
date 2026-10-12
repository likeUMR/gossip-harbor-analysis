# 事件与后续影响

事件不是另一套成功判定，而是把已经完成的状态变化通知给棋盘、活动、统计和界面。失败事件在对应闸门立即发送；落子事件在创建棋子之后发送，此时母体变换与销毁检查尚未执行；普通路径的次数状态通知则更早发生在产物计算期间。

**失败**：`_NotifySpreadFailed` 同时调用棋盘事件 `SpreadFailed`、全局 `EEventType.SpreadFailed` 和重震动 `VibrationHeavy`。

**成功**：`BaseBoardModel:SpreadItem` 生成新棋子并发送 `BoardEventType.SpreadItem`；`MainBoardModel:SpreadItem` 再派发 `EEventType.ItemSpread`、写 BI `LogSpread`，点击链随后发送 `VibrationLight`。

**状态持久化**：产出代码和次数处理过程中会调用 `SaveItemProperty`；变换走 `ItemTransform:Transform`，一次性耗尽走 `RemoveItem` 和 `BoardEventType.CollapseItem`。具体监听对象和异步网络上传仍按证据等级标记。

按触发点继续阅读：[扣能量时的资源事件](resource/index.md)、[落子与棋盘事件](board/index.md)、[活动与日志字段](side_effects/index.md)。


---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页是该阶段的第四层证据节点；沿用食品袋 105 的同一组案例输入，只展示当前节点涉及的算法和状态变化。

### 代入本页的值

本页没有新增运行时输入；具体字段以本页正文的源码和配表为准。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
