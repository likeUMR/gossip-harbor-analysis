# 棋子创建、订单刷新和落子事件的先后

## 1. 创建与保存先于通知

BaseBoardModel SpreadItem调用GenerateItem；它先由ItemModelFactory.CreateWithCode创建棋子（默认允许解锁类型），SaveItemProperty保存，再在位置非nil时_SetItem写入格子。主棋盘的_SetItem调用基类写入之后，除非autoUpdateOrderState显式false，才CountItemsCode、UpdateOrderState；订单状态刷新因此先于落子通知。

GenerateItem返回新模型后构造消息：Source母体、New新棋子、EnergyBoostRatio（nil默认0）、CostEnergy、BoardSpreadType。先发送棋盘局部BoardEventType.SpreadItem；MainBoardModel再派发全局EEventType.ItemSpread。监听回调可在这个同步通知中继续产出追加棋子。

## 2. 通知完成后才写本次日志

MainBoardModel在全局通知之后处理日志。普通双倍来源GeneratorBoostExtraNormal归一为Normal，智能双倍来源GeneratorBoostExtraSmart归一为GeneratorBoostSmart；事件消息此前已经保留双倍类型，所以活动能据它复制，日志则区分另一口径。Disco日志类型再查当前仍有效的Disco属性；若本次用完助力并关闭，查到的属性值可为0。

eb是本次指数、md是能量增益类型、st为日志来源、oriEle为返回的原始代码、sc为特殊场景；支持GeneratorBoost且有效Buff字符串非空时追加ab。之后LogSpread、_TryLogBoardFull。手动点击回到ItemSpread才发VibrationLight，并检查变换/销毁/CD Buff。

## 3. 空位与失败边界

上述SpreadItem没有“AddItem返回false就停止BoardChanged”的分支；文档不能自行补这样一条事务保障。空位前置检查和最终落点在点击链，创建/格层写入的异常或断言要继续追ItemModelFactory及ItemLayerModel。当前方法同样不把已扣能量、次数和保存自动回滚。

**证据**：BaseBoardModel GenerateItem / SpreadItem；MainBoardModel _SetItem / SpreadItem；ItemSpread _TrySpread。完整事件消费者须逐个按其注册条件理解，不能把通知顺序理解成所有活动都无条件生效。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：食品袋105普通A产201后，先保存新棋子并写目标格、刷新订单状态，再通知棋盘和全局监听；本例无追加Buff。

### 代入本页的值

A输入位置P、代码201、指数0、CostEnergy=true、来源Normal。GenerateItem创建201并保存，_SetItem写P后CountItemsCode/UpdateOrderState；消息Source=105模型、New=201模型、EnergyBoostRatio=0、CostEnergy=true、BoardSpreadType=Normal。局部SpreadItem→全局ItemSpread→本次日志→满盘统计→返回点击链VibrationLight。源码没有案例旧说法中的AddItem失败返回或BoardChanged条件。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- source-links:start -->

## 对应源码

[BaseBoardModel.lua](../../../../assets/recovered-source/BaseBoardModel.lua) · [MainBoardModel.lua](../../../../assets/recovered-source/MainBoardModel.lua) · [ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua)

<!-- source-links:end -->
