# 位置更新：具体算法与配置

条件`targetItem==nil or targetItem==item`。先_SetItem(sourcePos,nil,false)，再_SetItem(targetPos,item,false)。目标不是源自身时_LogMove；最后SetPosition(targetPos)。两次写格都明确false，不在此刷新订单。

MainBoardItemLayerModel:SetItem检查位置有效，移除原占用时空格数+1/从m_mapItems删除；写数据库position.GetKey()→itemId，空值则Remove；更新二维m_items；新占用空格数−1并加入m_mapItems。因此正常移动空格总数不变。ItemModel:SetPosition更新内存并派位置事件；格位置持久化在格层表，不靠SetPosition自动保存棋子配置。

_LogMove记录棋子code、源/目标坐标、特定活动日志参数；原格分支省略这一日志。正常路径没有资源扣除API，也没有普通合成事件。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Board.MainBoardItemLayerModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardItemLayerModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardItemLayerModel.disassembly.txt)
- Board.Model.Item.ItemModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：把201移入空格

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。S=(3,3)是普通201对象A，T=(4,3)为空，释放资格通过，能量10。

**按执行顺序代入：** 清S(false)→写T=A(false)→LogMove→SetPosition(T)；空位先+1再−1，净变化0。

**玩家看到的结果：** 201从左格移到右格，原格空出；能量仍10，没有新产物。
