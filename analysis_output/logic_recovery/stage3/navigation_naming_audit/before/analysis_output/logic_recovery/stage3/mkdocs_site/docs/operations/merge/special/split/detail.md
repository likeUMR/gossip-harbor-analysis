# 拆分确认、扣次数与第二落点：具体算法与配置

从目标type读取chainId、level、chain，prevType=chain[level−1]；打开确认窗，两个结果参数都为prevType，场景scissor_item_use_confirm。外层复位剪刀并return true。

确认再CanItemAffect；CostSplitUseCount先减1并保存；剩余≤0则RemoveItem剪刀。RemoveItem(target)；GenerateItem(T,prevType)；FindEmptyPositionInSpreadOrder(T)；GenerateItem(otherPosition,prevType)。局部SplitItem消息含Split/Target/New1/New2，LogSplit记录scissor=1，_TryLogBoardFull，最后关窗。没有全局ItemMerged或ItemShocked，也不检查普通合成副产物。

落点扫描从T左下角环的第一步开始：右、上、左、下，每边2r步，半径1到max(宽,高)−1，取首个合法空格，跳过中心；不是随机位置。正常资格要求非满盘，确认时复核。若重入等使第二位置nil，GenerateItem仍可创建并保存无格位置对象，因为只在position非nil时写格；源码没有回滚，不能发明自动缓存或取消分支。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Board.BaseItemLayerModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.disassembly.txt)
- Board.Model.Item.ItemSplit：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemSplit.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemSplit.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：最后一次剪刀拆分

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。剪刀在S=(3,3)且剩1次，目标202在T=(4,3)；另有空格(7,9)，其余格占满，玩家确认。

**按执行顺序代入：** 次数1−1=0→删剪刀；删202→T生成201；以T为中心第1圈第7项S为空→S生成201。

**玩家看到的结果：** 剪刀消失，原202变成两件201，分别在原目标格和原剪刀格；能量不变。
