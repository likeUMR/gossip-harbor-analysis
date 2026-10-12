# 等级触发、持续时间与一次性购买

`BundleConfig` 中 Global `starter_bundle_1` 的 goods 为 `gem-510、energy-200、3601-2`，条件 `Level-3`，购买 1 次，持续 172800 秒；非 Global 分支有 `cookienewuser12`，goods 为 `gem-168、energy-208、3601-1`。

等级小于 3、开关关闭、已购买或超过触发时间+172800 时不生成；否则建立实例并写过期时间。购买成功发奖、`buyCount+1` 并清理实例。假设玩家 3 级首次进入商店，获得 510 钻、200 能量和 2 个 3601；48 小时后资格失效。配置分支 source-confirmed，账号分组 runtime-pending。
