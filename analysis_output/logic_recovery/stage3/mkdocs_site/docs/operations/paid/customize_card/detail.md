# 卡牌配置、奖励内容与价格
`CustomizeCardBundle` 映射到 BundleCustomizeCardModel。卡牌内容、goods 数组和 purchaseId 分别读取；资格通过后形成奖励列表，再查询价格；缺配置时拒绝生成，不生成空卡牌。payload runtime-pending。
