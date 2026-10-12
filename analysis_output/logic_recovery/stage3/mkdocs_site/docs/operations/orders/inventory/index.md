# 库存确认与补交

棋盘计数不足时，`BaseOrderCell:OnGoButtonClicked` 不会直接完成订单，而是打开 `UseInventoryItemConfirmWindow`，并传入 `boardModel` 与订单对象。这个页面代表“玩家决定是否把仓库物品用于订单”的中层机制；确认窗口本身不是奖励或扣除实现。

入口已确认，窗口内的确认、取消、仓库扣除及再次进入 `FinishOrder` 尚未在当前静态材料中闭合，因此后续步骤标为 `runtime-pending`，不能把“打开窗口”解释为已经消耗仓库。

**源码**：`BaseOrderCell:OnGoButtonClicked`。**证据**：窗口调用 `source-confirmed`；确认回调和服务端失败/重试 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
