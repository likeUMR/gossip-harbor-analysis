# 需求扣除

每条需求先按棋盘有效位置顺序找相同代码；找不到才扫描仓库；两处都找不到记录 `FinishOrderRemoveItemError`。每项之后重新统计代码数量并 `UpdateOrderState`。

**状态**：`RemovedFromBoard`、`RemovedFromInventory`、订单代码计数。**源码**：`MainBoardModel:RemoveOrderRequirementItems`。**配置**：订单需求代码和数量。

---

## 贯穿案例：提交单需求订单

<div class="case-assets"><img src="../../../assets/cases/item-201.png" alt="棋子 201" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin-right:12px;"></div>

讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
