# 付费项目批次交接记录

## 批次范围

本批按付费项目作为第一层玩家入口，第二层按固定/动态商品类型组织，第三层拆资格、候选、价格、次数和生命周期，第四层写配置字段、算法、状态变化和假设案例。

## 清单与证据

| 机制 | 主要来源 | 静态状态 | 运行时状态 |
|---|---|---|---|
| 常驻钻石包 | `ShopIAPConfig*`, `IAPProductGlobal/CN` | source-confirmed | 本地化商店价格 runtime-pending |
| 常驻商店 | `ShopSlotConfig`, `ShopDataModel`, `ShopModel` | source-confirmed | 随机槽位轨迹 runtime-pending |
| 每日特惠/闪购 | `ShopDailyDealsConfig*`, `ShopDataModel` | source-confirmed | 服务端覆盖 runtime-pending |
| 新手礼包 | `BundleConfig`, `BundleLocalConfigData` | source-confirmed | 账号分支 runtime-pending |
| 时间限时礼包 | `BundleServerConfigData`, `BundleManager` | 框架 source-confirmed | 实际 payload runtime-pending |
| 能量礼包 | `BundleServerConfigData` | 字段 source-confirmed | 触发方向与数值 runtime-pending |
| 订单/棋子礼包 | `BundleServerConfigData`, Bundle models | 框架 source-confirmed | 缺口到奖励映射 runtime-pending |
| 周期/链式礼包 | `BundleServerConfigData`, `BundleManager` | 框架 source-confirmed | 步骤 payload runtime-pending |
| 活动/个性化礼包 | `IAPProductGlobal/CN`, Bundle models | 商品 ID source-confirmed | 服务端分层 unavailable |
| 性价比 | `diamond_pricing_analysis.json` | 计算基准 source-confirmed | 玩家需求快照假设 |

## 当前环节状态

- 环节0 输入核验：已完成本地客户端和解包配置定位；服务端 payload 未取得。
- 环节1 范围清单：已建立本批机制清单，后续发现新 Bundle 类型需回填。
- 环节2 执行骨架：已写入各第一/二层父页。
- 环节3–4 逐逻辑分析与底层文档：本批已完成首轮静态规格和假设案例。
- 环节5 行为校验：静态推演可进行；原版运行与网络响应差分 unavailable。
- 环节6 四层说明：已写入网站导航和页面。
- 环节7–9：待补充逐礼包触发矩阵、截图和独立总验收。

## 关键未知

不能从客户端商品 ID 推断账号一定能看到该商品；不能把 `m_totalPay`/`m_payLevel` 的存在直接解释为推荐分层；不能把本地价格档位当成最终地区售价。所有这些边界在页面中保留为 runtime-pending 或 unavailable。
