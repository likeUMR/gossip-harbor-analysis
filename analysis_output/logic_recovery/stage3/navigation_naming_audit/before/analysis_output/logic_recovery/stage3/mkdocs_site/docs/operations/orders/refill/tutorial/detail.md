# 教程单：检查解锁、跳过旧教程、进入进行中：具体算法与配置

TutorialOrderModel读取LocalConfigKey.TutoriaiOrderConfig，ConfigModel实际映射Data.Config.NewItemOrderConfig。持久字段TutorialOrderModel_CurTutorialID为id_state，缺省1_1；Ready="1"、Doing="2"。按配置id查记录，缺记录、Slot不符或非Ready拒绝。SkipItem非nil且已解锁则推进id+1并递归CanCreate当前槽；若UnlockItem==Fishing05，还同时标完成两个海鲜教程。否则UnlockItem未解锁拒绝，已解锁允许。Create按Requirement1..3非nil顺序追加，取头像，先写当前id_Doing，再创建TutorialOrder内类型11，Id=教程id。

Slot完成通知在补位之后派发，OnOrderFinished只比较消息订单Slot与当前教程Slot；Doing则进度id+1_Ready，没有再核对旧单内部类型或Id。LateInit重载遇Doing且该槽无单，同样推进；这决定下一次补位资格，不能误写成首次补位已经使用推进后的id。

## 对应本地配表

各后缀为可选变体，不是同时叠加。require受FileReplace精确文件名首匹配替换，失败才回退默认；实际账号选择及远端档位未取得。缺字段记“—”，不能当0。下方保留全记录与全部字段；嵌套Filters/Rewards可横向滚动查看。

**NewItemOrderConfig字段含义：** id是教程进度；Slot限定槽位；UnlockItem要求已解锁；SkipItem已解锁时跳过该教程；Requirement1..3按原序作为预设需求，不参与随机项数抽取。

<details><summary>NewItemOrderConfig：0条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr></tr></thead><tbody>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/NewItemOrderConfig.json">完整原记录</a></p></details>

<details><summary>NewItemOrderConfig_test：15条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Requirement1</th><th>SkipItem</th><th>Slot</th><th>UnlockItem</th><th>id</th></tr></thead><tbody>
<tr><td>904</td><td>907</td><td>11</td><td>705</td><td>1</td></tr>
<tr><td>905</td><td>907</td><td>11</td><td>705</td><td>2</td></tr>
<tr><td>906</td><td>907</td><td>11</td><td>705</td><td>3</td></tr>
<tr><td>1103</td><td>1106</td><td>11</td><td>1006</td><td>4</td></tr>
<tr><td>1104</td><td>1106</td><td>11</td><td>1006</td><td>5</td></tr>
<tr><td>1105</td><td>1106</td><td>11</td><td>1006</td><td>6</td></tr>
<tr><td>1304</td><td>1308</td><td>11</td><td>1205</td><td>7</td></tr>
<tr><td>1305</td><td>1308</td><td>11</td><td>1205</td><td>8</td></tr>
<tr><td>1307</td><td>1308</td><td>11</td><td>1205</td><td>9</td></tr>
<tr><td>1403</td><td>1406</td><td>11</td><td>1206</td><td>10</td></tr>
<tr><td>1404</td><td>1406</td><td>11</td><td>1206</td><td>11</td></tr>
<tr><td>1405</td><td>1406</td><td>11</td><td>1206</td><td>12</td></tr>
<tr><td>1804</td><td>1808</td><td>11</td><td>1705</td><td>13</td></tr>
<tr><td>1805</td><td>1808</td><td>11</td><td>1705</td><td>14</td></tr>
<tr><td>1807</td><td>1808</td><td>11</td><td>1705</td><td>15</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/NewItemOrderConfig_test.json">完整原记录</a></p></details>

## 源码依据

- Board.Model.Order.TutorialOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.TutorialOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.TutorialOrderModel.disassembly.txt)。对应：TutorialOrderModel:LateInit（恢复文本行23）；TutorialOrderModel:OnOrderFinished（恢复文本行36）；TutorialOrderModel:CanCreate（恢复文本行71）；TutorialOrderModel:CreateOrder（恢复文本行99）；TutorialOrderModel:GetCurOrderAndState（恢复文本行117）；TutorialOrderModel:SetCurOrderAndState（恢复文本行128）

- Model.ConfigModel：[恢复源码](../../../../assets/order-evidence/Model.ConfigModel.lua) · [原始指令](../../../../assets/order-evidence/Model.ConfigModel.disassembly.txt)

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)。对应：MainOrderModel:LateInit（恢复文本行119）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：预设教程需求触发

**完整输入（演示设定）：** 固定/回归未创建；假设教程记录id1、Slot1、UnlockItem201已解锁、SkipItem202未解锁、需求203、头像6；当前存档1_1。

**按执行顺序代入：** Ready1且槽匹配→CanCreate=true；Create写1_2，创建innerType11/Id1/需求[203]；完成后同槽OrderFinished消息→2_1。

**玩家看到的结果：** 槽1出现要求203的教程订单；交付完成后进入下一教程待创建状态，不使用普通随机点数。
