# 扣物飞行、奖励表现与顾客离开：具体算法与配置

MainBoardView._OnFinishOrder先重建layout并禁滚动，取旧订单cell；用message.Rewards或订单缓存copy，处理Buff/微笑表现，AddContiorderExtraReward修改表现数组；棋盘Removed映射pairs逐个_PlayRemoveOrderItemAnimation(index,0.5,2)。将相册奖励放delay，其它放other。DOTween等待0.5→插入Cooking动画→金币效果及AcquireRewardsInView(other,noDelay=true)；亲密度礼物加入delay并显HUD，delay非空再等0.3并View；再等0.5→宝箱表现→PlayLeaveAnimation→等待cell自定义时间或1秒→RemoveCell→开滚动→ButterflyDelayScroll→_StartPrompt。仓库稀疏映射pairs单独_PlayInventory2OrderItemAnimation(index,code,0.5,2)。这是调度顺序，动画辅助函数可能追加时长，不把0.5+0.3+0.5+1当统一真实总时长。

特殊完成_PlaySpecialOrderFinishAnimation参数1.4/2.6，回调打开SpecialOrderCompleteWindow；分支参数1.8/3，回调StartSpTimeline(EndTimeline)。模型SetSlot时间线标记先前已经写入。动画/展示不调用普通AcquireRewardsLogic重发金币，

## 源码依据

- Board.View.MainBoardView：[恢复源码](../../../../assets/order-evidence/Board.View.MainBoardView.lua) · [原始指令](../../../../assets/order-evidence/Board.View.MainBoardView.disassembly.txt)。对应：MainBoardView:_OnFinishSpecialOrder（恢复文本行803）；MainBoardView:_OnFinishBranchOrder（恢复文本行810）；MainBoardView:_OnFinishOrder（恢复文本行1712）

- Board.View.Order.BaseOrderAnimation：[恢复源码](../../../../assets/order-evidence/Board.View.Order.BaseOrderAnimation.lua) · [原始指令](../../../../assets/order-evidence/Board.View.Order.BaseOrderAnimation.disassembly.txt)


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：材料飞入后顾客离开

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。结算完成，Gold108；假设无额外表现奖励、无烹饪或宝箱，顾客离开自定义时长缺省。

**按执行顺序代入：** 棋盘键1/2和仓库键3各飞向对应需求；等待0.5→金币View8→等待0.5→Leave→缺省等待1→RemoveCell/开滚动；实际飞行辅助时长独立。

**玩家看到的结果：** 看到两件203和仓库204依次完成需求，8金币飞入后顾客离开；余额保持108，不会变116。
