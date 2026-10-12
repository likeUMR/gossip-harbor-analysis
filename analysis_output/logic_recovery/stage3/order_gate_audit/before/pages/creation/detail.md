# 随机订单过滤与抽取细节

Random creator 首先读取类型计时器；首次创建写入服务器时间，之后要求 `serverTime - startTimer >= RefreshTime`。过滤器选择后，分别按第一、第二、第三需求的难度上下限筛候选。候选必须通过 `_CheckItemCode`，并在 `Weight > 0` 时进入累计权重池。

需求数量从 `ItemAmounts` 的 `OneItemWeight`、`TwoItemsWeight`、`ThreeItemsWeight` 中抽取；当前 JSON 的常见类型为 50/50/0。候选代码按 `Table.ListWeightSelectOne` 选择，重复链衰减通过 `RepeatWeightDecreaseChain` 元数据改变权重；这不是永久删除全局配置项。订单完成后，涉及 `RepeatWeightDecrease > 0` 的链会重置衰减状态。

当前本地快照：`OrderItemConfig.json` 74 行，`DiffScore` 2–3000；`OrderRandomConfig.json` 9 个 Type（1、2、3、4、9、12、15、16、21）；`OrderFixedConfig.json` 16 行。Special/Branch 配置由 Lua 配置装载，但没有完整 JSON 快照。

**源码**：`MainOrderCreatorRandom.luac.txt` 的 `CanCreate` 119-168、`Create` 185-309、`GetAvailableItems` 671-824、`FilterByLevel` 1087-1117、`FilterByChainId` 1122-1131；**证据**：配置字段和选择顺序 `source-confirmed`，随机接口端点和运行时筛选结果 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
