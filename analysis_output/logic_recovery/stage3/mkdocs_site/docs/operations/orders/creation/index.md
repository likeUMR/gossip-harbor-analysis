# 订单创建与配置选择

每次订单槽位为空或订单已完成时，`MainOrderModel:_TryCreateOrder` 按固定优先级尝试：Fixed、ReturnFreeOrder、Tutorial、Contiorders、ExtraCustomer、LuckyOrder，最后才是普通 Random。前一个 creator 返回非空后不会继续尝试；成功的 Random 订单若没有 ID 才由 `DBIdGenerator` 补 ID，并派发 `MainOrderCreated`。

随机订单按 `OrderRandomConfig.Type` 选择过滤器，读取玩家等级、`DiffSum`、`First/Second/Third Min/Max`、`RefreshTime` 和 `ItemAmounts`；物品候选还要经过解锁等级、进度、禁用槽位、生成器、其它订单和上一个订单排除。`OrderItemConfig` 提供 `Code`、`DiffScore`、`Price`、`RecommendedPrice`、`UnlockLevel`、`ProgressUnlock`、`ForbiddenSlot`、`Weight`、`WeightMultiple`、`RepeatWeightDecrease`、`RecommendedNumber`、`DifficultyLevel`。

**源码**：`MainOrderModel.lua:527-558`、`LoadFileConfig:31-86`、`MainOrderCreatorRandom.luac.txt` 原始行 119-1208。创建优先级的静态顺序 `source-confirmed`；活动/账号实际命中 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
