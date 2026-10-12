# 微笑进度：具体算法与配置

主游戏模式且GetAddSmileScoreBySlot>0，主盘读取两次该数→BI→OrderBoost.OnOrderFinished→order.SetOrderBoostFinish(smileNum)。smileNum==1、活动当前score==1且logicType Normal才triggerButterfly=true；提示在尾部才发。GetAddSmileScoreBySlot：非Started/curInfo=nil返0；TimedSlot返2，ExtraSlot返0，ContiSlot读Conti模型GetSmileCount；其他槽查order_slot/order_num/reward_num，finishSlot>=上限返0。OnOrderFinished再次要求Started/Main且GetAddOrderBoostScoreByOrder>0；curScore=min(old+add,MaxScore)，slot完成数+1，达上限触发ReviewRace.FinishRace和相关日志；可用cell播放微笑飞行；SaveMetaData→OrderBoostSmileAddScore。活动配置档位来自远端，不能填默认1。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:FinishOrder（恢复文本行1101）

- OrderBoost.Model.OrderBoostModel：[恢复源码](../../../../assets/order-evidence/OrderBoost.Model.OrderBoostModel.lua) · [原始指令](../../../../assets/order-evidence/OrderBoost.Model.OrderBoostModel.disassembly.txt)。对应：OrderBoostModel:OnOrderFinished（恢复文本行94）；OrderBoostModel:GetAddSmileScoreBySlot（恢复文本行697）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：首个普通微笑订单

**完整输入（演示设定）：** 主游戏普通槽1；假设OrderBoost Started/curInfo有效，档order_slot1/order_num5/reward_num1，槽完成数0，score0、Max10、logicType Normal。

**按执行顺序代入：** smileNum1；OnOrderFinished加1→score=min(0+1,10)=1、slotCount0→1；保存并派SmileAdd；1==smileNum且score1且Normal→triggerButterfly=true。

**玩家看到的结果：** 微笑进度变1分，本槽记一次完成；正常交付结算完才出现首个微笑相关提示。
