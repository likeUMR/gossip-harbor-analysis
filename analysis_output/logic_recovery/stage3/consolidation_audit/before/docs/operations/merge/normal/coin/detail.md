# 金币棋子产出：具体算法与配置

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

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：高阶合成额外生成金币棋子

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。207×2合成208，结果在链第8级，默认金币门槛8；假设前述副产物没有占掉S，能量10、金币余额100。

**按执行顺序代入：** newLevel8≥threshold8且非满盘→SpreadItem(Coin01)到首空S；没有随机调用，没有金币资源Acquire。

**玩家看到的结果：** 208旁多一枚一级金币棋子；余额仍100，能量仍10，需要玩家再收取金币棋子。
