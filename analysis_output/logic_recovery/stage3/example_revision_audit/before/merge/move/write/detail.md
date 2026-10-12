# 写格、原格复位与位置日志：具体算法与配置

条件`targetItem==nil or targetItem==item`。先_SetItem(sourcePos,nil,false)，再_SetItem(targetPos,item,false)。目标不是源自身时_LogMove；最后SetPosition(targetPos)。两次写格都明确false，不在此刷新订单。

MainBoardItemLayerModel:SetItem检查位置有效，移除原占用时空格数+1/从m_mapItems删除；写数据库position.GetKey()→itemId，空值则Remove；更新二维m_items；新占用空格数−1并加入m_mapItems。因此正常移动空格总数不变。ItemModel:SetPosition更新内存并派位置事件；格位置持久化在格层表，不靠SetPosition自动保存棋子配置。

_LogMove记录棋子code、源/目标坐标、特定活动日志参数；原格分支省略这一日志。正常路径没有资源扣除API，也没有普通合成事件。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Board.MainBoardItemLayerModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardItemLayerModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardItemLayerModel.disassembly.txt)
- Board.Model.Item.ItemModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.disassembly.txt)

---

## 贯穿案例：两个201合成202

<img src="../../../../../assets/cases/item-201.png" alt="棋子201" style="width:72px;height:72px;object-fit:contain;margin-right:12px;">

本例T被占用，不执行移动。空格对照：201从S移到T，S空出，T仍是原对象。

### 代入本页的值

对照T为空：_SetItem(S,nil,false)→_SetItem(T,source,false)→LogMove→SetPosition(T)。原格T=S时仍写两次格，不写LogMove，但会进入收尾。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
