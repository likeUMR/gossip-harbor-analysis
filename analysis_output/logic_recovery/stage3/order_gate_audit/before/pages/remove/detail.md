# 棋盘优先与仓库兜底

`RemoveOrderRequirementItems` 按需求原始顺序逐项处理。每项先用 `GetValidPositionIterator` 扫描棋盘，遇到第一个 code 相同的棋子就 `RemoveItem(item,false)`；棋盘没有匹配项时才按仓库索引从 1 开始扫描并删除第一个匹配物。每项删除后立即重新 `CountItemsCode` 和 `UpdateOrderState`，所以重复需求会看到前一项已经扣除后的数量。

两处都找不到时记录 `FinishOrderRemoveItemError`，不会抛异常，也没有静态证据表明前面已发奖励会回滚。返回结果分别记录 `RemovedFromBoard` 对象列表和 `RemovedFromInventory` 代码列表。

**源码**：`MainBoardModel:RemoveOrderRequirementItems`、`GetValidPositionIterator`、`GetCodeCountMap`。棋盘/仓库混合扣除的运行时动画和网络时序仍需回放确认。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
