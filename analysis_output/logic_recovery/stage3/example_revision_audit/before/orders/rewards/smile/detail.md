# 订单微笑分数与首轮提示：具体算法与配置

主游戏模式且GetAddSmileScoreBySlot>0，主盘读取两次该数→BI→OrderBoost.OnOrderFinished→order.SetOrderBoostFinish(smileNum)。smileNum==1、活动当前score==1且logicType Normal才triggerButterfly=true；提示在尾部才发。GetAddSmileScoreBySlot：非Started/curInfo=nil返0；TimedSlot返2，ExtraSlot返0，ContiSlot读Conti模型GetSmileCount；其他槽查order_slot/order_num/reward_num，finishSlot>=上限返0。OnOrderFinished再次要求Started/Main且GetAddOrderBoostScoreByOrder>0；curScore=min(old+add,MaxScore)，slot完成数+1，达上限触发ReviewRace.FinishRace和相关日志；可用cell播放微笑飞行；SaveMetaData→OrderBoostSmileAddScore。活动配置档位来自远端，不能填默认1。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:FinishOrder（恢复文本行1101）

- OrderBoost.Model.OrderBoostModel：[恢复源码](../../../../assets/order-evidence/OrderBoost.Model.OrderBoostModel.lua) · [原始指令](../../../../assets/order-evidence/OrderBoost.Model.OrderBoostModel.disassembly.txt)。对应：OrderBoostModel:OnOrderFinished（恢复文本行94）；OrderBoostModel:GetAddSmileScoreBySlot（恢复文本行697）


---

## 贯穿案例：203×2与204×1，使用仓库补交

本例微笑活动不生效，不改变分数，也不触发首轮提示。

### 代入本页的值

slot1、活动非Started→smile0；对照TimedSlot且Started/curInfo有效→槽分2，仍不满足smileNum==1首轮提示条件。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
