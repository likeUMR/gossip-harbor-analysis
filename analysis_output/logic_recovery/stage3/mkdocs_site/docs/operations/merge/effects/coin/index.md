# 金币

合成链等级达到 `SystemConfig.SpreadCoinMinChainLevel` 后进入金币检查。金币检查位于互斥副产物流程之后，独立判断，但同样需要空位。

**配表**：`SystemConfig.SpreadCoinMinChainLevel`。**源码**：`MainBoardModel:_DoMergeItem` 金币分支。活动修正 `runtime-pending`。

---

## 贯穿案例：两个 201 合成 202


拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
