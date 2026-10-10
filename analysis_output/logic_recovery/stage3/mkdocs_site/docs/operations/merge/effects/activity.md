# 卡牌、能量气泡和临时棋子

Temp 先于 Card，Card 先于 EnergyBubble；某一步创建成功后，后续两类不再创建，棋盘满时跳过。

**源码**：`MainBoardModel:_DoMergeItem` 及 Temp/Card/EnergyBubble 调用。**配置**：对应类型字段。活动开关、动态对象身份和真实概率 `runtime-pending`。

---

## 贯穿案例：两个 201 合成 202


拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
