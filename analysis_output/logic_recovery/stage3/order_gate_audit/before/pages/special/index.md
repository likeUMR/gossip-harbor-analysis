# 特殊与分支订单

`MainBoardModel:FinishOrder` 先检查 `order:GetInnerType()`。`Special` 进入 `_FinishSpecialOrder`，`Branch` 进入 `_FinishBranchOrder`，两者都会立即返回，不执行普通订单的奖励快照、亲密度礼物和逐项需求扣除链。

特殊订单按 `OrderSpecialConfig` 的 `Requirement1..3` 链和 `GeneratorChain` 批量清除棋盘相关物品，发放专用 `Rewards`，写入 `EndTimeline` 地图进度并派发 `BoardEventType.FinishSpecialOrder`。分支订单按单条 `Requirement` 链清除相关物品，然后对 `Rewards` 权重列表循环抽取并把结果落到空位；空位不足和尾部事件需要运行时复核。

**源码**：`MainBoardModel.lua:1101-1108`、`1258-1305`。Special/Branch 配置完整生效值当前未导出，标为 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
