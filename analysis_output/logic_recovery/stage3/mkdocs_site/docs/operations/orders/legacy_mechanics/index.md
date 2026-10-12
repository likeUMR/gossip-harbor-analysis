# 订单机制：历史分析完整归档

本页把旧版订单分析接回“订单提交”统一入口。现有订单拆页解释源码流程和本地配置；本页补回旧版的订单类型定量、理论体力效率、TimedOrder、MonthPay 案例、Baseline 补位和 22 类进度订单汇总。

## 覆盖范围

| 历史章节 | 当前统一位置 | 证据等级 |
| --- | --- | --- |
| Fixed 16 个、Special 6 个、共 22 个进度订单 | [订单创建与配置选择](../creation/index.md)、[特殊与分支订单](../special/index.md) | 旧版配置汇总；以当前 `OrderItemConfig` 快照复核 |
| 订单类型定位、CD、金币/体力理论比 | [奖励结算](../rewards/index.md) | 理论体力按 `2^(L-1)`，不是玩家真实净消耗 |
| Baseline 触发、14 个指定棋子、库存清理单 | [Baseline/固定回归](../refill/fixed_return/index.md) | 源码流程与历史数字例分开记录 |
| TimedOrder（浣熊出没）触发、占比和远端缺口 | [特殊订单](../special/index.md)、[订单补位](../refill/index.md) | 本地证据不含完整服务端活动 payload |
| Random3 + MonthPay Filter 案例、Player/DiffSum/MonthPay | [随机抽取](../refill/draw/index.md) | MonthPay 数值为机制构造案例，不是当前账号事实 |
| P1/P2/P3 候选、无匹配 Filter 行为 | [候选筛选](../refill/candidates/index.md)、[动态订单](../refill/dynamic/index.md) | 保留旧版边界和失败分支 |
| Special、Baseline、TimedOrder、亲密度订单完整推演 | [订单分流](../dispatch/index.md)、[剧情与好感度](../intimacy/index.md) | 逐类案例归档 |
| Slot 与 Type、补位循环和扫描入口 | [补位循环](../refill/loop/index.md)、[完成、补位与同步](../finish/index.md) | 扫描与生成的区别明确保留 |
| 随机订单生成字段、固定订单解锁和数据来源 | [订单创建](../creation/index.md)、[保存与重载](../refill/save/index.md) | 本地字段可追踪，远端条件单列 |

## 统一推演框架

1. 事件进入后先判断活动资格，再判断槽位资格。
2. 读取 Filter、需求池和重复抑制状态；候选为空时进入该类型的失败或兜底路径。
3. 订单成功落位后写入槽位、计时、历史和同步状态；补位扫描会按轮次重试，但一次扫描不等于无限生成。
4. 理论效率只用于比较订单类型，不替代交付时真实的棋盘/仓库扣除和能量消耗。

## 关键边界

- MonthPay 章节是按照代码机制构造的演示案例，当前导出的 `OrderRandomConfig.json` 不含该字段，不能写成真实玩家配置。
- TimedOrder 的玩家表现和远端触发窗口仍需要服务端或真实账号回放确认。
- 旧版“金币/体力比”按等级理论体力计算，不能直接推导付费价值或实际完成时长。

## 原始交互分析

[打开完整的历史订单机制 HTML](../../../assets/reference-analysis/order-mechanics.html){:target="_blank"}

附件原样保留 6 个章节、18 张表、所有定量例、候选分布和失败边界。
