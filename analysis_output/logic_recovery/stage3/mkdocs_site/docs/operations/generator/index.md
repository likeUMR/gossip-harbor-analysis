# 母体点击

入口：`ItemSpread:OnTap`。一次点击不是“直接生成一个棋子”，而是按下面的顺序逐关检查；前置检查失败时，后面的阶段不会执行。

| 顺序 | 检查/处理 | 不满足时的结果 | 通过后进入 |
|---|---|---|---|
| 1 | 状态检查 | Recharging / ItemClosed / ItemOpening | 空位检查 |
| 2 | 空位检查 | BoardFull；不扣能量、不改次数 | 能量检查 |
| 3 | 能量检查 | LackEnergy；不产出 | 产出代码计算 |
| 4 | Lucky 判断 | 未命中则进入普通产出 | Lucky 物品或普通产出 |
| 5 | 未命中 Lucky 后，尝试活动直接产出；否则进入普通产出 | 普通路径依次执行上限修正、候选选择、链升级、活动改写、次数扣除和计时更新；Lucky / Disco 直接产出提前返回 | 实际能量扣除 |
| 6 | 扣能量、记录增益、最终落点与落子 | 落子派发棋盘和全局事件，并记录日志 | 母体收尾 |
| 7 | 变换与销毁 | 变换或一次性耗尽时结束；否则继续 | CD Buff 检查 |
| 8 | 尝试 CD Buff | 冷却恢复另由计时更新推进，不是每次点击都恢复 | 本次点击结束 |

本页只解释整条判断链；左侧子节点分别解释每个阶段。产出计算内部再分为 Lucky 判断和五种普通产出模式，不能概括成一个随机函数。

**源码证据**：[Board_Model_Item_ItemSpread.lua](/C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua)。入口及主调用顺序为 `source-confirmed`；服务端开关和动态对象身份为 `runtime-pending`。

## 如何阅读分支与后续影响

活动改写属于产出计算内部，事件与存档则在各个执行点发生。相关说明在对应阶段提供链接，不额外增加执行步骤：

- [Lucky 判断](lucky/index.md)：说明活动资格与优先级。
- [普通产出](output/index.md)：按顺序说明上限修正、候选选择、升级、活动改写与次数处理。
- [能量扣除](energy/consume/index.md)：同时说明资源通知。
- [次数、变换与销毁](lifecycle/count/index.md)：同时说明状态保存和落子后的收尾。

正常点击执行一次；测试十连和点击结束后的系统通知属于入口附加分支，见[点击入口与通知](entry/index.md)。跨阶段查阅可使用[事件与监听链](events/index.md)，其中每条事件均应以实际触发位置理解。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../assets/cases/generator.png" alt="母体点击的产出分支" class="case-composite" style="display:block;max-width:560px;width:100%;height:auto;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：玩家点击食品袋 105。先确认母体能点击、棋盘有空位、能量足够；随后本例的 Lucky 条件命中，额外放置 1 个 Lucky 物品 204，并扣除 1 点能量。因为 Lucky 分支已经产出，普通物品池和普通次数扣除不再处理。

A 产出 201（低阶面粉），B 产出 204（高阶面粉）；两个分支分别从同一初始状态演示，不能当作连续两次点击。母体 104 是低级对照：基础 Lucky 配置没有包含它。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
