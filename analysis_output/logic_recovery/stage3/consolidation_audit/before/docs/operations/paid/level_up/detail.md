# 等级触发、弹窗与关闭
`BundleLevelUpGiftModel` 的关键函数为 TriggerGiftData、BuyTriggerGiftData、GetTriggerGiftData、TryCloseGift、CanPopup、UpdatePerSecond。等级/事件更新生成 m_curTriggerData；CanPopup 通过才展示 purchaseId、descPrice、duration；购买、关闭或到期分别走不同清理路径。TestForceTriggerGift 仅是测试入口。
