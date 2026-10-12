# Git 历史版本覆盖核验

审计提交数：15；当前文档来源：工作树。

脚本按每个 Git 提交读取 MkDocs 文档和历史 HTML，抽取 Markdown/HTML 标题并与当前工作树标题集合比较。标题缺失只代表需要人工复核，不自动宣称语义丢失。

## 结果摘要

- 当前文档文件：304
- 当前唯一标题：892
- 历史提交：15
- 历史标题差异：41
- 已复核的页面重组/改名：41
- 未解决标题：0

## 结论

所有历史标题差异均已映射到当前页面或历史治理基线；没有未解决标题。

## 已复核的页面重组

| 历史标题 | 当前归档位置 |
| --- | --- |
| `1. 手动点击：确定性的方形环扫描` | `operations/generator/position/disposable/detail.md` |
| `2. 自动产出：随机空位与自动循环` | `operations/generator/position/disposable/detail.md` |
| `3. findrandomposition 的每一次抽样` | `operations/generator/position/disposable/detail.md` |
| `4. 满盘、缓存与最终写入` | `operations/generator/position/disposable/detail.md` |
| `buff切换何时真正清机会池` | `operations/generator/lucky/chance/load.md` |
| `cd、加速和恢复结算` | `operations/generator/lifecycle/cooldown/detail.md` |
| `chestcustomitem` | `operations/generator/output/chest/index.md` |
| `chestcustomitem 的具体选择` | `operations/generator/output/chest/detail.md` |
| `fixed` | `operations/generator/output/fixed/index.md` |
| `fixed 的具体选择` | `operations/generator/output/fixed/detail.md` |
| `generatorboost 任务进度与增益升级` | `operations/generator/events/side_effects/detail.md` |
| `lucky、disco 与产出改写` | `operations/generator/overrides/activity/index.md` |
| `smartitem` | `operations/generator/output/smart/index.md` |
| `smartitem 的具体选择` | `operations/generator/output/smart/detail.md` |
| `super/free 产出类型` | `operations/generator/lucky/items/type.md` |
| `三个根操作` | `docs/index.md:四个顶层主题` |
| `三类操作验收矩阵` | `docs/index.md:历史验收基线` |
| `两种切换的具体例子` | `operations/generator/lucky/chance/load.md` |
| `交付收尾` | `operations/orders/finish/index.md` |
| `剩余池恢复的具体例子` | `operations/generator/lifecycle/count/detail.md` |
| `副作用的具体字段` | `operations/generator/events/side_effects/detail.md` |
| `基础消耗和倍增比率` | `operations/generator/energy/boost/detail.md` |
| `奖励结算` | `operations/orders/rewards/index.md` |
| `存档如何恢复当前母体` | `operations/generator/state/model/detail.md` |
| `接口切换例子与真实升级路线的区别` | `operations/generator/lucky/chance/load.md` |
| `棋盘事件的具体写入顺序` | `operations/generator/events/board/detail.md` |
| `次数与剩余权重池怎样跨重载保留` | `operations/generator/lifecycle/count/detail.md` |
| `次数扣除、变换和销毁顺序` | `operations/generator/lifecycle/count/detail.md` |
| `活动、日志和 ui 副作用` | `operations/generator/events/side_effects/index.md` |
| `活动改写的具体顺序` | `operations/generator/overrides/activity/detail.md` |
| `点击关闭母体后，界面如何响应` | `operations/generator/state/closed/detail.md` |
| `点击开启中的母体后，界面如何响应` | `operations/generator/state/opening/detail.md` |
| `特殊棋子与吞噬` | `operations/merge/special/index.md` |
| `缺能量后先显示什么窗口` | `operations/generator/energy/consume/detail.md` |
| `自动产出与缓存的具体条件` | `operations/generator/position/auto/detail.md` |
| `落子通知后的 generatorboost 追加产出` | `operations/generator/events/side_effects/detail.md` |
| `订单完成、补位与同步` | `operations/orders/finish/index.md` |
| `读取与周期重装` | `operations/generator/lucky/chance/load.md` |
| `资源事件的具体监听链` | `operations/generator/events/resource/detail.md` |
| `链升级和 fishnet 具体算法` | `operations/generator/overrides/boost/detail.md` |
| `阈值队列生成` | `operations/generator/lucky/free/generate.md` |
