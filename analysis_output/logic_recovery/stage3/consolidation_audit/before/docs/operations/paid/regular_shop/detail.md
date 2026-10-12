# 商品候选、权重与购买次数

本页是 `PAID-SHOP-001` 至 `PAID-SHOP-006` 的第四层规格。目标是让复刻实现能够从配置和玩家状态推导“为什么这个槽位出现、价格是多少、还能买几次”。

## 配置字段

| 字段 | 来源 | 类型/单位 | 作用 |
|---|---|---|---|
| `ShopWeight` | `ItemProperty` / `ShopSlotConfig` | 非负数 | 候选或槽位抽取权重；小于等于 0 的闪购记录被过滤 |
| `Slot` | `ItemProperty` | 整数数组 | 闪购配置归属槽位 |
| `Type` | `ItemProperty` | 枚举/字符串 | 闪购类型到价格表的键 |
| `Price` | `ItemProperty` | 钻石数 | 写入 `m_mapFlashSaleItemType2Price` |
| `costCount` | DailyDeals/商品记录 | 整数 | 当前购买成本 |
| `costIncreasement` | DailyDeals | 整数 | 同 itemCode 后续价格递增量 |
| `weight`/`weightNoAlbum` | DailyDeals | 权重 | 有 Album 缓存资格时可将无 Album 权重置零 |
| `ShopCount` | 商品记录 | 次数 | 当前记录可购买次数；缺失值不能当无限次 |

来源：`Model/Shop/ShopDataModel.luac.txt` 的 `_InitDailyDealsDatas`、`_InitFlashSaleConfigDatas`、`GetFlashSalePrice`、`GetDailyDealsMinCost`；`Data/Config/ShopSlotConfig*.luac.txt`。

## 装载顺序

1. `LoadFileConfig` 先调用 `_InitIAPConfigDatas`、`_InitDailyDealsDatas`、`_InitFlashSaleConfigDatas`。
2. `_InitDailyDealsDatas` 深拷贝 `LocalConfigKey.ShopDailyDeals`。每条记录先检查 `ad==1`：若是且尚未有广告商品，则写入 `m_dailyDealsAdItemCode`。
3. 对同一 `itemCode`，记录 `costIncreasement`；记录 `costCount` 时保留最小值到 `m_mapDailyDealsMinCostCount`。
4. 查询 `AlbumActivityModel:IsCacheProperty(itemCode)`。若为缓存型物品，当前记录的 `weightNoAlbum` 被写成 0；否则等于原 `weight`。
5. `_InitFlashSaleConfigDatas` 遍历 `ItemProperty`，跳过 `ShopWeight <= 0` 或没有 `Slot` 的记录；对每个 Slot 建立配置数组，对每个 `CustomChain` 建立链数组，并把 `Type → Price` 写入价格表。

## 候选与展示算法

常驻槽位的候选集合必须先经过解锁、库存/次数和活动条件，再使用 ChainId 对应的槽位权重抽取。抽取结果只决定展示记录；不会改变 `costCount` 或 `ShopCount`。闪购则先按 Slot 分组，再使用 `_GetSingleItemDataForFlashSale` / `_GetSingleRandomItemDataForFlashSale` 做物品过滤和价格查询。

```text
valid = unlock(item) && remainingCount(item) > 0 && activityAllows(item)
if valid:
    candidateWeight = ShopWeight (或 weightNoAlbum)
slot = weightedChoice(candidateWeight)
price = flashSalePrice[Type] 或 costCount
```

以上伪代码只表达顺序；随机接口、遍历顺序和是否放回仍需从完整调用者和运行时确认，状态为 runtime-pending。

## 购买与刷新状态

购买前检查货币余额和 `ShopCount`。成功路径必须按“扣除 → 发放 → 次数减少 → 保存/通知”的顺序记录；任一步失败不能提前扣次数。手动刷新费用由 `GetRefreshGemCost` 读取，当前静态分析结果为 20 钻；广告刷新走广告回调，不应复用手动扣钻分支。

日界或服务端刷新可以重建候选集合，但只能按明确的 refresh 字段清理次数。不能因为重新生成槽位就重置购买历史。

## 完整假设案例

假设 ChainId=3，某槽位候选 A/B/C 的权重为 5/3/2；A 已解锁、`ShopCount=2`、`costCount=40`，B 未解锁，C 为 Album 缓存型且 `weightNoAlbum=0`。有效池只有 A，槽位确定展示 A。玩家余额 50，点击购买：余额 50→10，获得 A 的 goods，`ShopCount 2→1`，写购买记录并派发商店更新事件。再次刷新不会把次数恢复为 2；只有配置定义的周期刷新才会重置。

## 证据状态

- 配置字段读取和分支：source-confirmed。
- 20 钻刷新费用：静态常量/调用结果 source-confirmed，实际账号覆盖 runtime-pending。
- 完整候选随机轨迹、服务端活动过滤、原版状态回放：runtime-pending / unavailable。
