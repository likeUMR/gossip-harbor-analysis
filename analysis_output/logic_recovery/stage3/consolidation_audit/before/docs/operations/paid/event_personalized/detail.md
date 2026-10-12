# 服务端投放、分层与未知边界

`IAPProductGlobal/CN` 可见 `event_bundle_1..18`、`shop_daily_bundle_*`、`spoffercode*`、`rise*`、`playpoint*`、`wheelpack*`、`streak*` 等 ID。商品 ID 只能证明客户端能识别，不能证明账号一定收到。

服务端活动/分组下发 purchaseId 候选，客户端再按本地资格、历史、时间和同组过滤；缺 payload 时保留不可用状态。IAP 模型维护 `m_totalPay`/`m_payLevel`，但当前不能证明其直接决定礼包推荐，标记 runtime-pending。
