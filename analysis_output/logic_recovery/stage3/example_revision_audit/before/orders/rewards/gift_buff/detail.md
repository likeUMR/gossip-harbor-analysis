# 亲密度礼物与Buff奖励：具体算法与配置

giftRewards~=nil且CharacterIntimacy.IsOpen才AcquireRewardsLogic(Give,FinishOrder)，未显式传gameMode/Type2。order.GetBuffRewards存在才调用，结果非nil发同类Logic。GetGiftRewards读m_giftRewards；_AddGiftRewardInfo在新订单创建后已有gift时复用，无则CharacterIntimacy.AddGiftRewardInfo，数据库另存/还原。MainOrder.GetBuffRewards交BuffManager.GetBuffRewards(self)，不同Buff的候选与档位不能凭订单Price推导。SetFinished稍后重新读GetRewards的缓存路径，与这两组独立发奖位置区分。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:FinishOrder（恢复文本行1101）

- Board.Model.Order.MainOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrder.disassembly.txt)。对应：MainOrder:GetGiftRewards（恢复文本行278）；MainOrder:GetBuffRewards（恢复文本行282）

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)。对应：MainOrderModel:FinishOrder（恢复文本行560）；MainOrderModel:_AddGiftRewardInfo（恢复文本行862）


---

## 贯穿案例：203×2与204×1，使用仓库补交

本例礼物为空且无Buff额外奖励，两段跳过。

### 代入本页的值

gift=nil，BuffRewards=nil；Gold8不被这两段重复发放。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
