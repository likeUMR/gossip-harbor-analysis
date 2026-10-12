# 价格触发、次数上限与刷新

`BundleEnergyConfigDataGroup` 暴露 `GetGroupLastDuration`、`GetRefreshDuration`、`GetBundleLastDuration`、`GetTriggerPrice`、`GetTriggerMaxNum` 和 `GetPopType`；模型提供 `Try2TriggerEnergyBundle`。

能量状态变化后检查 trigger price/余额条件，再检查 triggerCount<maxNum，建立礼包并设置持续时间；购买发 energy goods、计数+1；refresh duration 到期清理或重置。触发价格是资格门槛，不等于售价。方向和数值 runtime-pending。
