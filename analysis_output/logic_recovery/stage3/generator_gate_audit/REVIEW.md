# 母体点击逐门禁审核

结论：未通过验收。审核对应 GH_LOGIC_RECOVERY_PLAN.md 第 9.4 节。此文件属于工作记录，不进入领导网站。

## 七项门禁

| 门禁 | 结果 | 依据与缺口 |
|---|---|---|
| G1 | pending | 全库已有 3,415 模块指令结构校验；母体相关原型到逻辑单元的对应尚未核销，不能以命名函数数量替代。 |
| G2 | failed | 全库 3415 份恢复源码发现 28 个直接ItemSpread监听注册点；这些消费者的条件、配置、再派发及动态包装链未全核销。GeneratorBoost具体复制算法已补充，但不能据此证明完整闭包。 |
| G3 | pending | 本轮 22 页选定规则有持久化哈希及说明证据；核心114函数的全量逐分支核销尚未完成。选定规则审核不等于整函数批准。失效证据0项。 |
| G4 | pending | 配置重载清机会池、活动结束清特殊状态、每日能量重置、普通次数保存等需逐字段映射与重登/边界验证。 |
| G5 | pending | 现有配置族已有展示位置；尚无读取字段与全量记录双向核销。服务器阈值、开关及账号活动配置仍有未取得值。 |
| G6 | pending | 自动检查相对 Markdown 链接与可达页面；尚无逻辑单元至具体段落的全量映射，四层深度与语义一致性仍需审核。 |
| G7 | unavailable | 恢复源码受控执行 63/63 通过，只验证选定规则；用户确认只有安装包和解包资源，原版事件/状态/存档差分缺少可运行原版环境。全分支验证也未齐备。 |

## 核心模块的独立清单

| 模块 | 命名函数 | 名称匹配 | 无名称匹配 | 语义核销待完成 | 原型数 |
|---|---:|---:|---:|---:|---:|
| ItemSpread | 69 | 59 | 10 | 69 | 70 |
| LuckyProduceModel | 45 | 40 | 5 | 45 | 48 |

名称匹配不是完成率；原型包含顶层与匿名函数，也不是命名函数数量。JSON 保留源码/文档哈希、每个函数的条件/返回/状态/配置候选以及原型清单。

## 文档与配置机械检查

母体页面 78 个；导航或 Markdown 链接可达 78 个；缺失相对目标 0 个。仅证明目标存在，不证明解释充分或网页视觉正确。


## 逐函数待核销线索

### ItemSpread

以下方法名尚未出现在母体文档；部分可能是工具或通用读取，需归属后决定解释深度：

- `ItemSpread:GetOpenDuration`
- `ItemSpread:GetCodeWeightPairs`
- `ItemSpread:GetSpreadCount`
- `ItemSpread:GetSpreadMaxNum`
- `ItemSpread:CanSupportCDBuff`
- `ItemSpread:CanSupportGeneratorBoostCDBuff`
- `ItemSpread:CanTestSupportCDFree`
- `ItemSpread:_Log`
- `ItemSpread:_FlushLog`
- `ItemSpread:GetTestLastSpreadInfo`
### LuckyProduceModel

以下方法名尚未出现在母体文档；部分可能是工具或通用读取，需归属后决定解释深度：

- `LuckyProduceModel:_GetTotalLeftSpreadCount`
- `LuckyProduceModel:_GetLuckyLeftSpreadCount`
- `LuckyProduceModel:_GetEnergyCostCount`
- `LuckyProduceModel:_GetCurLuckyProduceConfigIndex`
- `LuckyProduceModel:GetTestInfo`

## 修复及证据边界

已修正Fixed类型共享有限池、Lucky Smart整数倍率/等级条件、Super分类、宝箱预算与首项消费、SmartItem二进制缺口/补发、Disco助力分与回退、FishNet降级范围、免费计数重置、次数保存顺序、自动满盘缓存和GeneratorBoost追加复制。案例使用本地配置值并区分演示状态；选定规则的执行验证不能扩大为全操作已通过。

配套证据：reviewed_rules.json（页面/源码/配表块哈希与选定规则范围）、source_rule_tests.json（受控恢复源码执行）、EVENT_CONSUMERS.md / event_consumers.json（全库直接事件注册点）。工作记录不进入领导网站。

后续优先：补齐配置装载/重载及重置生命周期；核销 GeneratorBoost、Disco、SmartReward、EnergyBoost 的依赖；逐分支绑定文档和案例；采集原版对照。
