# 确认窗口的边界与待追踪调用

点击入口始终以 `GetCodeCountMap(true,false,false)` 检查棋盘，不计缓存和仓库。只有 `CanDeliver` 返回假才打开 `UseInventoryItemConfirmWindow`；取消路径在入口没有扣除、奖励或状态写入。

需要继续从窗口 prefab 对应 Lua 入口追踪：确认按钮是否将缺口映射转换为仓库索引、是否先删除仓库物品再重新调用 `MainBoardModel:FinishOrder`、取消/关闭是否只销毁窗口、网络失败是否回滚。当前报告不填入推测实现。

**源码证据**：`Board_View_Order_BaseOrderCell.lua:22-33`；**证据状态**：入口 `source-confirmed`，窗口内部调用链 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
