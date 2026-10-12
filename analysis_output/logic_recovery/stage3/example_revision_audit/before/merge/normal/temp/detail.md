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

## 贯穿案例：两个201合成202



本例临时物活动未开启，跳过，继续卡片。对照活动开启且选出204时，在202旁生成临时204并跳过卡片和气泡。

### 代入本页的值

本例Started=false，GenerateType=nil。新模式演示当前链库存202×1：diff[1]=1、diff[2]=2−2=0、diff[3]=4−2=2；选物还需实际订单、阈值和触发类型，不能仅凭diff自动生成。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
