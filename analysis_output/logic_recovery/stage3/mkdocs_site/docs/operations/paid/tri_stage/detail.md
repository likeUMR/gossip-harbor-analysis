# 阶段触发、商品属性与购买索引
`BundleTristageGiftModel` 保存当前触发数据和 buyNum/buyIndex，提供 TryTriigerGift、GetCurTriggerDataByGoodsPropertyType、TryPopupWindowByGoodsPropertyType、Buy。触发后按 goods property type 选择当前阶段，检查索引和窗口，购买成功推进索引；属性筛选不自动代表额外随机。
