# 一次性母体落点

这一页回答“一次性母体点击后，落点阶段先做什么、为什么这样做”。一次性描述的是耗尽后的生命周期，不是每次点击都随机找格子。正式点击链的顺序是：

1. `OnTap` 进入 `_TrySpread`，先过状态门槛；关闭、开启中、初始化中或次数为零时直接失败返回。
2. `CheckSpreadPosAndAuto` 先判断是否为自动母体。手动一次性母体调用 `FindEmptyPositionInSpreadOrder(母体坐标)`，按固定方形环取第一个合法空格。
3. 只有 `Spread_Auto == 1` 的自动路径才先调用 `FindSpreadPosition`；一次性母体在这里调用 `FindRandomPosition`，从当前全盘空位中均匀抽一个。自动路径已经找到位置时，手动点击不会再执行第二次扩散扫描。
4. 找不到位置时，手动路径发送 `SpreadFailed(BoardFull)`，流程在能量检查之前结束；因此这次不生成产物、不扣能量、不扣次数。自动路径只会返回 false，另有满足条件的缓存分支。
5. 找到位置后才进入能量检查、Lucky/普通产出、落子和次数扣除。一次性母体成功落子且剩余次数归零时，`TryRemoveSelf` 删除母体并派发 `CollapseItem`。

## 这一层要掌握的结论

- **手动点击位置是确定性的**：同一母体坐标和同一棋盘占用状态得到同一格，不调用随机数。
- **自动位置是当前集合上的均匀抽样**：每次 `FindRandomPosition` 都重新扫描空位并重新抽样，不保存已经抽过的格子集合。因此抽样本身是有放回语义；只有某格真正写入棋盘后，它才从下一次候选集合消失。
- **一次性判定由缺失字段实现**：`IsDisposable()` 等价于 `m_itemRecoveryDuration == nil`。它影响耗尽后的删除/缓存和 CD 恢复，不改变手动落点算法。

**源码证据**：`ItemSpread:OnTap`、`_TrySpread`、`CheckSpreadState`、`CheckSpreadPosAndAuto`、`TryRemoveSelf`、`_TryAutoSpread`、`MainBoardModel:FindSpreadPosition`、`BaseItemLayerModel:FindEmptyPositionInSpreadOrder`、`BaseItemLayerModel:FindRandomPosition`。配置字段来自 `ItemModelConfig`。确定的代码分支标为 `source-confirmed`；服务端缓存开关、实际账号棋盘和运行时随机种子仍标为 `runtime-pending`，不能由静态代码假定。
---

## 贯穿案例：打开一次性测试宝箱 main_t_chest_new_1

<div class="case-assets"><img src="../../../../assets/cases/item-main_t_chest_new_1.png" alt="一次性测试宝箱 main_t_chest_new_1" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：观察一次性母体在开启、落点、Decremental 权重和耗尽销毁之间的完整链路。

**本页发生什么**：本页使用一次性测试宝箱 `main_t_chest_new_1` 作为独立案例。它没有 `Spread_ItemRecoveryDuration`，因此 `IsDisposable()` 为 true；手动点击仍先按母体周围的方形环找空位，自动路径才会使用全盘随机空位。

### 代入本页的值

`Spread_OpenDuration=120`、`Spread_ItemMaxNumber=7`、`Spread_StorageMaxNumber=7`、`Spread_WeightType=2`、权重 `2401-2/2402-2/2501-2/2502-1`；未配置物品恢复时长。

<details><summary>本案例共同前提</summary>

本地配表确认：`main_t_chest_new_1` 的开启时长 120 秒、可产出 7 次、储备 7 次，`Spread_WeightType=2`，权重为 `2401-2 / 2402-2 / 2501-2 / 2502-1`；没有 `Spread_ItemRecoveryDuration`，因此是一次性母体。素材为原版 Sprite 图标加说明性排布，不是运行时截图。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>
