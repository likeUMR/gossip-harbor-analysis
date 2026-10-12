# 完成状态、补位循环和事件顺序

普通订单由 `MainBoardModel:FinishOrder` 发放奖励并调用一次 `order:SetFinished()`；随后所属 `OrderModel:FinishOrder` 会再次调用 `SetFinished`，写完成日志并进入 `_TryFillOrders`。第二次调用复用已缓存奖励，这是源码中的双写顺序。

`_TryFillOrders` 用 `repeat` 扫描所有空槽或 Finished 槽，只要本轮成功创建过订单就再扫一轮，直到整轮没有新订单；最后更新订单状态并记录新订单 unlock 日志。主订单模型在补位前还处理分支完成、亲密度、下一单 Lucky 资格和 `RepeatWeightDecrease` 重置。尾部顺序是 `UpdateOrderState` → OrderBoost 微笑事件（条件满足时）→ `CheckMoreUpload` → `BoardEventType.FinishOrder`；`EEventType.OrderFinished` 在槽位模型补位完成后更早发送。

特殊订单和分支订单在 `FinishOrder` 入口直接分流到专用函数，不进入普通奖励/扣除链。订单 Lucky 使用 `LuckyTriggerChance`，与母体 LuckyProduce 机会池独立。

**源码**：`MainBoardModel:FinishOrder`、`MainOrderModel:FinishOrder`、`SlotOrderModel:FinishOrder`、`_TryFillOrders`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
