# 订单完成、补位与同步

需求和延迟奖励后，订单模型执行 `FinishOrder`，尝试补位，更新状态，发送完成事件并上传同步。订单 `LuckyTriggerChance` 与母体 LuckyProduce 独立；Lucky 订单可直接允许 Lucky 行为。

**配置**：`OrderFixedConfig`、`OrderRandomConfig`、订单类型和 `LuckyTriggerChance`。**源码**：`MainOrderModel:FinishOrder`、`SlotOrderModel:FinishOrder`、`BoardEventType.FinishOrder`。网络回调、补位失败重试和异步 UI `runtime-pending`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
