# 仓库确认与关闭后的提交：具体算法与配置

Init再次CanDeliver(GetCodeCountMap(true,false,false))，以pairs遍历缺口，每个count拆成count条{type=code,count=1}给rewardContent；不同code展示顺序不保证固定。可选listListeners逐个AddActiveListener到Close。红按钮仅Close；绿按钮m_bFinishOrder=true再Close。OnCloseFinish先BaseWindow.OnCloseFinish；标记非真不做提交，有callback则优先执行callback，否则GetOrderModel(Slot).ContainsOrder(order)才FinishOrder。普通按钮未传callback/listListeners。此处不再CanDeliver、不验证仓库数量；“订单仍在”也不等于“材料足够”。取消不扣物。窗口期间数量变化可能导致后续部分扣除失败，不能凭空增加原版事务保证。

## 源码依据

- UI.Window.Board.UseInventoryItemConfirmWindow：[恢复源码](../../../../assets/order-evidence/UI.Window.Board.UseInventoryItemConfirmWindow.lua) · [原始指令](../../../../assets/order-evidence/UI.Window.Board.UseInventoryItemConfirmWindow.disassembly.txt)。对应：UseInventoryItemConfirmWindow:Init（恢复文本行4）；UseInventoryItemConfirmWindow:OnRedClick（恢复文本行30）；UseInventoryItemConfirmWindow:OnGreenClick（恢复文本行34）；UseInventoryItemConfirmWindow:OnCloseFinish（恢复文本行39）

- Board.View.Order.BaseOrderCell：[恢复源码](../../../../assets/order-evidence/Board.View.Order.BaseOrderCell.lua) · [原始指令](../../../../assets/order-evidence/Board.View.Order.BaseOrderCell.disassembly.txt)。对应：BaseOrderCell:Init（恢复文本行41）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

<div class="case-assets"><img src="../../../../../assets/cases/item-204.png" alt="棋子204" width="72" height="72"></div>

### 场景1：确认仓库补交

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。确认窗已重算缺204=1；关闭期间订单和物品不变，无专用关闭回调。

**按执行顺序代入：** OnGreen置确认标记并Close；OnCloseFinish确认真、ContainsOrder=true→FinishOrder；Gold100+8=108；扣棋盘203×2和仓库204×1。

**玩家看到的结果：** 确认后获得8金币，三件需求都被消耗，订单完成；能量仍10。
