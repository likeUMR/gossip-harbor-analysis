# 分支任务交付：具体算法与配置

先Slot.FinishOrder→按order.Slot查BranchConfig→按Requirement链/GeneratorChain批量清理（规则同特殊任务，棋盘/仓库/缓存都处理）。GetCodeAndWeightPairs把Rewards的code-count字符串转Code/Weight。while #pool~=0：ListWeightSelectOne取code→FindEmptyPositionInValidOrder→无位CacheItems({code},Type2)，有位GenerateItem并加入New→从前向后找首个相同code，Weight−1，恰为0才删除并break。没有全局持久池；本次临时池单位份额无放回，code可重复出现。结束写EndTimeline="1"，局部FinishBranchOrder携Order/Removed/New；New不含缓存件。默认Slot7池2402×2、2405×1、2502×2、2503×1，共6件；初次概率2/6、1/6、2/6、1/6。重复code配置、零/负权重不应假设自动归并或修复。

## 对应本地配表

各后缀为可选变体，不是同时叠加。require受FileReplace精确文件名首匹配替换，失败才回退默认；实际账号选择及远端档位未取得。缺字段记“—”，不能当0。下方保留全记录与全部字段；嵌套Filters/Rewards可横向滚动查看。

**OrderBranchConfig字段含义：** Slot索引实际分支配置，Requirement与GeneratorChain决定清链；Rewards的code-count既为抽样份额又为必须发完的件数；BranchType为进度类型，EndTimeline完成标记，Id/AvatarId构造对象。

<details><summary>OrderBranchConfig：1条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>AvatarId</th><th>BranchType</th><th>EndTimeline</th><th>GeneratorChain</th><th>Id</th><th>Requirement</th><th>Rewards</th><th>Slot</th></tr></thead><tbody>
<tr><td>401</td><td>1</td><td>branch_order_finish</td><td>82</td><td>1</td><td>8313</td><td>[&quot;2402-2&quot;, &quot;2405-1&quot;, &quot;2502-2&quot;, &quot;2503-1&quot;]</td><td>7</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderBranchConfig.json">完整原记录</a></p></details>

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:_FinishBranchOrder（恢复文本行1287）

- Board.Model.ItemModelFactory：[恢复源码](../../../../assets/order-evidence/Board.Model.ItemModelFactory.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.ItemModelFactory.disassembly.txt)。对应：ItemModelFactory.GetCodeAndWeightPairs（恢复文本行275）

- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)。对应：BaseBoardModel:FindEmptyPositionInValidOrder（恢复文本行403）

- Board.Model.Board.BaseItemLayerModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseItemLayerModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseItemLayerModel.disassembly.txt)。对应：BaseItemLayerModel:FindEmptyPositionInValidOrder（恢复文本行74）

- Common.Utility.Table：[恢复源码](../../../../assets/order-evidence/Common.Utility.Table.lua) · [原始指令](../../../../assets/order-evidence/Common.Utility.Table.disassembly.txt)。对应：Table.ListWeightSelectOne（恢复文本行103）

- Common.Utility.MathUtil：[恢复源码](../../../../assets/order-evidence/Common.Utility.MathUtil.lua) · [原始指令](../../../../assets/order-evidence/Common.Utility.MathUtil.disassembly.txt)


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：分支奖励有限池全部发完

**完整输入（演示设定）：** 本地槽7奖励2402×2、2405×1、2502×2、2503×1；假设分支资格有效、相关清链已完成，奖励时仅2个合法空格。

**按执行顺序代入：** 按此序2402/2405/2502/2503，权重6→5→4→3→2→1，示例抽签1/2/2/3/1/1依次得到2402,2405,2502,2503,2402,2502；各Count−1，最终全0。

**玩家看到的结果：** 棋盘收到2402和2405各一件；缓存收到2402一件、2502两件、2503一件；顺序随机，总共六件不会少发。
