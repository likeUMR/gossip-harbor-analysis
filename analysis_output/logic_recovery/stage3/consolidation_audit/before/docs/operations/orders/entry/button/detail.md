# 按钮资格：具体算法与配置

BaseOrderCell.OnGoButtonClicked只在m_bGoButtonEnabled恰为false时return；nil不等同false。随后播放sfxOrderServe，取得所在BoardView模型，检查CanDeliver。SpecialOrderCell覆盖入口，门控和音效相同，却直接打开SpecialOrderItemWindow，不做普通入口的数量判断。订单状态控制按钮显示属于点击之前的资格来源，不是模型内部第二次校验。

## 源码依据

- Board.View.Order.BaseOrderCell：[恢复源码](../../../../assets/order-evidence/Board.View.Order.BaseOrderCell.lua) · [原始指令](../../../../assets/order-evidence/Board.View.Order.BaseOrderCell.disassembly.txt)。对应：BaseOrderCell:OnGoButtonClicked（恢复文本行22）

- Board.View.Order.MainOrderCell：[恢复源码](../../../../assets/order-evidence/Board.View.Order.MainOrderCell.lua) · [原始指令](../../../../assets/order-evidence/Board.View.Order.MainOrderCell.disassembly.txt)。对应：SpecialOrderCell:OnGoButtonClicked（恢复文本行536）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：按钮允许提交

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。按钮开启，非特殊入口。

**按执行顺序代入：** m_bGoButtonEnabled=true→不return；播放sfxOrderServe；GetCodeCountMap(true,false,false)得到203:2，需求检查204不足→打开确认窗。

**玩家看到的结果：** 听到服务音效，出现使用仓库204补交的确认窗；金币仍100，物品未扣。
