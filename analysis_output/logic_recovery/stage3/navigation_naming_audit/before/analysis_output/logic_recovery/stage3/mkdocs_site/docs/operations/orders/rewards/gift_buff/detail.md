# 亲密度礼物与Buff奖励：具体算法与配置

giftRewards~=nil且CharacterIntimacy.IsOpen才AcquireRewardsLogic(Give,FinishOrder)，未显式传gameMode/Type2。order.GetBuffRewards存在才调用，结果非nil发同类Logic。GetGiftRewards读m_giftRewards；_AddGiftRewardInfo在新订单创建后已有gift时复用，无则CharacterIntimacy.AddGiftRewardInfo，数据库另存/还原。MainOrder.GetBuffRewards交BuffManager.GetBuffRewards(self)，不同Buff的候选与档位不能凭订单Price推导。SetFinished稍后重新读GetRewards的缓存路径，与这两组独立发奖位置区分。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:FinishOrder（恢复文本行1101）

- Board.Model.Order.MainOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrder.disassembly.txt)。对应：MainOrder:GetGiftRewards（恢复文本行278）；MainOrder:GetBuffRewards（恢复文本行282）

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)。对应：MainOrderModel:FinishOrder（恢复文本行560）；MainOrderModel:_AddGiftRewardInfo（恢复文本行862）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：礼物和Buff分别发放

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。假设亲密度已开放、giftRewards=[Gold3]，GetBuffRewards返回[Energy5]；基础Gold8已发完。

**按执行顺序代入：** 初Gold100/Energy10；基础后108/10；gift非nil且IsOpen=true→Gold111；BuffRewards非nil→Energy15。

**玩家看到的结果：** 总共收到11金币和5能量，余额111、能量15；其中礼物3金币与Buff5能量是额外两次结算。
