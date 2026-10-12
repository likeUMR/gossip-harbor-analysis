# 母体点击逐门禁审核

结论：未通过验收。审核对应 GH_LOGIC_RECOVERY_PLAN.md 第 9.4 节。此文件属于工作记录，不进入领导网站。

## 七项门禁

| 门禁 | 结果 | 依据与缺口 |
|---|---|---|
| G1 | pending | 全库已有 3,415 模块指令结构校验；母体相关原型到逻辑单元的对应尚未核销，不能以命名函数数量替代。 |
| G2 | failed | 审计原工具只选固定 12 模块。Super Lucky 已找到特效、音效、提示和 GeneratorBoost 消费者，尚未完成这些模块及其调用/监听闭包核销。 |
| G3 | pending | 两核心模块的 114 个命名函数缺少持久化逐分支审核证据；名称匹配仅提供检索线索。 |
| G4 | pending | 配置重载清机会池、活动结束清特殊状态、每日能量重置、普通次数保存等需逐字段映射与重登/边界验证。 |
| G5 | pending | 现有配置族已有展示位置；尚无读取字段与全量记录双向核销。服务器阈值、开关及账号活动配置仍有未取得值。 |
| G6 | pending | 自动检查相对 Markdown 链接与可达页面；尚无逻辑单元至具体段落的全量映射，四层深度与语义一致性仍需审核。 |
| G7 | pending | 当前审计输入未提供全分支受控案例、原版逐事件/状态/存档差分及差异关闭记录。静态演示不是原版运行证据。 |

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

本轮修正 Super Lucky 的因果说明与错误的“后续池”说法，并明确 GeneratorBoost 追加物品是独立 Buff 分支。源码分类可以确认，但消费者闭包及原版回放仍需核销，不能把“没有额外机会”扩大为“没有任何后续活动效果”。

后续优先：补齐配置装载/重载及重置生命周期；核销 GeneratorBoost、Disco、SmartReward、EnergyBoost 的依赖；逐分支绑定文档和案例；采集原版对照。
