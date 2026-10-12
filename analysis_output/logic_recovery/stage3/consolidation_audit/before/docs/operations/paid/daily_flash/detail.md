# 日界刷新、广告与动态价格

`ShopDailyDealsConfig` 可见 3101=25 钻、2901=10 钻且带广告字段、`ShopNewChest_1`=0 钻；随机变体有降级片 30、升级片 150、`pack_common_3/4/5`=50/100/200 钻。模型保存广告商品、递增费用和同 itemCode 的最低价格。

执行顺序：服务器时间 → 日界/闪购到期 → 清理旧记录 → 装载候选 → 广告资格/动态价格 → 购买或广告回调 → 写记录。`GemDiscount`、`PackShopSale` 和 StartedShopDiscountActivity 是覆盖入口，payload runtime-pending。广告失败不应发 goods。
