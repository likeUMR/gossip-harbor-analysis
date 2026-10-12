# 概率修正与随机判定

棋盘满或气泡功能关闭时不调用随机数；已有相同 inner code 的气泡也直接取消。否则先读新棋子的 `BubbleChance`，购买加成或订单加成成立时把概率置为 100%；普通路径依次乘订单衰减、高等级气泡链衰减和 `BubbleDecreaseModel` 的全局倍率，最后把概率下限限制为 1。测试开关 `TestBubbleMustSpread` 在随机前强制 100%。

最终调用 `MathUtil.Random(100)`，源码实现为 `floor(math.random()*100)+1`，取值 1..100（含端点）；条件是 `p >= R`。通过后把新棋子 code 加上 Bubble 前缀，并使用 `FindEmptyPositionInSpreadOrder` 找气泡落点，再派发 `BubbleSpread`。这是独立阈值判定，不是候选池抽样，也不保存历史抽样状态。

**源码**：`MainBoardModel:_TrySpreadBubbleByMerge`、`_GetDecreaseBubbleChanceRatio`、`_GetDecreaseBubbleChanceRatio2`、`MathUtil.Random`。

---

## 贯穿案例：两个 201 合成 202


拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
