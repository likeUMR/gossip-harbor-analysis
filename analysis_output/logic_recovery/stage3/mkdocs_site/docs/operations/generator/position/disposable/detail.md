# 一次性落点的具体算法

### 1. 手动点击：确定性的方形环扫描

`_TrySpread` 先通过 `CheckSpreadPosAndAuto` 取落点。一次性母体通常 `Spread_Auto != 1`，因此直接调用 `FindEmptyPositionInSpreadOrder(centerPosition)`。底层实现先令 `currentPosition=centerPosition`，令 `maxTiles=max(HorizontalTiles,VerticalTiles)`；对 `i=1..maxTiles-1`，先把当前位置移到左下角方向的 `(-1,-1)`，形成边长 `2*i` 的方形环，再按 `dir=1..4`、每个方向走 `2*i` 格。每到一格先调用 `PositionIsValid`，再调用 `GetItem==nil`；第一个合法空格立即返回。扫描完所有环后返回传入的 `openedPosition`，本次调用没有传该参数所以结果为 nil。

这意味着手动一次性母体不是随机选位置：同一棋盘占用状态和同一母体坐标下，返回位置完全由扫描顺序决定。

### 2. 自动产出：随机空位与自动循环

`Update` 对 `Spread_Auto==1` 的母体反复调用 `_TryAutoSpread`。该函数先检查 `m_itemRestNumber != 0` 且 `m_state == Opened`，再通过 `_GetAutoSpreadPosition → MainBoardModel:FindSpreadPosition` 选位置。`FindSpreadPosition` 对 `IsDisposable()` 为真时调用 `FindRandomPosition`；可恢复母体则调用八邻域 `FindEmptyPositionInCircleOrder`。位置成功后才生成代码并写入棋盘，循环继续直到无次数、无位置或触发变换。

### 3. `FindRandomPosition` 的每一次抽样

`BaseItemLayerModel:FindRandomPosition` 每次调用都新建 `positions` 临时数组，从 `GetValidPositionIterator()` 的有效位置迭代器开始。迭代器从 `(1,1)` 逐格走：x 递增，x 超过棋盘宽度时换到下一 y；每格读取 `GetItem`，只把空格插入数组。空数组交给 `Table.ListRandomSelectOne` 返回 nil；非空数组由 `MathUtil.Random(#positions)` 生成 1 到候选数的整数下标并返回该项。它没有保存“已抽过的位置”集合，也没有在抽样后从棋盘写入前修改候选数组；下一次调用重新扫描当前棋盘。因此它是“每次基于当前空位集合的独立均匀抽样”，从概率语义上属于有放回抽样；真正落子后该格才会从下一次候选集合消失。

### 4. 满盘、缓存与最终写入

手动扫描返回 nil 时，`CheckSpreadPosAndAuto` 立即调用 `_NotifySpreadFailed(BoardFull)`；该函数同时发 `BoardEventType.SpreadFailed`、`EEventType.SpreadFailed` 和 `VibrationHeavy`，随后 `_TrySpread` 返回，能量、产出代码、扣除次数、落子均不执行。自动路径无位置时，若 `IsDisposable()`、`m_weightType==Decremental`、`CacheItemFromSpread` 方法存在且 `AutoSpreadToCache` 服务端开关开启，则把 `GetAutoSpreadDecrementalRemainTypes()` 展开的剩余代码列表写入缓存，递增 `m_spreadCount`，调用 `EmptySpreadCount` 清空次数和 Decremental 权重，并通过缓存事件通知；否则 `_TryAutoSpread` 返回 false。

**源码证据**：`ItemSpread:_TrySpread`（约 896 行）、`CheckSpreadPosAndAuto`（847 行）、`_TryAutoSpread`（798 行）、`MainBoardModel:FindSpreadPosition`（230 行）、`BaseItemLayerModel:FindEmptyPositionInSpreadOrder`（解码源码 25-38 行）、`FindRandomPosition`（解码源码 99-108 行）、`Table.ListRandomSelectOne`（解码源码 95-100 行）。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。

---

## 贯穿案例：打开一次性测试宝箱 main_t_chest_new_1

<div class="case-assets"><img src="../../../../../assets/cases/item-main_t_chest_new_1.png" alt="一次性测试宝箱 main_t_chest_new_1" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：观察一次性母体在开启、落点、Decremental 权重和耗尽销毁之间的完整链路。

**本页发生什么**：本页继续使用一次性测试宝箱 `main_t_chest_new_1`，把同一输入代入方形环扫描、自动随机和缓存分支的底层算法。

### 代入本页的值

`Spread_OpenDuration=120`、`Spread_ItemMaxNumber=7`、`Spread_StorageMaxNumber=7`、`Spread_WeightType=2`；当前手动案例指定母体周围存在首个合法空位，自动案例单独讨论当前空位集合。

<details><summary>本案例共同前提</summary>

本地配表确认：`main_t_chest_new_1` 的开启时长 120 秒、可产出 7 次、储备 7 次，`Spread_WeightType=2`，权重为 `2401-2 / 2402-2 / 2501-2 / 2502-1`；没有 `Spread_ItemRecoveryDuration`，因此是一次性母体。素材为原版 Sprite 图标加说明性排布，不是运行时截图。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
