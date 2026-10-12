# 订单完成、补位与同步

需求和延迟奖励后，订单模型执行 `FinishOrder`，尝试补位，更新状态，发送完成事件并上传同步。订单 `LuckyTriggerChance` 与母体 LuckyProduce 独立；Lucky 订单可直接允许 Lucky 行为。

**配置**：`OrderFixedConfig`、`OrderRandomConfig`、订单类型和 `LuckyTriggerChance`。**源码**：`MainOrderModel:FinishOrder`、`SlotOrderModel:FinishOrder`、`BoardEventType.FinishOrder`。网络回调、补位失败重试和异步 UI `runtime-pending`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
