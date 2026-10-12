# 可交付判断

`CanDeliver` 按需求出现位置计数，不做集合去重；`[203,203]` 需要两份 203。按钮调用 `GetCodeCountMap(true,false,false)` 后进入判断，不足时展示确认窗口，取消不会扣除。

**配表**：订单需求来自 `OrderItemConfig` 和当前订单对象。**源码**：`BaseOrderCell:OnGoButtonClicked`、`BaseOrder:CanDeliver`。重复需求语义 `source-confirmed`，确认窗口时序 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
