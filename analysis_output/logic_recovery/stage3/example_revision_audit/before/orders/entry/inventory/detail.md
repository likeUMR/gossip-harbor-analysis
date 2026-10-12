# 仓库确认与关闭后的提交：具体算法与配置

Init再次CanDeliver(GetCodeCountMap(true,false,false))，以pairs遍历缺口，每个count拆成count条{type=code,count=1}给rewardContent；不同code展示顺序不保证固定。可选listListeners逐个AddActiveListener到Close。红按钮仅Close；绿按钮m_bFinishOrder=true再Close。OnCloseFinish先BaseWindow.OnCloseFinish；标记非真不做提交，有callback则优先执行callback，否则GetOrderModel(Slot).ContainsOrder(order)才FinishOrder。普通按钮未传callback/listListeners。此处不再CanDeliver、不验证仓库数量；“订单仍在”也不等于“材料足够”。取消不扣物。窗口期间数量变化可能导致后续部分扣除失败，不能凭空增加原版事务保证。

## 源码依据

- UI.Window.Board.UseInventoryItemConfirmWindow：[恢复源码](../../../../assets/order-evidence/UI.Window.Board.UseInventoryItemConfirmWindow.lua) · [原始指令](../../../../assets/order-evidence/UI.Window.Board.UseInventoryItemConfirmWindow.disassembly.txt)。对应：UseInventoryItemConfirmWindow:Init（恢复文本行4）；UseInventoryItemConfirmWindow:OnRedClick（恢复文本行30）；UseInventoryItemConfirmWindow:OnGreenClick（恢复文本行34）；UseInventoryItemConfirmWindow:OnCloseFinish（恢复文本行39）

- Board.View.Order.BaseOrderCell：[恢复源码](../../../../assets/order-evidence/Board.View.Order.BaseOrderCell.lua) · [原始指令](../../../../assets/order-evidence/Board.View.Order.BaseOrderCell.disassembly.txt)。对应：BaseOrderCell:Init（恢复文本行41）


---

## 贯穿案例：203×2与204×1，使用仓库补交

<div class="case-assets"><img src="../../../../../assets/cases/item-204.png" alt="棋子204" width="72" height="72"></div>

窗口显示204×1，确认后订单仍在槽1，于关闭完成回调提交；仓库204直到扣除阶段才删除。

### 代入本页的值

缺口1→展示一条{type=204,count=1}；绿按钮finish=true；callback=nil、ContainsOrder=true→FinishOrder。对照订单已移出槽：不提交。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
