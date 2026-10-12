# Gossip Harbor 棋盘逻辑

本站采用逻辑树组织，不按真实源文件排列。左侧树的每一层代表游戏逻辑的一层：根节点是玩家操作，下一层是操作中的主要判断，再下一层是判断内部的机制分支，最底层页面直接给出算法、配表、状态和源码证据。

## 四个顶层主题

- [付费项目](operations/paid/index.md)：常驻商店、周期礼包、活动投放、价格与奖励价值。
- [母体点击](operations/generator/index.md)：状态、空位、能量、Lucky、五类普通产出、次数、CD 和后续事件。
- [棋子拖拽与合成](operations/merge/index.md)：移动、交换、特殊棋子、普通合成和副产物。
- [订单提交](operations/orders/index.md)：可交付判断、需求扣除、奖励、订单完成和补位。

## 参考 PDF 对照

- [参考 PDF 覆盖核验](reference_pdf_coverage.md)：逐章节核对母体、订单、剧情/好感度、用户差异、配置分层和订单附表，明确已覆盖内容与证据缺口。
- [Git 历史版本覆盖审计](legacy_version_coverage.md)：逐提交比较历史 MkDocs/HTML 标题和归档内容，记录页面重组、别名映射与真正需要补回的内容。

## 历史验收基线

历史版本的三类操作验收要求已经整合到当前四个顶层主题：

| 顶层主题 | 历史验收范围 |
| --- | --- |
| 母体点击 | 五种 `WeightType`、Lucky 机会耗尽/重复、免费/二连/三连、能量不足、棋盘满、初始化/关闭/开启/CD/恢复、EnergyBoost、GeneratorBoost、Disco、SmartProduce、一次性/可恢复耗尽 |
| 棋子拖拽与合成 | 移动、交换、不可移动目标、普通合成、特殊棋子、`ItemSwallow`、`Temp`、`Card`、`EnergyBubble`、`Bubble`、`Coin` 和满盘跳过 |
| 订单提交 | 单/多/重复需求、棋盘与仓库混合、不足需求、确认窗口、奖励、Special/Branch/Lucky/Timed/Contiorder、补位、状态更新、事件和同步 |

每个验收场景都应记录输入、随机序列、配置快照、状态快照、事件顺序、网络交互和 UI 结果；当前没有原版运行环境的项目仍保持 `unavailable`，不因文档重组而误标通过。

## 阅读方法

展开左侧树，父页面只解释当前层级的作用、顺序和子节点；子页面继续向下展开。底层节点页面同时展示算法、配表、状态字段、源码位置和证据等级，不把证据从机制中拆走。

## 当前规模

Lua 模块 3,415 个，Lua 原型 33,272 个，Android 类 43,784 个，Android 方法 254,729 个。`ItemModelConfig`: 548 行，Spread 163 行，MergedType 370 行，BubbleChance>0 138 行；`OrderItemConfig`: 74 行，DiffScore 2–3000。
