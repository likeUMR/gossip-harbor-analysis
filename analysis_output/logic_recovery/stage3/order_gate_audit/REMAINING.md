# 尚未放行项

## 已取得代码，仍可继续分析

1. 按稳定标识核销原型、函数与分支，逐项区分相关/不相关并给理由。当前整模块候选账本为独立发现起点，不是全部已审阅的分母。
2. OrderFinished、MainOrderCreated、ChestCustomerOrderFinish、SmileOrderDeliver_1、OrderStateChanged及局部FinishOrder的全部注册与动态消费者、再派发、任务/活动状态变化。注册行只发现候选，不能宣称34条监听已闭合。
3. MainOrder.GetRewards全部活动公式和实际奖励handler的动态分派，PropertyDataManager、BuffManager、亲密度礼物及额外领取；当前提供订单直接追加顺序与若干专用规则，未把所有活动内部实现都当作已完成。
4. GetDynamicMaxLevel、普通候选预选/项数、Lucky库存约束、全部随机创建器、头像/礼物、FileReplace装载与缓存，逐路径执行验证及异常数据边界。当前测试未覆盖所有这些算法组合。
5. 组件RemoveItem、仓库删除、缓存写入、DBAdd/DBRemove/重载、SyncModel和事件再派发的存档闭包。只读得保存字段不等于原生数据持久化已验证。
6. MainBoardView、特殊窗、订单动画辅助函数、连续额外奖励、教程/活动弹窗、关闭和延迟回调完整链。当前明确直接调度，仍需所有辅助内部逻辑与锁定状态核销。
7. CookingFrenzy定向选物、宝箱优化分支CalculateOrderCodeLackNumMap及合成库存换算、活动档位读取全部相关原型和本地/远端字段的逆向映射。
8. EmptyReqOrder刷新需求、TimedOrder覆写、连续/额外顾客状态保存与后续要求确定：创建入口规则已补，但活动生命周期和所有运行触发仍待逐项核销。

## 缺少外部材料

- 实际账号FileReplace、服务器活动档位、开关、付费/时间/进度和存档输入：可解释客户端字段/算法，不能给出账号实际抽样分布。
- 原版可运行客户端及相同输入状态：G7逐事件/状态/存档差分 unavailable。受控Lua执行不能代替原版运行观察。
- 服务器内部处理若客户端只暴露接口，另列接口约束与客户端可见行为，不编造实现。

前一组不是“无法解决”，继续分析即可推进。外部材料不足也不能掩盖已有代码尚未核销的工作。
