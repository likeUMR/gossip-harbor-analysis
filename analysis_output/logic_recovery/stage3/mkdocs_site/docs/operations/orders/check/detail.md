# 重复需求与计数来源

普通订单按钮先要求 `m_bGoButtonEnabled`，再调用 `GetCodeCountMap(true,false,false)`；这三个参数的含义是只计棋盘，不计缓存和仓库。`BaseOrder:CanDeliver` 按需求原始顺序逐项检查：第 i 项先统计它在前 i 项中出现了几次，再要求代码数量至少达到这个序号。因此 `[203,203,204]` 要求 203 两个、204 一个，不能转成去重集合。

棋盘不足时入口打开仓库确认窗口；普通成功路径才进入 `FinishOrder`。显示层的 `CanDeliver` 状态只来自订单状态刷新，不能当作扣除已经完成的证明。

**源码**：`BaseOrderCell:OnGoButtonClicked`、`BaseOrder:CanDeliver`、`BaseBoardModel:GetCodeCountMap`。重复需求和入口计数口径为 `source-confirmed`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
