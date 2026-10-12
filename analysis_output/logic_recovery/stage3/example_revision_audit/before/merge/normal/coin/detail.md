# 主副产物之后，独立检查金币：具体算法与配置

`not IsBoardFull()`后读取SystemConfigKey.SpreadCoinMinChainLevel；条件`threshold ≤ New.Type链等级`，含等号。按FindEmptyPositionInSpreadOrder(New.Position)取首空位，SpreadItem(Coin01,logSpread=false)。没有随机接口，不按概率给金币，也不以hasCreateItem为互斥条件。

SystemConfigModel.LoadFileConfig读取GetLocalConfig(LocalConfigKey.System)，逐条用name作键、tonumber(value)保存，GetConfig直接查该键；默认SystemConfig本地值8。不能凭空添加远端覆盖优先级，实际本地装载变体应按ConfigModel选择核对。普通合成等级2时不达；等级8且有位时会给1枚Coin01。特殊升级/剪刀不会调用此普通后处理，因此不可默认它们也按等级发金币。

## 本分支的落点与写入顺序

FindEmptyPositionInSpreadOrder从New.Position开始，maxTiles=max(7,9)=9；r=1..8。每轮当前位置先(−1,−1)，然后按dir右/上/左/下，每边走2r步，每步之后检查合法且GetItem=nil就return。无位return openedPosition（本链未传即nil）。中心不扫描，角落越界跳过但步进继续。

例如中心(4,3)，r1依次(4,2),(5,2),(5,3),(5,4),(4,4),(3,4),(3,3),(3,2)。若唯一空位为源S=(3,3)，落在r1第7项；不是总优先源格。

SpreadItem内GenerateItem→SaveItemProperty→_SetItem（默认刷新订单）→局部SpreadItem→主盘全局ItemSpread→日志/满盘检查。本操作传logSpread=false禁产出日志，但不禁上述通知。消息CostEnergy缺省值与BoardSpreadType由SpreadItem实现填充，活动应读取实际消息，不把合成来源冒充母体消耗能量。

EnergyBubble分支缺外层满盘检查是前述例外；GenerateItem(nil,code)仍保存对象但不写格，不能当落子已成功。顺序写入不是统一事务。

## 对应本地配表

| 字段 | 在本步骤中的含义 |
| --- | --- |
| name / value | 以name索引的本地数值；SpreadCoinMinChainLevel默认8，比较新物链等级 |

同一文件后缀是可选变体，不代表本次账号全部同时生效。全局require按FileReplace的首个精确file匹配追加后缀，替换装载失败才回退默认；账号实际后缀尚未取得。下表列出此步骤所用字段，下载保留完整原记录。字段缺省以“—”表示，不能当作数值0。

<details><summary>SystemConfig：1条相关记录（原表4条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>name</th><th>value</th></tr></thead><tbody>
<tr><td>SpreadCoinMinChainLevel</td><td>8</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/SystemConfig.json">完整原记录</a></p>
</details>

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Model.SystemConfigModel：[恢复源码](../../../../assets/merge-evidence/Model.SystemConfigModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Model.SystemConfigModel.disassembly.txt)
- Board.Model.Board.BaseItemLayerModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.disassembly.txt)
- Board.Model.Base.BoardPosition：[恢复源码](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.disassembly.txt)
- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)

---

## 贯穿案例：两个201合成202

<img src="../../../../../assets/cases/item-2401.png" alt="棋子2401" style="width:72px;height:72px;object-fit:contain;margin-right:12px;">

202是当前链第2级，低于默认门槛8，因此主例没有金币。对照合成到第8级且还有空格时，多出1枚一级金币。

### 代入本页的值

默认threshold=8，newLevel=2→false。newLevel=8→true；若上一副产物用完唯一空位，IsBoardFull=true，则连阈值读取也跳过。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
