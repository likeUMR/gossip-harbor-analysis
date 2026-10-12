# 棋盘优先与仓库兜底

`RemoveOrderRequirementItems` 按需求原始顺序逐项处理。每项先用 `GetValidPositionIterator` 扫描棋盘，遇到第一个 code 相同的棋子就 `RemoveItem(item,false)`；棋盘没有匹配项时才按仓库索引从 1 开始扫描并删除第一个匹配物。每项删除后立即重新 `CountItemsCode` 和 `UpdateOrderState`，所以重复需求会看到前一项已经扣除后的数量。

两处都找不到时记录 `FinishOrderRemoveItemError`，不会抛异常，也没有静态证据表明前面已发奖励会回滚。返回结果分别记录 `RemovedFromBoard` 对象列表和 `RemovedFromInventory` 代码列表。

**源码**：`MainBoardModel:RemoveOrderRequirementItems`、`GetValidPositionIterator`、`GetCodeCountMap`。棋盘/仓库混合扣除的运行时动画和网络时序仍需回放确认。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
