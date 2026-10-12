# 状态刷新与同步：具体算法与配置

普通FinishOrder尾部UpdateOrderState→triggerButterfly真派SmileOrderDeliver_1→SyncModel.CheckMoreUpload(nil,nil,requirements)→self.event.Call(FinishOrder,{Order,RemoveItemInfo,Rewards,mapDelayRewards})。OrderFinished{order}已在Slot.FinishOrder补位后派发。两者不同事件与payload不能合并；Sync检查不是服务器确认交付响应。本地主流程没有等待网络成功才发局部消息，网络队列/合并与存档协议另属同步模型。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:FinishOrder（恢复文本行1101）

- Board.Model.Order.SlotOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.disassembly.txt)。对应：SlotOrderModel:FinishOrder（恢复文本行65）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：首轮提示与完成消息

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。已完成发奖和扣物，补位返回；本例首个普通微笑资格true，奖励快照Gold8，扣物来自棋盘索引1/2和仓库索引3。

**按执行顺序代入：** OrderFinished→UpdateOrderState→SmileOrderDeliver_1→CheckMoreUpload(nil,nil,[203,203,204])→局部FinishOrder；payload Gold8/RemovedBoard1,2/Inventory3。

## `OrderFinished` 消费者闭包

全局事件的作用是“完成后的业务入账与状态推进”，不是局部棋盘动画的别名。已从本地恢复源码核实的直接消费者如下：

| 消费者 | 直接处理 | 二次事件/持久化边界 |
| --- | --- | --- |
| Adventure、Multiboards、PureBoard | 按订单生成活动物，展开数量、写活动缓存并记录获取日志 | 分别派 `AddAdventureActivityItem`、`AddMultiboardsActivityItem`、`AddOrderFinishItem` |
| Dig | 直接执行 `AcquireRewardsLogic` | 派 `AddOrderFinishItem`，奖励逻辑仍受活动资格和配置约束 |
| Farmboard、Puzzle、ScoreRace | 增加活动 Token/拼图 Token/竞速分并保存 | 分别派 `CollectFarmboardToken`、`CollectPuzzleToken`、`CollectScoreRaceToken`；ScoreRace 按价格/难度换算 |
| Break | 从订单已缓存奖励中取活动物 | 只派棋盘飞行动画，不再次发同一奖励 |
| CookingFrenzy、TriggerBoost | 消费订单分数缓存并清空 | 延迟调用视图领取/表现；缓存清空后不能重复消费 |
| BundleChopGift | 累加 `curToken`、`waitFlyScore`、`openWindowScore` 并保存 metadata | 跨礼包档位记录轮次日志，表现层读取等待飞行分 |
| Butterfly | 完成当前槽后推进下一订单或结算最终奖励 | 非末阶段递增 index；末阶段重置并在延迟后派成功事件 |
| TimedOrder、TutorialOrder | 删除计时奖励字段，或把教程槽推进到下一 Ready 状态 | 这些是状态清理/推进，不是普通金币奖励 |
| TaskEventProgressGain、Pass | 所有订单 `OrderFinish +1`；额外顾客再记录 `RacoonFinish`；Pass 推进 customer | 任务的条件、目标和奖励仍由注册模型与远端配置决定 |
| ShopData、Shop、GooglePgs、SDKHelper | 特殊订单商店刷新、Flash Sale 刷新、平台成就统计、一次行为上传 | 这些消费者不改变订单材料扣除结果 |

这些处理可能与局部 `FinishOrder` 同帧发生，但事件 payload 不同，也没有源码保证所有活动的固定注册顺序。已确认的状态链是：先完成业务事件和补位，再做 `UpdateOrderState`、微笑提示、同步检查，最后把 `FinishOrder` 的 `Order/RemoveItemInfo/Rewards/mapDelayRewards` 交给视图。网络同步检查不是服务器成功回执。

## `MainOrderCreated` 的创建时序

`MainOrderModel:_TryCreateOrder` 在返回新单前派 `MainOrderCreated`；此时订单尚未经过 `_DBAddOrder`，也尚未写入 `m_orders[slot]`。`ShopDataModel` 只刷新特殊订单数据，亲密度教程消费者会在无强教程、无时间线、窗口关闭且主场景的条件下启动随机亲密度单教程，`TutorialStartPopupHelper` 只设置弹窗检查标记。实现时不能在该事件消费者中假设“新单已经存在于订单集合”。

**玩家看到的结果：** 金币108、三件物品已扣；玩家看到首轮微笑提示，随后进入交付表现，同步检查不会再发8金币。
