# 特殊与分支订单

`MainBoardModel:FinishOrder` 先检查 `order:GetInnerType()`。`Special` 进入 `_FinishSpecialOrder`，`Branch` 进入 `_FinishBranchOrder`，两者都会立即返回，不执行普通订单的奖励快照、亲密度礼物和逐项需求扣除链。

特殊订单按 `OrderSpecialConfig` 的 `Requirement1..3` 链和 `GeneratorChain` 批量清除棋盘相关物品，发放专用 `Rewards`，写入 `EndTimeline` 地图进度并派发 `BoardEventType.FinishSpecialOrder`。分支订单按单条 `Requirement` 链清除相关物品，然后对 `Rewards` 权重列表循环抽取并把结果落到空位；空位不足和尾部事件需要运行时复核。

**源码**：`MainBoardModel.lua:1101-1108`、`1258-1305`。Special/Branch 配置完整生效值当前未导出，标为 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
