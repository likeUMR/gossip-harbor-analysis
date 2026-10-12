# 拆分确认、扣次数与第二落点：具体算法与配置

从目标type读取chainId、level、chain，prevType=chain[level−1]；打开确认窗，两个结果参数都为prevType，场景scissor_item_use_confirm。外层复位剪刀并return true。

确认再CanItemAffect；CostSplitUseCount先减1并保存；剩余≤0则RemoveItem剪刀。RemoveItem(target)；GenerateItem(T,prevType)；FindEmptyPositionInSpreadOrder(T)；GenerateItem(otherPosition,prevType)。局部SplitItem消息含Split/Target/New1/New2，LogSplit记录scissor=1，_TryLogBoardFull，最后关窗。没有全局ItemMerged或ItemShocked，也不检查普通合成副产物。

落点扫描从T左下角环的第一步开始：右、上、左、下，每边2r步，半径1到max(宽,高)−1，取首个合法空格，跳过中心；不是随机位置。正常资格要求非满盘，确认时复核。若重入等使第二位置nil，GenerateItem仍可创建并保存无格位置对象，因为只在position非nil时写格；源码没有回滚，不能发明自动缓存或取消分支。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Board.BaseItemLayerModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.disassembly.txt)
- Board.Model.Item.ItemSplit：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemSplit.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemSplit.disassembly.txt)

---

## 贯穿案例：两个201合成202

<img src="../../../../../assets/cases/item-level_down_piece_1.png" alt="棋子level_down_piece_1" style="width:72px;height:72px;object-fit:contain;margin-right:12px;">

主例没有剪刀。拆分对照：把剪刀拖到202，确认后得到两个201。

### 代入本页的值

202为链第二级，chain[1]=201。演示剪刀剩余1→0并移除；T生成201。其它格全满而剪刀在S=(3,3)、T=(4,3)时，第二件最终落入腾出的S；若剪刀仍有次数，则要求已有另一空位。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
