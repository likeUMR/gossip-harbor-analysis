# 一次性落点的具体算法

## 1. 手动路径：`FindEmptyPositionInSpreadOrder`

`CheckSpreadPosAndAuto` 把母体坐标作为 `centerPosition` 传给 `FindEmptyPositionInSpreadOrder`。实现先令 `currentPosition = centerPosition`，令 `maxTiles = max(HorizontalTiles, VerticalTiles)`；对 `i = 1 .. maxTiles - 1`，先把当前位置移动到本层左下角方向的 `(-1,-1)`，得到边长为 `2*i` 的方形环，再按四个方向依次走 `2*i` 格。每走一格先调用 `PositionIsValid`，越界格跳过；合法格再调用 `GetItem(position)`，只有返回 `nil` 才是候选格。遇到第一个合法空位立即返回。

所有环都没有空位时返回传入的 `openedPosition`；本调用没有传该参数，因此最终是 `nil`。这一步没有随机接口，也没有写棋盘，只产生一个待使用坐标。

## 2. 自动路径：分流和循环

`Update` 仅在 `IsAutoSpread()`（`m_auto == 1`）为真时进入循环。每轮 `_TryAutoSpread` 先要求 `m_itemRestNumber ~= 0` 且 `m_state == Opened`，再经 `_GetAutoSpreadPosition → MainBoardModel:FindSpreadPosition` 选择位置。`FindSpreadPosition` 的分支是：一次性母体（`IsDisposable() == true`）调用 `FindRandomPosition`；可恢复母体调用八邻域 `FindEmptyPositionInCircleOrder`。位置成功后才调用 `GenerateItemCode` 和 `SpreadItem` 写入棋盘。

## 3. `FindRandomPosition`：候选表和随机范围

底层每次调用都新建局部数组 `positions = {}`。`GetValidPositionIterator()` 按棋盘坐标遍历：从 `(1,1)` 开始，x 递增，超过棋盘宽度后换到下一行 y。每个位置读取 `GetItem`；空位才插入 `positions`，被占用和无效格都不进入候选。

- 候选数为 `N = #positions`；`N == 0` 时 `Table.ListRandomSelectOne` 返回 `nil`。
- `N > 0` 时调用 `MathUtil.Random(N)`，本版本接口返回整数 `1..N`（含两端），用作数组下标；每个当前空位概率均为 `1/N`。
- 函数不保存历史位置、不删除已选项，也不在返回前写入棋盘。下一轮重新扫描当时的棋盘状态，因此在“抽样后尚未落子”的窗口内可以再次选中同一格；落子成功后该格才从下一轮候选表消失。这是当前实现的**有放回抽样语义**，与 Decremental 产物权重池的扣减/移除不是同一件事。

## 4. 自动满盘和缓存

位置为空时，`_TryAutoSpread` 计算 `bAllowAutoSpreadToCache`。必须同时满足 `IsDisposable()`、`m_weightType == Decremental`、棋盘实现 `CacheItemFromSpread`，以及 `IsServerControlOpen(AutoSpreadToCache)`。条件不全满足就返回 `false`，不会消耗次数。

条件全部满足时，调用 `GetAutoSpreadDecrementalRemainTypes()`，把当前每个 `{Code, Weight}` 展开为重复代码数组；写入 `CacheItemFromSpread`，将 `m_spreadCount` 增加数组长度，再调用 `EmptySpreadCount` 把次数、储备和 Decremental 权重清空，并保存属性、派发状态变化。

## 5. 失败和销毁的精确边界

`CheckSpreadPosAndAuto` 返回位置后，`_TrySpread` 才调用 `CheckEnergy`。若棋盘满，`_NotifySpreadFailed` 同时派发 `BoardEventType.SpreadFailed`、`EEventType.SpreadFailed` 和 `VibrationHeavy`；后续 `GenerateItemCode`、`SpreadCostEnergy`、`SpreadItem`、`CosetRestNumber` 都不会发生。

成功落子后，点击链才执行 `TryRemoveSelf`：一次性母体的 `m_itemRestNumber == 0` 时调用 `RemoveItem` 并派发 `CollapseItem`。所以母体不会在“准备找位置”时删除，而是在产物已写入棋盘、次数已扣减后才销毁。

## 6. 落点成功后，哪些逻辑才会继续

落点函数只负责坐标，调用链的后续顺序仍然固定：

1. `CheckEnergy` 读取 `Spread_CostEnergy`；一次性样本 `main_t_chest_new_1` 的值为 `0`，所以这条样本不扣能量，但仍然必须先有合法空位。
2. `GenerateItemCode` 先尝试 Lucky，再尝试 Disco，最后按 `Spread_WeightType` 进入 Fixed、Decremental、OrderItem、ChestCustomItem 或 SmartItem。一次性落点算法不改变产物池；它只把 `position` 传给后续写入。
3. 普通 Decremental 分支调用 `Table.ListWeightSelectOne(m_codeWeightPairs)`，选中后立即把对应 `Weight` 减 1，减到 0 就从 `m_codeWeightPairs` 删除，并保存母体属性。这是产物权重池的无放回式耗尽过程，和自动落点的有放回位置抽样是两套独立状态。
4. `CosetRestNumber` 先把 `m_spreadCount` 加 1；一次性母体默认扣 `floor(2 ^ energyBoostRatio)` 次数，结果下限为 0。之后 `SpreadItem` 才把新棋子写入已选位置。
5. 写入成功后 `TryRemoveSelf` 检查变换次数，再检查一次性剩余次数是否为 0；满足后删除母体并发送 `CollapseItem`，否则才有机会进入 CD Buff。

因此复刻时必须保存两类不同的状态：`m_codeWeightPairs`（产物权重剩余）和棋盘占用集合（位置候选）。前者会因抽到某个代码而扣减，后者只在棋子真正落盘后改变。

## 7. 可直接复刻的伪代码

```text
function manual_position(board, center):
    for ring = 1 .. max(board.width, board.height)-1:
        p = center + (-ring, -ring)
        for direction in [right, up, left, down]:
            repeat 2*ring times:
                if board.valid(p) and board.item_at(p) == nil:
                    return p
                p = step(p, direction)
    return nil

function random_position(board):
    candidates = [p for p in board.valid_positions() if board.item_at(p) == nil]
    if candidates is empty: return nil
    return candidates[random_integer_inclusive(1, len(candidates))]

function auto_spread_once(generator):
    if generator.rest == 0 or generator.state != Opened: return false
    p = random_position(board) if generator.disposable else circle_position(board, generator.position)
    if p is nil: maybe_cache_remaining_decremental(generator); return false
    code = generate_code()
    board.spread_item(generator, p, code)
    return true
```

**底层证据位置**：`ItemSpread.lua` 的 `CheckSpreadPosAndAuto`（847-862）、`_TryAutoSpread`（798-828）、`_TrySpread`（864-928）、`TryRemoveSelf`（930-944）；`MainBoardModel.lua` 的 `FindSpreadPosition`（230-237）；解码 `BaseItemLayerModel` 的 `FindEmptyPositionInSpreadOrder` 和 `FindRandomPosition`；`Table.ListRandomSelectOne`。`MathUtil.Random` 的种子来源、实际棋盘尺寸和服务端 `AutoSpreadToCache` 开关仍是 `runtime-pending`，不能从客户端静态代码推出。

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
