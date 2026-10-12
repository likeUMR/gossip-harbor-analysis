# 可交付判断

`CanDeliver` 按需求出现位置计数，不做集合去重；`[203,203]` 需要两份 203。按钮调用 `GetCodeCountMap(true,false,false)` 后进入判断，不足时展示确认窗口，取消不会扣除。

**配表**：订单需求来自 `OrderItemConfig` 和当前订单对象。**源码**：`BaseOrderCell:OnGoButtonClicked`、`BaseOrder:CanDeliver`。重复需求语义 `source-confirmed`，确认窗口时序 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
