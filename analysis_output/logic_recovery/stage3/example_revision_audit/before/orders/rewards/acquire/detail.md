# 奖励落账与棋子进入缓存：具体算法与配置

AcquireRewardsLogic空表return；单记录无[1]则包装数组，逐项ConvertDynamicReward，再SplitRewards按GetRewardCategoryType分组。_AcquireRewardsLogic取RewardHandlerManager.GetAllHandlers，以pairs遍历存在的handler，组非空才LogicHandle，参数source/scene/targetGameMode/cacheItemType/boardType。不同类别处理次序无保证，同组ipairs保留顺序。PropertyRewardCategoryHandler交PropertyDataManager.Acquire；ItemRewardCategoryHandler把每条count展开code数组，BoardModelHelper.GetModelByGameMode→CacheItems，逐条日志。普通FinishOrder首次调用Give/FinishOrder/gameMode/Type2。这里只有Logic，不调用AcquireRewardsInView；视图尾部才演出，不能再落账一次。各奖励子类别和PropertyDataManager真实持久化仍有独立实现边界，不能据此假设网络事务。

## 源码依据

- Model.UserData.RewardApi：[恢复源码](../../../../assets/order-evidence/Model.UserData.RewardApi.lua) · [原始指令](../../../../assets/order-evidence/Model.UserData.RewardApi.disassembly.txt)。对应：RewardApi.SplitRewards（恢复文本行48）；RewardApi.AcquireRewardsLogic（恢复文本行74）；RewardApi._AcquireRewardsLogic（恢复文本行92）

- Model.RewardHandler.RewardCategoryHandler.ItemRewardCategoryHandler：[恢复源码](../../../../assets/order-evidence/Model.RewardHandler.RewardCategoryHandler.ItemRewardCategoryHandler.lua) · [原始指令](../../../../assets/order-evidence/Model.RewardHandler.RewardCategoryHandler.ItemRewardCategoryHandler.disassembly.txt)。对应：ItemRewardCategoryHandler:LogicHandle（恢复文本行9）

- Model.RewardHandler.RewardCategoryHandler.PropertyRewardCategoryHandler：[恢复源码](../../../../assets/order-evidence/Model.RewardHandler.RewardCategoryHandler.PropertyRewardCategoryHandler.lua) · [原始指令](../../../../assets/order-evidence/Model.RewardHandler.RewardCategoryHandler.PropertyRewardCategoryHandler.disassembly.txt)。对应：PropertyRewardCategoryHandler:LogicHandle（恢复文本行103）


---

## 贯穿案例：203×2与204×1，使用仓库补交

本例Gold8交资源处理器，余额增至108；不生成棋盘金币棋子。

### 代入本页的值

category=Property；count8；棋盘203/204此时仍未删除。对照Item code204×2→缓存数组[204,204]，并非调用GenerateItem两次。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
