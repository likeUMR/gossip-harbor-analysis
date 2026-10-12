# 价格档位与奖励

`ShopIAPConfig`/`ShopIAPConfigCN` 提供购买 ID。当前快照可见全球 `gem-100、gem-265、gem-580、gem-1260、gem-3350、gem-7450`；中国变体为 `gem-100、gem-380、gem-880、gem-1650、gem-4200、gem-8250`。`IAPProductGlobal` 有多档 USD 价格，`IAPProductCN` 使用 CNY。

执行顺序：`purchaseId → IAP 商品记录 → 商店本地化价格 → 交易成功 → 钻石奖励`。商品记录缺失时拒绝购买，不能默认为 0 价。假设中国玩家购买 `gem-880`，商店返回 ¥68，成功后增加 880 钻；重复回调按交易号幂等。档位是 source-confirmed，实际商店价 runtime-pending。
