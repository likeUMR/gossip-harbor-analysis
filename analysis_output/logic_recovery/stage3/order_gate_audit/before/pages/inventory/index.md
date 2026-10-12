# 库存确认与补交

棋盘计数不足时，`BaseOrderCell:OnGoButtonClicked` 不会直接完成订单，而是打开 `UseInventoryItemConfirmWindow`，并传入 `boardModel` 与订单对象。这个页面代表“玩家决定是否把仓库物品用于订单”的中层机制；确认窗口本身不是奖励或扣除实现。

入口已确认，窗口内的确认、取消、仓库扣除及再次进入 `FinishOrder` 尚未在当前静态材料中闭合，因此后续步骤标为 `runtime-pending`，不能把“打开窗口”解释为已经消耗仓库。

**源码**：`BaseOrderCell:OnGoButtonClicked`。**证据**：窗口调用 `source-confirmed`；确认回调和服务端失败/重试 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
