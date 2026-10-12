# 特殊与分支的底层算法

Special 的链判断先取每个 Requirement 的 `GetChainId`，再把 `GeneratorChain` 也转成链 ID；棋盘棋子若本体代码或 `ItemBubble` 内部代码属于任一需求链/生成器链，就交给 `_BatchRemoveItems` 删除。完成后调用 `RewardApi.AcquireRewardsLogic(orderConfig.Rewards, Give, SpecialTaskComplete, Main, Type2)`，设置 `MapDataModel:SetSlot(orderConfig.EndTimeline,"1")`，最后发 `FinishSpecialOrder`。

Branch 使用单个 Requirement 的链 ID和 GeneratorChain组成清除条件；随后构造 `ItemModelFactory.GetCodeAndWeightPairs(orderConfig.Rewards)`，只要权重列表非空就调用 `Table.ListWeightSelectOne` 取一个 Code，并寻找有效空位生成奖励棋子。源码明确是循环消耗候选列表，但奖励列表为空、棋盘无空位和后续事件的完整处理需要运行时样本确认。

**证据状态**：Special 清除、奖励、时间线和事件 `source-confirmed`；Branch 落点失败和配置实际值 `runtime-pending`。**源码**：`Board_Model_Board_MainBoardModel.lua:1258-1310`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
