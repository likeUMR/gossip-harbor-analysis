# 订单完成标记：具体算法与配置

BaseOrder.SetFinished：Table.IsEmpty(m_cacheRewards)时m_cacheRewards=GetRewards，然后m_state=Finished。不会用_SetState，不改变stateChange/time。首次尚未Finished时再次GetRewards可能重新读活动状态；MainBoardModel此前即时发奖快照与这次缓存不是同一个赋值。槽位模型之后还会SetFinished一次，非空缓存则复用；空缓存会继续调用GetRewards，而Finished订单读取空缓存复制。GetRewards Finished返回DeepCopy，防止外部直接改缓存。

## 源码依据

- Board.Model.Order.BaseOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.disassembly.txt)。对应：BaseOrder:SetFinished（恢复文本行130）；BaseOrder:GetRewards（恢复文本行157）

- Board.Model.Order.MainOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrder.disassembly.txt)。对应：MainOrder:GetRewards（恢复文本行136）

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)

- Board.Model.Order.SlotOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.disassembly.txt)


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：完成后固定奖励读取

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。基础奖励已发，活动读取结果稳定为Gold8，缓存尚空。

**按执行顺序代入：** cache空→GetRewards=[Gold8]存入；state→Finished4；后续Slot.SetFinished复用非空缓存；读取返回DeepCopy。

**玩家看到的结果：** 订单显示完成，之后读到的仍是本次8金币奖励；此步不再发8金币，余额保持108。
