# Week9 PDF 覆盖核验

基准文件：`C:\Users\TU\Documents\xwechat_files\wxid_efy8socw73jk22_346e\msg\file\2026-10\Week9(1).pdf`。文件 14 页，标题为 Week9。本页按 6.8 工作流记录范围、证据和剩余边界。

| PDF 页 | 内容分母 | 正式位置 | 状态 |
| ---: | --- | --- | --- |
| 1-4 | 体力来源、普通/战令游玩、时长反馈、42 次母体轮询 | [Week9 母体经验](operations/generator/week9_experience/index.md)、母体状态/产出页 | 已归档；样本标观察 |
| 5-6 | 槽位分类、候选比例、Slot 1/2 额度、实测卡点、Slot 6 | [Week9 订单实测](operations/orders/week9_empirical/index.md)、订单创建/补位页 | 已归档；远端值待回放 |
| 7-8 | 好感度、礼物、Slot 19、笑脸经典/智能分支与付费诱因 | [Week9 订单实测](operations/orders/week9_empirical/index.md)、订单奖励/剧情好感度页 | 已归档；模式由服务端决定 |
| 9-13 | 配置变体、服务器三种控制、18 类包内功能、玩家数据、难度/泡泡/礼包公式 | [用户差异与配置分层](operations/paid/segmentation/index.md)、付费和配置页 | 已归档；字段按证据分级 |
| 14 | 升级礼包的触发、有效序号、购买递增和换序列重置 | [等级礼包](operations/paid/level_up/index.md)、用户差异页 | 已归档；公式已视觉核对 |

## 6.8 生产记录

环节 0 保留 PDF 原始路径、页数和哈希账本；环节 1 以 14 页为独立内容分母；环节 3 将每页拆为体验、母体、订单、配置/玩家数据逻辑单元；环节 4-6 分别落到底层页面、专题页面和本覆盖表；环节 7 为 42 次轮询、订单样本、笑脸预算和礼包序号提供可回放案例；环节 8 通过 MkDocs 构建与链接扫描验收。

## 证据和未闭合项

PDF 是参考分析成果，不等价于 APK 的逐函数证明。实测时长、槽位比例、礼物概率和 42 次样本必须标为观察/样本；包内字段、调用顺序和配置记录按页面的 `source-confirmed` 等级使用。真实账号的 `FileReplace` 后缀、服务器活动 payload、笑脸模式、完整好感度配置及原版与复刻版逐字段差分仍为 `runtime-pending`，不能用页面覆盖宣称客户端全量门禁已通过。
