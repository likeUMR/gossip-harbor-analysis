# 确认窗口的边界与待追踪调用

点击入口始终以 `GetCodeCountMap(true,false,false)` 检查棋盘，不计缓存和仓库。只有 `CanDeliver` 返回假才打开 `UseInventoryItemConfirmWindow`；取消路径在入口没有扣除、奖励或状态写入。

需要继续从窗口 prefab 对应 Lua 入口追踪：确认按钮是否将缺口映射转换为仓库索引、是否先删除仓库物品再重新调用 `MainBoardModel:FinishOrder`、取消/关闭是否只销毁窗口、网络失败是否回滚。当前报告不填入推测实现。

**源码证据**：`Board_View_Order_BaseOrderCell.lua:22-33`；**证据状态**：入口 `source-confirmed`，窗口内部调用链 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
