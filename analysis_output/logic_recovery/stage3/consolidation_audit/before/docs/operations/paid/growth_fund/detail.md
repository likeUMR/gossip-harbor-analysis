# 等级奖励、购买与领取资格
`GrowthFundModel` 提供 OnLevelUp、IsGrowthFundActive、Buy、CanAcquireReward、GetStepCount、GetLevelCondition、GetStepRewards 和 GetPurchaseID。未购买只能展示入口；购买成功标记 GrowthFundPaid；升级时逐档检查等级条件，满足且未领取才写 acquiredRewards。等级和奖励表 runtime-pending。
