# 棋子拖拽与合成：调用链和实现规格

> 历史报告：2026-10-12已由MkDocs四层拖拽与合成页面及merge_gate_audit的新源码/字节码验证取代。此文不再作为实现依据。已知修正包括：交换最后一次写格会刷新订单；普通合成先清购买气泡记忆；基础概率0不会因最低阈值变为1%；卡片字符串键映射不被ipairs遍历；能量气泡外层没有满盘检查。新分析也尚未通过全量门禁，状态详见工作计划9.9。

> 机制编号：`BOARD-DRAG-MERGE-3.98.10`  
> 证据范围：当前已解出的 Gossip Harbor 3.98.10 客户端 Lua 字节码反汇编及 stage3 恢复文本。  
> 证据标记：`source-confirmed` 表示由代码/字节码直接确认；`runtime-pending` 表示需要运行时或真实配置快照确认；`unavailable` 表示当前样本没有客户端决定权。

## 1. 玩家动作的高层含义（第二层）

拖动一个棋子到棋盘格后，客户端按照固定的优先级解释这个落点：

1. 落点必须在棋盘有效范围内，且拖动开始时的源格仍然由同一个对象占据。
2. 空格表示普通移动；移动完成后更新位置、必要的加速计时，并发出移动结束事件。
3. 有目标棋子时，先尝试特殊棋子对目标的作用（升级/降级剪刀）。特殊作用一旦成功或弹出确认窗口，就截断后续普通合成。
4. 特殊作用没有接管后，检查是否可以合成。可合成时消耗拖入物，将目标替换成合成链的下一级，然后按顺序检查活动副产物、气泡和金币。
5. 不可合成时，检查目标是否能吞噬拖入物；能吞噬则累计吞噬进度并可能触发转换。
6. 以上都没有发生时，如果目标允许移动，则交换两个棋子；目标不可移动则把拖入物复位。

这不是“看到同类就合成”的单一规则：特殊影响优先于合成，吞噬优先于交换；每一条提前返回都会阻止后续副作用。`source-confirmed`（`Board_Model_Board_MainBoardModel.lua:282-331`）。

## 2. 入口与调用顺序（第三层）

### 2.1 视图层释放

`MainBoardView` 的拖动更新函数在 `MainBoardView.lua` 字节码反汇编源行 `623-752` 中执行以下顺序（`source-confirmed`）：

- 当前选中的模型不存在，直接返回。
- 使用 `m_model:CanItemMove(selected)` 判断拖动源是否可移动。
- 若指针位于 `Inventory` 且仓库功能开启，先调用 `StoreItem`；成功则播放放入动画并结束本次释放，否则显示锁定提示。
- 其余落点调用 `m_model:DragItem(selectedModel, boardPosition, false)`（反汇编源行 `678`）；旧版本/其它视图调用两参数重载（源行 `682`）。
- 调用返回后用 `GetItem(selected:GetPosition())` 更新选中位置；视图层负责拖动动画、合成高亮和音效，不改变模型规则。

拖动开始时（源行 `572-607`）会再次检查 `CanItemMove`，首次进入拖动状态时派发 `EEventType.StartDraggingItem`，刷新合成指示器和受影响效果。拖动过程中，合成灯光只允许在距离不超过一个格子的候选格内显示，并带 0.15 秒防抖；这是提示层约束，不是模型层合成许可。

### 2.2 模型入口 `MainBoardModel:DragItem`

证据：`analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:282-331`。

```text
PositionIsValid(target)
  ├─ 否：item.SetPosition(item.GetPosition())，返回
source = GetItem(item.GetPosition())
  ├─ source ~= item：复位，返回（防止过期视图/重复拖动覆盖棋盘）
target = GetItem(targetPosition)
  ├─ target == nil 或 target == item：移动到空位
  │    _SetItem(source,nil,false) -> _SetItem(target,item,false)
  │    _LogMove -> SetPosition -> _UpdateAccelerate -> ItemMoveEnd
  └─ 有目标：
       CanItemAffect -> _AffectItem（成功/等待确认即返回）
       特殊但不能作用 -> _ShowAffectFailTip
       CanItemMerge -> _MergeItem -> 返回
       target.ItemSwallow:CanSwallow(item) -> Swallow -> 返回
       !CanItemMove(target) -> 复位，返回
       否则交换两对象位置、写两条 Move 日志、更新加速
```

空位移动和交换都把 `autoUpdateOrderState` 置为 `false`，因此 `_SetItem` 本身只改棋盘层，不立即重复刷新订单；普通拖动完成没有显式 `OrderStateChanged`。合成/吞噬内部的删除、生成路径则按各自函数决定是否刷新订单。

## 3. 空位移动与交换的底层细节（第四层）

### 3.1 普通移动

`BaseBoardModel:_SetItem` 只调用 `m_itemLayerModel:SetItem(position,item)`（`014680c...lua:395-397`）；`MainBoardModel:_SetItem` 在 `autoUpdateOrderState ~= false` 时才执行 `CountItemsCode()`、`UpdateOrderState()`（`Board_Model_Board_MainBoardModel.lua:179-186`）。因此拖动分支明确传 `false` 是为了把一次位置调整作为一个原子操作。

移动成功后：

- `_LogMove` 将棋子 code、源坐标、目标坐标和活动事件 id 写入 `EBIType.MoveItem`（`Board_Model_Board_MainBoardModel.lua:755-778`）。
- `item:SetPosition(targetPosition)` 更新模型坐标。
- `_UpdateAccelerate(item,targetItem)` 检查 `ItemSpread:CanAccelerate`、`ItemTransform:CanAccelerate` 或 `ItemAccelerate:IsActivated`；任一对象满足时连续调用两次 `UpdatePerSecond()`，以立即刷新依赖秒级计时的组件（`:385-398`）。
- 空位移动额外派发 `EEventType.ItemMoveEnd`；交换分支没有同一处的 `ItemMoveEnd` 派发（`:315-330`）。这是需要运行时确认视图是否在其它回调补发的差异（`runtime-pending`）。

### 3.2 交换

交换前只检查目标 `CanItemMove`。该函数拒绝：纸箱组件、蜘蛛网组件、锁定组件；有 `ItemSwallow` 时还必须满足 `AllowTap()`（`014680c...lua:311-322`，反汇编文本的源码行标注为 `BaseBoardModel:CanItemMove`）。

交换写入顺序是：清空源格；把拖入物写入目标格；把原目标写回源格；分别记录拖入物和目标物的 Move 日志；更新两者 `SetPosition`；最后执行一次 `_UpdateAccelerate(item,targetItem)`。所有 `_SetItem` 调用传 `false`，所以交换不自行刷新订单状态。`source-confirmed`。

## 4. 合成资格：每一个判断的具体含义

证据：`analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:329-365`。

1. 若任一物品有 `ItemSpread` 且 `IsChestUsedOnce()` 为真，立即不可合成。一次性箱子已经被打开/使用后不能靠拖动再次并入链条。
2. 对每个物品分别决定比较 code：有 `ItemCobweb` 或 `ItemTemp` 时使用组件的 `GetInnerItemCode()`；普通物品使用 `GetType()`。
3. `mergedType` 取普通物品的 `GetMergedType()`；临时/蜘蛛网物品本身不提供合成目标，但其内含 code 可与普通同 code 物品匹配。
4. 若生成器工厂功能开启且该 code 属于工厂专用棋子，直接拒绝普通合成（`IsGeneratorFactoryOpen` + `IsGeneratorFactoryItem`）。
5. 最终条件是 `itemType1 == itemType2 and mergedType ~= nil`。也就是说必须同一逻辑类型，且至少一侧提供下一级 `MergedType`；配置中 `MergedType` 来自 ItemModelConfig。

`ItemModel` 在创建时把配置字段 `Type`、`MergedType`、`BubbleChance`、`SellingPrice`、`SpecialType` 复制到实例（`analysis_data/luac_disasm/Board/Model/Item/ItemModel.luac.txt:35-61,140-184`）。`GetMergedType` 是直接返回该字段；并非运行时按等级计算。具体链表必须以实际生效 ItemModelConfig 为准（`runtime-pending`，样本包含多套活动配置）。

## 5. 普通合成的执行与副产物顺序

### 5.1 原子合成

入口 `MainBoardModel:_MergeItem`（`:440-443`）调用 `_DoMergeItem`，结束后才 `_LogMerge`。`BaseBoardModel:_DoMergeItem`（`014680c...lua:236-260`）按以下顺序：

1. `RemoveItem(item,false)`：从棋盘层移除拖入物，并从 `ItemManager` 删除其持久化对象。
2. 若拖入物不是 `ItemTemp`，目标 code = `item:GetMergedType()`；若拖入物是临时物，目标 code = `targetItem:GetMergedType()`，日志用的 `itemType` 始终保留拖入物 code。
3. `GM.ItemDataModel:IsUnlocked(mergedType)` 在生成前查询是否首次解锁（`nil` 表示首次；布尔真值本身不是“首次”标记）。
4. `ReplaceItem(targetItem,mergedType,autoUpdateOrderState)`：删除目标并在目标位置 `GenerateItem` 新物品。`GenerateItem` 由 `ItemModelFactory.CreateWithCode` 创建对象、保存 ItemManager、写入棋盘、登记 `m_mergeAllIgnoredItems`。
5. 构造 `MergeItem` 消息：`Source`、`Target`、`New`、原始 `itemType`、`isFirstUnlock`。
6. 同步调用模型事件 `BoardEventType.MergeItem`，再全局派发 `EEventType.ItemMerged`。
7. `ShockNeighborItems(targetPosition)` 只检查四个正交邻格并向存在的 item 派发组件事件 `OnShock`，随后派发 `EEventType.ItemShocked`。

### 5.2 MainBoardModel 的后处理顺序

`MainBoardModel:_DoMergeItem`（`Board_Model_Board_MainBoardModel.lua:445-510`）在基础合成完成后追加：

1. 清空 `m_lastBreakBubbleType`。
2. `ScoreRace:_OnItemMerged(item)`；非 nil 的分数写入 `mergeInfo.ScoreRace_Score`。
3. 若棋盘未满，先问 `TempItem:GenerateType(mergeInfo.New:GetType())`。有结果时在合成物附近按 `FindEmptyPositionInSpreadOrder` 生成临时副产物，标记 `TempType`，停止后续副产物。
4. 否则问 `CardItem:TryGenerateItem(mergeInfo.itemType)`；有结果时同样按扩散顺序生成，标记 `CardType`，并派发 `EEventType.CardItemGenerate`。
5. 否则若 `EnergyBubble:CanSpreadEnergyBubble()`，读取 `GetBubbleInfo()`，生成其 `Code`，记录 `BubbleType` 和 `Group`。
6. 否则调用 `_TrySpreadBubbleByMerge(new,target)`，该函数可能生成普通气泡，并返回 code。
7. 即使前述副产物已生成，若棋盘未满且合成链等级达到 `SystemConfigKey.SpreadCoinMinChainLevel`，仍在扩散顺序的空位生成 `ItemType.Coin01`；金币不是 `hasCreateItem` 的互斥分支。
8. `GM.SyncModel:CheckMoreUpload(newType)` 检查同步上传。

所以一个合成最多有一个“临时/卡片/能量气泡/普通气泡”主副产物，但还可能再有一个金币。合成后处理不会随机抽“副产物类型”；类型优先级由上述 if 顺序决定。`source-confirmed`。

## 6. 气泡副产物的算法、修正和随机语义

证据：`Board_Model_Board_MainBoardModel.lua:517-675`。

1. 棋盘已满则直接返回，无随机数调用。
2. 只有 `OpenFunctionModel:IsFunctionOpen(EFunction.Bubble)` 为真时读取新物品配置的 `BubbleChance`。
3. 若棋盘已有相同内含 code 的气泡，取消本次气泡机会（避免同类气泡并存）。
4. 若购买奖励 `_CanBubbleBuyBonus` 成立，或订单奖励 `_CanBubbleOrderBonus` 成立，将概率强制设为 100%。订单奖励还要求 `BubbleOrderBonus` 为 1/2、订单 item 配置 `WeightMultiple == 1`、目标下一级存在且订单缺口大于 0；模式 2 额外要求当前库存/棋盘中目标数量少于 2（`:645-692`）。
5. 普通情况下按乘法顺序依次修正：
   - `_GetDecreaseBubbleChanceRatio`：读取 `EGeneralConfType.BubbleOrderDecrease`；若有效，统计订单中 `WeightMultiple==1` 的链上需求，并要求库存数量覆盖每个这种需求，否则返回 ratio。该 ratio 乘入原始概率。
   - `_GetDecreaseBubbleChanceRatio2`：读取 `BubbleChainDecreaseLevel` 与 `BubbleChainDecreaseRatio`；统计当前棋盘中高于指定等级的气泡 code，每个气泡使 ratio 乘 `decreaseRatio ^ count`；再乘入概率。
   - `GM.BubbleDecreaseModel:GetBubbleDecreaseRatio()`：玩家侧气泡衰减模型的 ratio 最后乘入。
   - 最终概率下限为 1（百分比单位），不会因修正降到 0。
6. 测试模式偏好 `TestBubbleMustSpread=1` 会在随机前把概率改为 100%。
7. 判定表达式是 `bubbleChance >= MathUtil.Random(100)`。当通过时，气泡 code 由新物品 type 加 `ItemCodePrefix.Bubble` 组成；纯数字 type 则使用 `tonumber(type)+ItemCodeOffset.Bubble` 的数值编码。落点使用 `FindEmptyPositionInSpreadOrder(new.position)`；调用 `SpreadItem` 后派发 `EEventType.BubbleSpread`。

随机语义：这里是一次独立的整数阈值判定，不是候选池抽样。`Common/Utility/MathUtil.luac.txt:37-66` 确认单参数整数调用走 `floor(math.random() * upper) + 1`，所以 `MathUtil.Random(100)` 的取值为 **1..100（含两端）**；测试模式还可由 `GM.TestModel:GetMathRandomNumber()` 注入受控的 `[0,1)` 浮点源。若最终概率为 `p`（百分比），通过条件是 `R <= p`，即整数阈值下约 `p/100`，p=1 仍有 1% 下限。每次合成至多调用一次该随机接口。`source-confirmed`。

## 7. 特殊棋子作用（升级与降级）

证据：`Board_Model_Board_MainBoardModel.lua:303-414`；`ItemModel.luac.txt:182-200`。

### 7.1 资格与确认窗口

`CanItemAffect` 只是转发 `targetItem:CanSpecialTypeAffect(item:GetSpecialType())`。`ItemModel:CanSpecialTypeAffect` 的字节码显示：传入类型为空返回 false；目标的 `m_mapSpecialTypeTarget[specialType]` 必须为真；降级还必须 `not board:IsBoardFull()`。此外，目标自身为降级时对降级拖入物返回 true，这是双剪刀合并专用分支。映射表由 ItemModelFactory 从配置字段加载，具体 code→specialType→target 映射需从当前配置快照逐项导出（`runtime-pending`）。

### 7.2 LevelUp

拖入升级棋子时弹出 `UseSpecialItemConfirmWindow`，传入拖入类型、目标类型、目标 `MergedType`，场景 key `rainbow_item_use_confirm`。确认回调再次检查 `CanItemAffect`，然后：删除升级物；用目标 `MergedType` 替换目标；派发 `BoardEventType.MergeItem`、`EEventType.ItemMerged`；震动四邻格并派发 `ItemShocked`；BI 记录 `levelup=1`。回调关闭窗口。等待确认期间拖入物位置立即复位。若确认时状态已改变，则无副作用。

### 7.3 LevelDown（双剪刀）

目标也是 LevelDown 时：删除两把剪刀，生成目标 type 的新剪刀，读取两者 `ItemSplit:GetSplitUseCount()` 之和写入新组件；派发合成事件；BI 记录 `{scissor=scissorCount}`。这是消耗次数相加，不是次数重置。

### 7.4 LevelDown（把目标拆成两个前一级）

目标不是 LevelDown 时，读取目标 type 的 chain id、chain level、chain，取 `chain[level-1]` 为前一级。确认窗口场景 key 为 `scissor_item_use_confirm`。确认后先扣拖入剪刀次数；若无剩余则删除剪刀；删除目标；在目标位置生成一个前一级；再用 `FindEmptyPositionInSpreadOrder(targetPosition)` 找第二个空位并生成第二个前一级；派发 `BoardEventType.SplitItem`（字段 `Split`,`Target`,`New1`,`New2`），BI 记录 `LogSplit(targetType,newType,{scissor=1})`。若没有空位，`GenerateItem(nil,...)` 的行为和 `SpreadItem` 的失败处理需要运行时确认；代码未显式对 `otherPosition==nil` 分支保护（`runtime-pending`）。

特殊作用成功后不会进入普通合成、吞噬或交换分支。

## 8. 吞噬棋子：拖入、进度、转换

证据：`Board_Model_Item_ItemSwallow.lua:1-151`。

- `CanSwallow(item)` 遍历两个配置槽，只有 code 相等且 `Swallowed < Count` 才为真。
- `Swallow(item)` 将对应槽的 `Swallowed` 加 1，立即保存目标吞噬棋子的属性；从棋盘移除拖入物；派发 `BoardEventType.SwallowItem` 和全局 `EEventType.ItemSwallow`，BI 记录 source/target code。
- 每次吞噬触发组件 `ProgressChanged`。只有两个槽都达到 Count 才调用目标的 `ItemTransform:Transform()`；如果目标不允许点击，还额外震动四邻格。
- 配置字段为 `Swallow_Weight1/2`、`Swallow_Number1/2`。初始化时通过 `ItemFixedSwallowModel:GenerateTargetCode(itemConfig.Type, weight, index)` 将权重转换为具体目标 code；教程强制类型 `TutorialBoardHelper.GetForcedSwallowItemTypes()` 会覆盖该选择。该选择器的底层算法已由 `analysis_data/luac_disasm/Board/Model/Board/ItemFixedSwallowModel.luac.txt:10-72` 确认：
  1. 以 `itemType` 和槽位 index 拼出数据库键 `sequence<index>`，读取上次剩余序列；同时把配置的 `CodeWeightPairs` 序列化为 code/weight 对。
  2. 若数据库序列为空，调用 `_GenerateSequence(pairs)`。该函数先求权重总和 `W`，建立 `[1..W]` 的整数数组，再从 `W` 递减到 1，每轮调用 `MathUtil.Random(i)` 选数组下标并交换到当前位置，形成 1..W 的随机排列；最后用逗号连接并保存。
  3. `GenerateTargetCode` 取序列第一个整数 `r`，按 `CodeWeightPairs` 顺序做累计权重减法：若 `r <= pair.Weight` 返回该 pair 的 `Code`，否则 `r -= pair.Weight` 继续下一项。取出的整数从数据库序列删除，剩余序列立即写回。
  4. 序列耗尽后才重新生成一套排列。因此每个槽位是在总权重展开池上的**无放回抽样**；同一 code 仍可出现多次，次数等于其 weight，跨越序列边界才重新开始。它不是每次调用都独立按概率抽样，也没有运行时“抽中后扣权重”的临时内存状态，持久化数据库序列就是抽样状态。`source-confirmed`。
- 目标生成时记录 `m_generateTime=GetServerTime()`；点击吞噬目标自身受 `TapProtectionTime=1` 秒保护，但拖动入口的 `CanSwallow` 不检查这 1 秒，因此拖入吞噬与点击批量吞噬存在不同门槛。

## 9. 事件、持久化和订单状态

| 阶段 | 模型事件 | 全局事件/同步 | 持久化与状态 |
|---|---|---|---|
| 空位移动 | 无 BoardEvent | `ItemMoveEnd` | 位置写入 ItemLayerModel；无自动订单刷新 |
| 交换 | 无 BoardEvent | 代码入口未派发 `ItemMoveEnd` | 两格写入 ItemLayerModel；无自动订单刷新 |
| 普通合成 | `MergeItem` | `ItemMerged`、`ItemShocked`；后处理可能 `CardItemGenerate`、`BubbleSpread`、`ItemSpread` | 删除/生成写 ItemManager；`ReplaceItem` 的 `autoUpdateOrderState` 由调用参数决定 |
| 特殊升级 | `MergeItem` | `ItemMerged`、`ItemShocked` | 删除升级物、替换目标；确认回调二次校验 |
| 特殊拆分 | `SplitItem` | 无同名全局 Split 事件证据 | 扣 Split 次数、删目标、生成两个前一级 |
| 吞噬 | `SwallowItem` | `ItemSwallow` | 保存目标吞噬进度；删除 source；完成后 Transform |

订单状态由 `MainBoardModel:UpdateOrderState`（`:975-984`）重算：统计棋盘、缓存和仓库 code 数量，调用每个订单模型 `UpdateState`，计算 requirement/lack map，最后派发 `EEventType.OrderStateChanged`。拖动空位/交换本身传 false，不直接调用它；合成生成/删除路径若 `autoUpdateOrderState` 未禁用会触发刷新。具体哪一类合成调用最终触发订单刷新，需结合调用方传参和运行时事件序列核对（`runtime-pending`）。

## 10. 自动合成与测试入口（非普通玩家路径）

`BaseBoardModel:MergeAll`（`014680c...lua:262-319`）只在测试/调试或显式调用下运行。它先按 `GetValidPositionIterator` 建组，跳过已用一次的箱子、不可交互位置、工厂棋子以及测试偏好排除项；普通、临时、蜘蛛网分组后优先蜘蛛网→临时→普通→橙树。组内使用 `Table.ListRandomSelectOne/N`，所以自动测试合并的配对选择是随机的；不是玩家拖拽的选择规则。若 `lastTouchedItem` 存在，则优先找曼哈顿距离最近的同 code 对并记录 `m_logNearestTouchedMergeItem`，供 `_LogMerge` 的 `isTouched` 字段使用。`runtime-pending`：测试按钮的可见开关和正式包是否暴露该入口。

## 11. 配置字段索引

| 配置/状态 | 读取位置 | 作用 |
|---|---|---|
| `Type` | ItemModelFactory/ItemModel | 逻辑比较 code、日志和订单需求 |
| `MergedType` | ItemModel | 普通合成的输出 code；为空表示链末端 |
| `SpecialType`、特殊目标映射 | ItemModelFactory、ItemModel | LevelUp/LevelDown 资格和目标 |
| `BubbleChance` | ItemModel、MainBoardModel | 合成后普通气泡初始百分比 |
| `SellingPrice` | ItemModel | 与拖拽无关，但移动/合成后的出售值保持配置值 |
| `Swallow_Weight1/2` | ItemSwallow | 通过固定吞噬模型选择目标 code |
| `Swallow_Number1/2` | ItemSwallow | 每个槽需要吞噬的数量 |
| `SpreadCoinMinChainLevel` | SystemConfig | 合成物达到该链等级后额外产金币 |
| `BubbleOrderDecrease` | GeneralConf | 订单缺口满足时的气泡概率乘数 |
| `BubbleChainDecreaseLevel/Ratio` | GeneralConf | 高等级气泡数量造成的乘法衰减 |
| `BubbleOrderBonus` | GeneralConf | 订单奖励将气泡概率强制 100% 的模式 |
| `TestBubbleMustSpread` | PlayerPrefs（测试） | 强制气泡 100% |
| `ItemLandOpt` | ServerControl GeneralConf | 缓存物弹出时的落点优化，非普通拖拽 |

原始配置反汇编样本：`analysis_data/luac_disasm/Data/Config/AdventureItemModelConfig_*.luac.txt`；通用字段读取证据：`analysis_data/luac_disasm/Board/Model/ItemModelFactory.luac.txt:760-850`、`Board/Model/Item/ItemSwallow.luac.txt:120-160`。

## 12. 未确认项与下一步核销

1. 当前生效 ItemModelConfig 的完整链条、特殊映射和每个棋子数值；包内存在多活动配置，需追装载覆盖优先级。
2. `ItemFixedSwallowModel` 的权重数值及服务端是否覆盖 `FixedSwallow` 表仍需导出；抽样算法、持久化序列和序列耗尽后的重建已经 `source-confirmed`。
3. 双剪刀/拆分时第二空位为空的异常行为；静态代码未显式处理 nil。
4. 交换分支是否由视图或事件监听器补发 `ItemMoveEnd`，以及各类合成调用的订单刷新时刻。
5. `ScoreRace`、`TempItem`、`CardItem`、`EnergyBubble`、`BubbleSale`、`BubbleDecreaseModel` 的活动配置和服务端开关；本报告已列出调用顺序，但活动内部算法需分别建立第四层页面。
6. `ItemMerged` 监听器的完整异步链（UI 动画、成就、教程、任务和网络上传）尚未在本报告展开；应从 `EventType` 注册表反向检索所有监听器。

以上未确认项不影响已确认的分支顺序，但在阶段三门禁中不能标记为实现规格完成，直到配置快照或运行时追踪补齐。

