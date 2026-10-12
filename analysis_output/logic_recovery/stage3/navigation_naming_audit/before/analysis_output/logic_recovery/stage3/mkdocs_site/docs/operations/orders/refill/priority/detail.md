# 新订单创建的优先级：具体算法与配置

MainOrderModel._TryCreateOrder先Fixed.Create；new=nil且ReturnFree.CanCreate才Create；再教程CanCreate/Create；读取contiModel并在nil/CanCreate时创建；再ExtraCustomer；再Lucky.CanCreate/Create；最后require随机creator。新单无Id且GetType==Random才DBIdGenerator.Generate并tonumber；_AddGiftRewardInfo→MainOrderCreated(new)→return。固定订单写当前Id进度发生在构造之前。回归/活动/教程资格可能改元数据，即使最终构造nil也不能假设无副作用。

头像：FirstOrder元数据空首次置1返固定6。BakeOut可领奖优先收集未被其它订单占用的BakeOut头像；没候选再按NormalAvatars等级门槛收集未占用。全部占用则从已解锁普通头像等权回退；连普通解锁集合都空才返6。多个集合来自pairs时排列不固定；头像不构成需求权重。

## 对应本地配表

各后缀为可选变体，不是同时叠加。require受FileReplace精确文件名首匹配替换，失败才回退默认；实际账号选择及远端档位未取得。缺字段记“—”，不能当0。下方保留全记录与全部字段；嵌套Filters/Rewards可横向滚动查看。

**OrderFixedConfig字段含义：** Id是进度顺序，Slots是允许槽位集合，UnlockLevel含端点门槛，Requirement1..3保留重复与顺序；缺需求不凭空补0。

<details><summary>OrderFixedConfig：16条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Id</th><th>Requirement1</th><th>Requirement2</th><th>Requirement3</th><th>Slots</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>1</td><td>203</td><td>—</td><td>—</td><td>[1]</td><td>1</td></tr>
<tr><td>2</td><td>208</td><td>—</td><td>—</td><td>[1]</td><td>1</td></tr>
<tr><td>3</td><td>204</td><td>—</td><td>—</td><td>[1]</td><td>1</td></tr>
<tr><td>4</td><td>206</td><td>—</td><td>—</td><td>[1]</td><td>1</td></tr>
<tr><td>5</td><td>304</td><td>—</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>6</td><td>303</td><td>—</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>7</td><td>303</td><td>206</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>8</td><td>305</td><td>—</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>9</td><td>208</td><td>—</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>10</td><td>205</td><td>303</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>11</td><td>504</td><td>504</td><td>—</td><td>[1, 2]</td><td>3</td></tr>
<tr><td>12</td><td>205</td><td>505</td><td>—</td><td>[1, 2]</td><td>3</td></tr>
<tr><td>13</td><td>505</td><td>503</td><td>—</td><td>[1, 2]</td><td>3</td></tr>
<tr><td>14</td><td>603</td><td>—</td><td>—</td><td>[1, 2]</td><td>4</td></tr>
<tr><td>15</td><td>507</td><td>204</td><td>303</td><td>[3]</td><td>4</td></tr>
<tr><td>16</td><td>206</td><td>604</td><td>—</td><td>[1, 2]</td><td>4</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderFixedConfig.json">完整原记录</a></p></details>

**OrderAvatarConfig字段含义：** NormalAvatars的Id/UnlockLevel用于解锁候选；其它分类按订单类型与活动资格读取，已占用头像尽量排除；仅表现头像，不参与需求价格与难度。

<details><summary>OrderAvatarConfig：9条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>分类</th><th>记录</th></tr></thead><tbody>
<tr><td>BakeOutAvatars</td><td>{&quot;201&quot;: &quot;Colby&quot;, &quot;202&quot;: &quot;Poppy&quot;, &quot;203&quot;: &quot;Ruben&quot;}</td></tr>
<tr><td>NormalAvatars</td><td>[{&quot;UnlockLevel&quot;: 2, &quot;Id&quot;: 1, &quot;Avatar&quot;: &quot;Lily&quot;}, {&quot;UnlockLevel&quot;: 5, &quot;Id&quot;: 2, &quot;Avatar&quot;: &quot;Lucy&quot;}, {&quot;Id&quot;: 3, &quot;Avatar&quot;: &quot;Harry&quot;}, {&quot;UnlockLevel&quot;: 3, &quot;Id&quot;: 4, &quot;Avatar&quot;: &quot;Mark&quot;}, {&quot;UnlockLevel&quot;: 4, &quot;Id&quot;: 5, &quot;Avatar&quot;: &quot;Norman&quot;}, {&quot;UnlockLevel&quot;: 999, &quot;Id&quot;: 6, &quot;Avatar&quot;: &quot;Olivia&quot;}, {&quot;Id&quot;: 7, &quot;Avatar&quot;: &quot;Amala&quot;}, {&quot;Id&quot;: 8, &quot;Avatar&quot;: &quot;Karla&quot;}]</td></tr>
<tr><td>CharacterIntimacyAvatars</td><td>{&quot;601&quot;: &quot;Gerald&quot;}</td></tr>
<tr><td>BranchAvatars</td><td>{&quot;401&quot;: &quot;Quinn&quot;}</td></tr>
<tr><td>SpecialAvatars</td><td>{&quot;104&quot;: &quot;Carmen&quot;, &quot;105&quot;: &quot;Olivia&quot;, &quot;106&quot;: &quot;Coconut&quot;, &quot;101&quot;: &quot;Sam&quot;, &quot;102&quot;: &quot;Olivia&quot;, &quot;103&quot;: &quot;Harrison&quot;}</td></tr>
<tr><td>ExtraCustomerAvatars</td><td>{&quot;3001&quot;: &quot;panda&quot;}</td></tr>
<tr><td>TimedOrderAvatars</td><td>{&quot;802&quot;: &quot;Banana&quot;, &quot;801&quot;: &quot;Raccoon2&quot;}</td></tr>
<tr><td>ContiorderAvatars</td><td>{&quot;2001&quot;: &quot;contiorders&quot;}</td></tr>
<tr><td>ChestCustomerAvatars</td><td>{&quot;1004&quot;: &quot;ChestRaccoon4&quot;, &quot;1001&quot;: &quot;ChestRaccoon1&quot;, &quot;1002&quot;: &quot;ChestRaccoon2&quot;, &quot;1003&quot;: &quot;ChestRaccoon3&quot;}</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderAvatarConfig.json">完整原记录</a></p></details>

<details><summary>OrderAvatarConfig_more：9条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>分类</th><th>记录</th></tr></thead><tbody>
<tr><td>BakeOutAvatars</td><td>{&quot;201&quot;: &quot;Colby&quot;, &quot;202&quot;: &quot;Poppy&quot;, &quot;203&quot;: &quot;Ruben&quot;}</td></tr>
<tr><td>NormalAvatars</td><td>[{&quot;UnlockLevel&quot;: 2, &quot;Id&quot;: 1, &quot;Avatar&quot;: &quot;Lily&quot;}, {&quot;UnlockLevel&quot;: 5, &quot;Id&quot;: 2, &quot;Avatar&quot;: &quot;Lucy&quot;}, {&quot;Id&quot;: 3, &quot;Avatar&quot;: &quot;Harry&quot;}, {&quot;UnlockLevel&quot;: 3, &quot;Id&quot;: 4, &quot;Avatar&quot;: &quot;Mark&quot;}, {&quot;UnlockLevel&quot;: 4, &quot;Id&quot;: 5, &quot;Avatar&quot;: &quot;Norman&quot;}, {&quot;UnlockLevel&quot;: 999, &quot;Id&quot;: 6, &quot;Avatar&quot;: &quot;Olivia&quot;}, {&quot;Id&quot;: 7, &quot;Avatar&quot;: &quot;Amala&quot;}, {&quot;Id&quot;: 8, &quot;Avatar&quot;: &quot;Karla&quot;}, {&quot;UnlockLevel&quot;: 7, &quot;Id&quot;: 11, &quot;Avatar&quot;: &quot;Colton&quot;}, {&quot;UnlockLevel&quot;: 25, &quot;Id&quot;: 12, &quot;Avatar&quot;: &quot;Vance&quot;}, {&quot;UnlockLevel&quot;: 29, &quot;Id&quot;: 13, &quot;Avatar&quot;: &quot;Sophia&quot;}, {&quot;UnlockLevel&quot;: 56, &quot;Id&quot;: 14, &quot;Avatar&quot;: &quot;Dominic&quot;}, {&quot;UnlockLevel&quot;: 66, &quot;Id&quot;: 15, &quot;Avatar&quot;: &quot;Imelda&quot;}, {&quot;UnlockLevel&quot;: 76, &quot;Id&quot;: 16, &quot;Avatar&quot;: &quot;Saul&quot;}, {&quot;UnlockLevel&quot;: 85, &quot;Id&quot;: 17, &quot;Avatar&quot;: &quot;Riley&quot;}, {&quot;UnlockLevel&quot;: 90, &quot;Id&quot;: 18, &quot;Avatar&quot;: &quot;Frankie&quot;}, {&quot;UnlockLevel&quot;: 192, &quot;Id&quot;: 19, &quot;Avatar&quot;: &quot;Tony&quot;}, {&quot;UnlockLevel&quot;: 218, &quot;Id&quot;: 20, &quot;Avatar&quot;: &quot;Atlas&quot;}]</td></tr>
<tr><td>CharacterIntimacyAvatars</td><td>{&quot;601&quot;: &quot;Gerald&quot;}</td></tr>
<tr><td>BranchAvatars</td><td>{&quot;401&quot;: &quot;Quinn&quot;}</td></tr>
<tr><td>SpecialAvatars</td><td>{&quot;104&quot;: &quot;Carmen&quot;, &quot;105&quot;: &quot;Olivia&quot;, &quot;106&quot;: &quot;Coconut&quot;, &quot;101&quot;: &quot;Sam&quot;, &quot;102&quot;: &quot;Olivia&quot;, &quot;103&quot;: &quot;Harrison&quot;}</td></tr>
<tr><td>ExtraCustomerAvatars</td><td>{&quot;3001&quot;: &quot;panda&quot;}</td></tr>
<tr><td>TimedOrderAvatars</td><td>{&quot;802&quot;: &quot;Banana&quot;, &quot;801&quot;: &quot;Raccoon2&quot;}</td></tr>
<tr><td>ContiorderAvatars</td><td>{&quot;2001&quot;: &quot;contiorders&quot;}</td></tr>
<tr><td>ChestCustomerAvatars</td><td>{&quot;1004&quot;: &quot;ChestRaccoon4&quot;, &quot;1001&quot;: &quot;ChestRaccoon1&quot;, &quot;1002&quot;: &quot;ChestRaccoon2&quot;, &quot;1003&quot;: &quot;ChestRaccoon3&quot;}</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderAvatarConfig_more.json">完整原记录</a></p></details>

## 源码依据

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)。对应：MainOrderModel:_TryCreateOrder（恢复文本行527）；MainOrderModel:GetAvatarId（恢复文本行669）；MainOrderModel:_AddGiftRewardInfo（恢复文本行862）

- Board.Model.Order.MainOrderCreator：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreator.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreator.disassembly.txt)

- Board.Model.Order.MainOrderCreatorRandom：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreatorRandom.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreatorRandom.disassembly.txt)


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：固定单先于随机单

**完整输入（演示设定）：** 假设槽1空，固定进度0，下一条Id1允许槽1、UnlockLevel1，玩家10；配置需求203、头像6。其它创建器即使有资格也不再调用。

**按执行顺序代入：** Fixed.Create：10≥1且槽1匹配→进度写1，构造需求[203]；Return/Tutorial/Conti/Extra/Lucky/Random Create次数均0。

**玩家看到的结果：** 槽1出现固定需求203的新顾客；不消耗普通随机创建次数，也没有额外Lucky需求。
