# 付费系统执行骨架（环节 2 预审）

## A. 常驻 IAP 商品

1. `ShopDataModel:LoadFileConfig` 触发 `_InitIAPConfigDatas`。
2. 从 `LocalConfigKey.ShopIAP` 读取记录，逐条把 `goods` 字符串解析为货币数组，按 `type` 放入 `m_mapIAPDatas`。
3. IAP 模型装载地区商品表，并在运行时用商店 `localizedPrice` 覆盖显示价格。
4. 商品点击进入支付入口；成功后由奖励/交易回调发放 goods，恢复购买走单独回调。

## B. 常驻商店、每日特惠与闪购

1. 初始化 IAP、DailyDeals、FlashSale 三类本地配置。
2. DailyDeals 记录按 `itemCode` 建索引，同时提取广告商品、费用递增和最低费用；缓存型物品把 `weightNoAlbum` 置零。
3. FlashSale 过滤 `ShopWeight <= 0` 或无 Slot 的记录，按 Slot 建候选表，按 CustomChain 建链配置，按 Type 保存价格。
4. 商店刷新/日界事件重新计算有效候选；槽位生成使用 ChainId 权重，购买扣价、发 goods、扣次数。
5. 服务端活动字段可覆盖价格或候选，但覆盖来源未取得时不能填假值。

## C. 通用礼包管理

1. `BundleManager:Init` 注册 BundleDataTable 和 BundleMetaDataTable，建立 15 类模型工厂。
2. 登录/同步完成后，各模型读取自己的组配置和存档字段。
3. 每秒更新推进过期、冷却和周期；事件入口尝试触发对应模型。
4. `GetActiveGroupDatas` → `IsBundleDataValid` → `GetValidBundleIds` 形成当前可见集合；过期和次数耗尽在此边界被剔除。
5. UI 层读取 bundleId、purchaseId、goods、discountTag、bundleUIType、descPrice；展示字段不等于支付金额。
6. 统一购买入口成功后写 leftCount/购买记录；模型专属回调推进阶段或发放奖励；恢复购买重新结算未完成到账。

## D. 动态礼包的共同分支

- 等级：Starter、LevelUp、GrowthFund。
- 能量：EnergyBundle，读取 triggerPrice、triggerMaxNum、refreshDuration。
- 订单：OrderItemBundle，读取 itemLevel、triggerItem、priority、group/model trigger interval。
- 周期：Weekly/NewWeekly，读取星期窗口和持续时间。
- 链式/多阶段：Chain、TriStage、OnePlusN、OnePlusFour，读取 step/index/buy count/cooldown。
- 活动：服务端候选先进入客户端，再接受本地资格和历史过滤。

## 预审结论

第二层必须按以上实际类型建立；“推荐”“展示”“折扣”不能成为替代真实执行阶段的独立目录。每个类型的第三层要解释资格→候选→展示→购买/领取→持久化；第四层要核对具体模型函数、字段和配置记录。当前骨架中服务端候选、完整奖励 payload 和原版回放仍为未闭合项。
