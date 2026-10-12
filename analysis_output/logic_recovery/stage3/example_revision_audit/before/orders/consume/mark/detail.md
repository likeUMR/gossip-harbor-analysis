# 缓存奖励与完成状态：具体算法与配置

BaseOrder.SetFinished：Table.IsEmpty(m_cacheRewards)时m_cacheRewards=GetRewards，然后m_state=Finished。不会用_SetState，不改变stateChange/time。首次尚未Finished时再次GetRewards可能重新读活动状态；MainBoardModel此前即时发奖快照与这次缓存不是同一个赋值。槽位模型之后还会SetFinished一次，非空缓存则复用；空缓存会继续调用GetRewards，而Finished订单读取空缓存复制。GetRewards Finished返回DeepCopy，防止外部直接改缓存。

## 源码依据

- Board.Model.Order.BaseOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.disassembly.txt)。对应：BaseOrder:SetFinished（恢复文本行130）；BaseOrder:GetRewards（恢复文本行157）

- Board.Model.Order.MainOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrder.disassembly.txt)。对应：MainOrder:GetRewards（恢复文本行136）

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)

- Board.Model.Order.SlotOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.disassembly.txt)


---

## 贯穿案例：203×2与204×1，使用仓库补交

无活动状态变化，奖励缓存仍为Gold8，状态改4，再开始扣物。

### 代入本页的值

m_cacheRewards=[Gold8]，m_state=4；不更新stateChangeTime；后续Slot.SetFinished不再重新计算非空缓存。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
