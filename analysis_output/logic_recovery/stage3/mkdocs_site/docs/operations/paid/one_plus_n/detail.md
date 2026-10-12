# 周期、弹窗上限与多步奖励
`BundleOnePlusNGroupData` 提供 weeks、popupsMax、buyTimes、cooldownTime、time、descPrice、giftID；模型提供 TryTriggerGift、CanPopup、Buy、TryReceiveRewards。先检查触发完成，再检查冷却、购买次数和弹窗次数；购买成功写完成步骤，奖励领取单独结算。
