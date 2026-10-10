# 一次性母体落点

一次性只描述母体的生命周期，不等于“每次点击都随机落点”。玩家手动点击时，`_TrySpread → CheckSpreadPosAndAuto` 调用 `FindEmptyPositionInSpreadOrder`，以母体为中心按方形环扫描并取第一个空位；只有 `Spread_Auto==1` 的自动产出才会经过 `FindSpreadPosition → FindRandomPosition`，从全盘空位中抽取。

本页的配置级例子是 `main_t_chest_new_1`：没有 `Spread_ItemRecoveryDuration`，所以 `IsDisposable()==true`；开启时长 120 秒、可产出 7 次、储备 7 次，Decremental 权重为 `2401-2 / 2402-2 / 2501-2 / 2502-1`。这些字段决定状态和次数，不改变手动方形环扫描。

手动入口找不到空格会立即发送 `SpreadFailed(BoardFull)`。自动入口找不到空格时，只有一次性、Decremental、存在缓存函数且 `AutoSpreadToCache` 服务端开关开启，才会把剩余代码放入缓存；否则自动循环停止。Lucky、产出代码和能量扣除属于后续页面。

**源码**：`ItemSpread:_TrySpread`、`CheckSpreadPosAndAuto`、`_TryAutoSpread`、`MainBoardModel:FindSpreadPosition`、`BaseItemLayerModel:FindEmptyPositionInSpreadOrder`、`FindRandomPosition`。**证据**：入口分流、配置读取和候选构造为 `source-confirmed`；服务端自动缓存开关、账号棋盘和随机种子为 `runtime-pending`。

---

## 贯穿案例：打开一次性测试宝箱 main_t_chest_new_1

<div class="case-assets"><img src="../../../../../assets/cases/item-main_t_chest_new_1.png" alt="一次性测试宝箱 main_t_chest_new_1" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：观察一次性母体在开启、落点、Decremental 权重和耗尽销毁之间的完整链路。

**本页发生什么**：本页使用一次性测试宝箱 `main_t_chest_new_1` 作为独立案例。它没有 `Spread_ItemRecoveryDuration`，因此 `IsDisposable()` 为 true；手动点击仍先按母体周围的方形环找空位，自动路径才会使用全盘随机空位。

### 代入本页的值

`Spread_OpenDuration=120`、`Spread_ItemMaxNumber=7`、`Spread_StorageMaxNumber=7`、`Spread_WeightType=2`、权重 `2401-2/2402-2/2501-2/2502-1`；未配置物品恢复时长。

<details><summary>本案例共同前提</summary>

本地配表确认：`main_t_chest_new_1` 的开启时长 120 秒、可产出 7 次、储备 7 次，`Spread_WeightType=2`，权重为 `2401-2 / 2402-2 / 2501-2 / 2502-1`；没有 `Spread_ItemRecoveryDuration`，因此是一次性母体。素材为原版 Sprite 图标加说明性排布，不是运行时截图。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
