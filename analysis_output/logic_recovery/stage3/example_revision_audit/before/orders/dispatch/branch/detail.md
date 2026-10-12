# 分支任务：抽一份减一份直到耗尽：具体算法与配置

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

## 贯穿案例：203×2与204×1，使用仓库补交

主例不走分支。对照默认槽7，即使没有空位，6件奖励也会通过缓存全部发完。

### 代入本页的值

假设首抽2402：份数2→1，总6→5，下次2402概率1/5；最终四类件数恒2、1、2、1。新建池下一次重新读取配置。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
