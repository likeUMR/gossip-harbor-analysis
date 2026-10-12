# 需求扣除

每条需求先按棋盘有效位置顺序找相同代码；找不到才扫描仓库；两处都找不到记录 `FinishOrderRemoveItemError`。每项之后重新统计代码数量并 `UpdateOrderState`。

**状态**：`RemovedFromBoard`、`RemovedFromInventory`、订单代码计数。**源码**：`MainBoardModel:RemoveOrderRequirementItems`。**配置**：订单需求代码和数量。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
