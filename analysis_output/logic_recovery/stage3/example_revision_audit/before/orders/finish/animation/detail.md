# 扣物飞行、奖励表现与顾客离开：具体算法与配置

MainBoardView._OnFinishOrder先重建layout并禁滚动，取旧订单cell；用message.Rewards或订单缓存copy，处理Buff/微笑表现，AddContiorderExtraReward修改表现数组；棋盘Removed映射pairs逐个_PlayRemoveOrderItemAnimation(index,0.5,2)。将相册奖励放delay，其它放other。DOTween等待0.5→插入Cooking动画→金币效果及AcquireRewardsInView(other,noDelay=true)；亲密度礼物加入delay并显HUD，delay非空再等0.3并View；再等0.5→宝箱表现→PlayLeaveAnimation→等待cell自定义时间或1秒→RemoveCell→开滚动→ButterflyDelayScroll→_StartPrompt。仓库稀疏映射pairs单独_PlayInventory2OrderItemAnimation(index,code,0.5,2)。这是调度顺序，动画辅助函数可能追加时长，不把0.5+0.3+0.5+1当统一真实总时长。

特殊完成_PlaySpecialOrderFinishAnimation参数1.4/2.6，回调打开SpecialOrderCompleteWindow；分支参数1.8/3，回调StartSpTimeline(EndTimeline)。模型SetSlot时间线标记先前已经写入。动画/展示不调用普通AcquireRewardsLogic重发金币，

## 源码依据

- Board.View.MainBoardView：[恢复源码](../../../../assets/order-evidence/Board.View.MainBoardView.lua) · [原始指令](../../../../assets/order-evidence/Board.View.MainBoardView.disassembly.txt)。对应：MainBoardView:_OnFinishSpecialOrder（恢复文本行803）；MainBoardView:_OnFinishBranchOrder（恢复文本行810）；MainBoardView:_OnFinishOrder（恢复文本行1712）

- Board.View.Order.BaseOrderAnimation：[恢复源码](../../../../assets/order-evidence/Board.View.Order.BaseOrderAnimation.lua) · [原始指令](../../../../assets/order-evidence/Board.View.Order.BaseOrderAnimation.disassembly.txt)


---

## 贯穿案例：203×2与204×1，使用仓库补交

模型已扣两件203与仓库204，视图按需求索引播放三件飞入，并展示8金币，顾客离开后恢复滚动。

### 代入本页的值

模型余额108不会因View再变116；RemovedFromInventory[3]正确飞向第3需求，不因稀疏数组而遗漏。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
