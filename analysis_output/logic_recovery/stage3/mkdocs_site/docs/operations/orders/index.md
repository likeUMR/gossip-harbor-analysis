# 订单提交

UI 入口 `BaseOrderCell:OnGoButtonClicked` 先获取代码数量并调用 `BaseOrder:CanDeliver`；不足时进入确认流程，足够时调用 `MainBoardModel:FinishOrder`。

- [可交付判断](check/index.md)
- [库存确认与补交](inventory/index.md)
- [奖励结算](rewards/index.md)
- [需求扣除](remove/index.md)
- [特殊与分支订单](special/index.md)
- [订单完成、补位与同步](finish/index.md)
- [订单创建与配置选择](creation/index.md)

---

## 贯穿案例：提交单需求订单

<div class="case-assets"><img src="../../../assets/cases/order.png" alt="提交单需求订单" class="case-composite" style="display:block;max-width:560px;width:100%;height:auto;"></div>

演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
