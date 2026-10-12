# 奖励落账与棋子进入缓存：具体算法与配置

AcquireRewardsLogic空表return；单记录无[1]则包装数组，逐项ConvertDynamicReward，再SplitRewards按GetRewardCategoryType分组。_AcquireRewardsLogic取RewardHandlerManager.GetAllHandlers，以pairs遍历存在的handler，组非空才LogicHandle，参数source/scene/targetGameMode/cacheItemType/boardType。不同类别处理次序无保证，同组ipairs保留顺序。PropertyRewardCategoryHandler交PropertyDataManager.Acquire；ItemRewardCategoryHandler把每条count展开code数组，BoardModelHelper.GetModelByGameMode→CacheItems，逐条日志。普通FinishOrder首次调用Give/FinishOrder/gameMode/Type2。这里只有Logic，不调用AcquireRewardsInView；视图尾部才演出，不能再落账一次。各奖励子类别和PropertyDataManager真实持久化仍有独立实现边界，不能据此假设网络事务。

## 源码依据

- Model.UserData.RewardApi：[恢复源码](../../../../assets/order-evidence/Model.UserData.RewardApi.lua) · [原始指令](../../../../assets/order-evidence/Model.UserData.RewardApi.disassembly.txt)。对应：RewardApi.SplitRewards（恢复文本行48）；RewardApi.AcquireRewardsLogic（恢复文本行74）；RewardApi._AcquireRewardsLogic（恢复文本行92）

- Model.RewardHandler.RewardCategoryHandler.ItemRewardCategoryHandler：[恢复源码](../../../../assets/order-evidence/Model.RewardHandler.RewardCategoryHandler.ItemRewardCategoryHandler.lua) · [原始指令](../../../../assets/order-evidence/Model.RewardHandler.RewardCategoryHandler.ItemRewardCategoryHandler.disassembly.txt)。对应：ItemRewardCategoryHandler:LogicHandle（恢复文本行9）

- Model.RewardHandler.RewardCategoryHandler.PropertyRewardCategoryHandler：[恢复源码](../../../../assets/order-evidence/Model.RewardHandler.RewardCategoryHandler.PropertyRewardCategoryHandler.lua) · [原始指令](../../../../assets/order-evidence/Model.RewardHandler.RewardCategoryHandler.PropertyRewardCategoryHandler.disassembly.txt)。对应：PropertyRewardCategoryHandler:LogicHandle（恢复文本行103）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：货币入账与棋子入缓存

**完整输入（演示设定）：** 假设逻辑奖励[Gold8,Item204×2]，Gold100，缓存原来空，目标主棋盘、Type2。

**按执行顺序代入：** Property处理Gold8→108；Item204 count2展开[204,204]→CacheItems；不同类别pairs先后不保证，最终状态相同。

**玩家看到的结果：** 金币余额108，缓存增加两件204；棋盘不会凭这一步直接多两件204。
