# 没有前两种副产物，再尝试能量气泡：具体算法与配置

此分支只检查not hasCreateItem，没有像临时/卡片那样外层not IsBoardFull。CanSpreadEnergyBubble要求Started且serverTime>TriggerTime，恰好相等不触发。配置energyBubbleConfig先按trigger_energy升序，同值trigger_gem降序。

GetTriggerConfig逐条：当前Energy≤trigger_energy；若连锁能量商店开启，读取当前step的price，跳过连续price=0记录，越末尾break；否则读取EnergyData.costNum。cost≥trigger_gem才选第一条。未选到返回nil。

GetBubbleInfo拼`PropertyBubble前缀 + Energy属性 + '-' + energy + '-' + gem`，Group=groupId；先保存TriggerTime=serverTime+interval×60和GroupId，然后返回Code/Group。棋盘找环形空位并SpreadItem，记录BubbleType/Group、hasCreateItem=true。若此前同步变化使满盘，这里可能位置nil而活动冷却已保存；不可补成“满盘必不推进冷却”。

字段trigger_energy、trigger_gem、energy、gem、interval、groupId均来自服务器活动表，包内实际账号记录缺失；表排序与时间/价格规则可恢复，实际产量和价格不能冒充已知。

## 本分支的落点与写入顺序

FindEmptyPositionInSpreadOrder从New.Position开始，maxTiles=max(7,9)=9；r=1..8。每轮当前位置先(−1,−1)，然后按dir右/上/左/下，每边走2r步，每步之后检查合法且GetItem=nil就return。无位return openedPosition（本链未传即nil）。中心不扫描，角落越界跳过但步进继续。

例如中心(4,3)，r1依次(4,2),(5,2),(5,3),(5,4),(4,4),(3,4),(3,3),(3,2)。若唯一空位为源S=(3,3)，落在r1第7项；不是总优先源格。

SpreadItem内GenerateItem→SaveItemProperty→_SetItem（默认刷新订单）→局部SpreadItem→主盘全局ItemSpread→日志/满盘检查。本操作传logSpread=false禁产出日志，但不禁上述通知。消息CostEnergy缺省值与BoardSpreadType由SpreadItem实现填充，活动应读取实际消息，不把合成来源冒充母体消耗能量。

EnergyBubble分支缺外层满盘检查是前述例外；GenerateItem(nil,code)仍保存对象但不写格，不能当落子已成功。顺序写入不是统一事务。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- EnergyBubble.Model.EnergyBubbleModel：[恢复源码](../../../../assets/merge-evidence/EnergyBubble.Model.EnergyBubbleModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/EnergyBubble.Model.EnergyBubbleModel.disassembly.txt)
- Board.Model.Board.BaseItemLayerModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.disassembly.txt)
- Board.Model.Base.BoardPosition：[恢复源码](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.disassembly.txt)
- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)

---

## 贯穿案例：两个201合成202



本例能量气泡活动未开启，继续普通气泡。对照能量低且购买价格过门槛，生成一枚指定能量/宝石价格的气泡。

### 代入本页的值

假设serverTime=1000、旧TriggerTime=999、interval=5：通过时间条件，选择后新TriggerTime=1300。恰好serverTime=999不通过；能量10与trigger_energy=10相等可通过。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
