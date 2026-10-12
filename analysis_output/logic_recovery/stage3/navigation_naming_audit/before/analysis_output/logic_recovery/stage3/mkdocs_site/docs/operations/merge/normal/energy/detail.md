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

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：低能量时生成购买气泡

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。临时物和卡片都未生成；假设能量气泡Started，now1000>旧Trigger999；能量10、非免费购买价格20；唯一档trigger_energy10、trigger_gem20、energy100、gem30、interval5、groupId2，S为空。

**按执行顺序代入：** 10≤10且20≥20→选档；TriggerTime=1000+5×60=1300，GroupId=2保存；Code按PropertyBubble前缀、Energy、100、30拼接，SpreadItem到S；hasCreateItem=true。 代入原前缀prb#和energy，实体Code=prb#energy-100-30。

**玩家看到的结果：** 202旁出现内含100能量、购买价30宝石的气泡；当前能量仍10，没有自动扣30宝石，等待5分钟后才可能再次触发该机制。
