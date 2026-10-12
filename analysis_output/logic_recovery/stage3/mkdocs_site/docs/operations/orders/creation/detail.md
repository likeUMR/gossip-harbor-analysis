# 随机订单过滤与抽取细节

Random creator 首先读取类型计时器；首次创建写入服务器时间，之后要求 `serverTime - startTimer >= RefreshTime`。过滤器选择后，分别按第一、第二、第三需求的难度上下限筛候选。候选必须通过 `_CheckItemCode`，并在 `Weight > 0` 时进入累计权重池。

需求数量从 `ItemAmounts` 的 `OneItemWeight`、`TwoItemsWeight`、`ThreeItemsWeight` 中抽取；当前 JSON 的常见类型为 50/50/0。候选代码按 `Table.ListWeightSelectOne` 选择，重复链衰减通过 `RepeatWeightDecreaseChain` 元数据改变权重；这不是永久删除全局配置项。订单完成后，涉及 `RepeatWeightDecrease > 0` 的链会重置衰减状态。

当前本地快照：`OrderItemConfig.json` 74 行，`DiffScore` 2–3000；`OrderRandomConfig.json` 9 个 Type（1、2、3、4、9、12、15、16、21）；`OrderFixedConfig.json` 16 行。Special/Branch 配置由 Lua 配置装载，但没有完整 JSON 快照。

**源码**：`MainOrderCreatorRandom.luac.txt` 的 `CanCreate` 119-168、`Create` 185-309、`GetAvailableItems` 671-824、`FilterByLevel` 1087-1117、`FilterByChainId` 1122-1131；**证据**：配置字段和选择顺序 `source-confirmed`，随机接口端点和运行时筛选结果 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
