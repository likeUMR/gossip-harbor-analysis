# 订单类型判断：具体算法与配置

MainBoardModel.FinishOrder：innerType==MainOrderType.Special(5)则_FinishSpecialOrder并return；elseif Branch(7)则_FinishBranchOrder并return；其余继续普通链。MainOrder.GetType把Fixed内部0映为OrderType.Fixed1，把5/7映为OrderType.Special3，其余映Random2。普通FinishOrder本身没有ContainsOrder或CanDeliver的前置保护；不能把后面槽位ContainsOrder当成发奖前的校验。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:FinishOrder（恢复文本行1101）

- Board.Model.Order.MainOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrder.disassembly.txt)。对应：MainOrder:GetType（恢复文本行39）

- Board.Model.Order.MainOrderDefinition：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderDefinition.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderDefinition.disassembly.txt)


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：分流决定执行链

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。对照另两场景：内部类型Special与Branch，各采用下面对应任务的完整输入。

**按执行顺序代入：** Normal→非Special/Branch→普通链：价格8、难度9；Special→_FinishSpecialOrder后return；Branch→_FinishBranchOrder后return。

**玩家看到的结果：** 普通单领8金币并扣三件需求；特殊与分支单各走专用清链和奖励，不再叠加普通单8金币。
