# 优先尝试临时棋子：具体算法与配置

棋盘非满且hasCreateItem=false才GenerateType(New.Type)。_CanGenerateTempItem要求Started且主盘没有任何ItemTemp；_CanTrigger要求Energy≤TriggerEnergy（缺省不限制）、排除免费后的能量购买价格≥TriggerGem（缺省不限制），且非无限能量。RoundInterval由interval×60秒；轮间条件严格serverTime−lastEnd>interval。

旧模式：间隔未过返回；没有保存targetType才选择当前链订单缺口中最低等级的合格需求。需求须有Rule且同链；非Advanced时前1级及前2级库存代码不得存在；Advanced时到需求等级的一等价库存总量<floor(2^max(需求等级−3,0))。并要求某个临时候选等级严格高于当前合成等级。保存需求目标；然后按已排序候选找第一个level>mergedLevel，没有则MarkRoundEnd。选到候选列表末项标needUpload。

新模式：先清旧目标并写lastEnd；满足资源后，间隔过或允许同链无间隔且lastChain匹配才继续。计算diff[L]=2^(L−1)−sum(count[i]×2^(i−1),i≤L)，库存仅棋盘+仓库，无缓存；从有订单缺口及Rule且diff>threshold的需求找最高可用等级。优先在mergedLevel+1..maxLevel−1选候选，找不到才在1..min(mergedLevel,maxLevel−1)选；diff严格>阈值，MoreBetter取更大、LessBetter取更小，等值后遍历项覆盖先项。阈值先Duration[temp].trigger_item_min，否则主/副链默认阈值。

选出后保存StartTimer、LastTempItemChainId；needUpload真则检查同步。棋盘在合成新物附近按方形环找到空位，以Temp前缀+type SpreadItem(logSpread=false)，记TempType并hasCreateItem=true。它是订单缺口规则选择，不是一次均匀随机抽取。服务器temp_item_general_config、temp_item_rule_config、temp_item_duration实际记录未取得，不把演示阈值当原值。

## 本分支的落点与写入顺序

FindEmptyPositionInSpreadOrder从New.Position开始，maxTiles=max(7,9)=9；r=1..8。每轮当前位置先(−1,−1)，然后按dir右/上/左/下，每边走2r步，每步之后检查合法且GetItem=nil就return。无位return openedPosition（本链未传即nil）。中心不扫描，角落越界跳过但步进继续。

例如中心(4,3)，r1依次(4,2),(5,2),(5,3),(5,4),(4,4),(3,4),(3,3),(3,2)。若唯一空位为源S=(3,3)，落在r1第7项；不是总优先源格。

SpreadItem内GenerateItem→SaveItemProperty→_SetItem（默认刷新订单）→局部SpreadItem→主盘全局ItemSpread→日志/满盘检查。本操作传logSpread=false禁产出日志，但不禁上述通知。消息CostEnergy缺省值与BoardSpreadType由SpreadItem实现填充，活动应读取实际消息，不把合成来源冒充母体消耗能量。

EnergyBubble分支缺外层满盘检查是前述例外；GenerateItem(nil,code)仍保存对象但不写格，不能当落子已成功。顺序写入不是统一事务。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- TempItem.Model.TempItemModel：[恢复源码](../../../../assets/merge-evidence/TempItem.Model.TempItemModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/TempItem.Model.TempItemModel.disassembly.txt)
- TempItem.Board.ItemTemp：[恢复源码](../../../../assets/merge-evidence/TempItem.Board.ItemTemp.lua) · [原指令与源码行](../../../../assets/merge-evidence/TempItem.Board.ItemTemp.disassembly.txt)
- Board.Model.Board.BaseItemLayerModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.disassembly.txt)
- Board.Model.Base.BoardPosition：[恢复源码](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.disassembly.txt)
- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)

---

## 演示案例

下面分别改变前提，让各条分支实际发生；互斥结果属于不同场景。

### 场景1：旧规则帮助订单缺口

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。假设活动Started、OldMode，盘上无临时物、无无限能量；能量10≤门槛20，非免费购买价格20≥门槛10；now=1000、lastEnd=600、interval=5分钟。201合成202后本链仅202一件；订单缺205一件，Rule[205]=[203,204]，Advanced关闭，203/204库存均无。 本轮旧TargetType=nil，无教程强制计时；假设Duration[203]=60秒，落点仅S为空。

**按执行顺序代入：** 1000−600=400>5×60；205前1/2级204/203均无；mergedLevel=2，Rule首203等级3>2→203，未到列表末项；保存Target=205、StartTimer=1000、LastChain=2；S空，生成Temp包装203。 StartTimer1000，本例当前时刻1000，elapsed=0，计时0/60；临时203开始60秒存在期。 本例临时实体代码t#203。

**玩家看到的结果：** 202保留，旁边额外出现临时203，帮助继续合成订单所缺的205；本次卡片和两类气泡不再尝试。 本例临时物开始一分钟倒计时。

### 场景2：新规则按等价库存补缺

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。活动与资源、时间同上，改NewMode/MoreBetter；订单缺204一件，Rule[204]存在；合成后本链只有202一件，假设203和204的触发阈值均1，其它候选阈值1。 本轮旧TargetType=nil，无教程强制计时；假设Duration[203]=60秒，落点仅S为空。

**按执行顺序代入：** diff[1]=1，diff[2]=2−2=0，diff[3]=4−2=2，diff[4]=8−2=6；需求204的6>1→maxLevel=4；检查mergedLevel+1=3到max−1=3，diff203=2>1→选203；保存Target203、StartTimer1000、LastChain2并检查上传。 StartTimer1000，本例当前时刻1000，elapsed=0，计时0/60；临时203开始60秒存在期。 本例临时实体代码t#203。

**玩家看到的结果：** 在202旁生成临时203；帮助填补204订单，本次不再抽卡片或气泡。 本例临时物开始一分钟倒计时。

### 场景3：旧模式高级库存阈值触发

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。沿用旧规则场景，但Advanced开启；订单缺205，Rule[205]=[203,204]，本链合成后仅202一件。 本轮旧TargetType=nil，无教程强制计时；假设Duration[203]=60秒，落点仅S为空。

**按执行顺序代入：** 205等级5→阈值floor(2^(5−3))=4；仅202一件折算2<4通过；Rule首203等级3>合成等级2→选203；保存目标与开始时间，S落Temp203。 StartTimer1000，本例当前时刻1000，elapsed=0，计时0/60；临时203开始60秒存在期。 本例临时实体代码t#203。

**玩家看到的结果：** 202旁出现临时203，帮助继续制作205；高级库存规则通过后仍沿用旧模式的规则列表选物。 本例临时物开始一分钟倒计时。
