# 棋盘物品计数：具体算法与配置

入口GetCodeCountMap(true,false,false)：BaseBoardModel复制棋盘m_codeCountMap；BaseActionBoardModel仅includeCache~=false才加入缓存；MainBoardModel仅includeStore~=false才加入仓库。这三个布尔值分别是棋盘、缓存、仓库。需求以GetCode精确匹配；气泡/网/临时包装代码不自动等于内含203。用于日常UpdateOrderState的计数路径与此次按钮传参应分别追踪，不能用UI状态替代入口真实计数。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:GetCodeCountMap（恢复文本行187）

- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)。对应：BaseBoardModel:GetCodeCountMap（恢复文本行507）

- Board.Model.Board.BaseActionBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseActionBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseActionBoardModel.disassembly.txt)。对应：BaseActionBoardModel:GetCodeCountMap（恢复文本行136）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

<div class="case-assets"><img src="../../../../../assets/cases/item-203.png" alt="棋子203" width="72" height="72"><img src="../../../../../assets/cases/item-204.png" alt="棋子204" width="72" height="72"></div>

### 场景1：区别棋盘与总持有

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。另外缓存有204×3。

**按执行顺序代入：** 参数(true,false,false)→map={203:2}，204=0；不是仓库加缓存后的204=4；CanDeliver需求第3项失败。

**玩家看到的结果：** 虽然仓库和缓存都有204，仍会出现仓库补交提示；缓存不能替代此次材料扣除。
