# 特殊棋子与吞噬

LevelUp 将目标替换为 `MergedType`；LevelDown 拆成两个前一级棋子；ItemSwallow 按两个 `Swallow_Weight` 生成目标代码并保存进度，两个目标数量都达标才 Transform；吞噬扫描按有效棋盘位置顺序，不随机打乱。

**配表**：`Swallow_Weight`、吞噬数量、Transform 字段。**源码**：[ItemSwallow.lua](/C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSwallow.lua)、`ItemTransform`。

---

## 贯穿案例：两个 201 合成 202


拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
