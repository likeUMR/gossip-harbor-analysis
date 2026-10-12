# 特殊任务交付：具体算法与配置

先Slot模型FinishOrder，再GetSpecialOrderConfig：Special取GetSpecialOrderConfigWithOffset(0)，并非用任意传入Id直接索引。Requirement1..3的链加入集合；GeneratorChain可为字符串或数组，IsInGeneratorChain按相等/逐项判断。itemFilter对Bubble用innerCode，其余GetType；缓存用typeFilter直接查code链。_BatchRemoveItems按有效格序RemoveItem(默认刷新)，仓库while索引删除后不自增以防跳过，删除持久化属性；缓存同样删后不自增；最后ChangeCachedItems→InventoryItemUpdate。返回Removed只有棋盘对象，不能据此以为仓库/缓存没有删除。之后UpdateOrderState→AcquireRewardsLogic(Rewards,Give,SpecialTaskComplete,Main,Type2)→MapData.SetSlot(EndTimeline,"1")→局部FinishSpecialOrder。默认特殊Id1需求1610，GeneratorChain15，奖励gem15/energy100。

## 对应本地配表

各后缀为可选变体，不是同时叠加。require受FileReplace精确文件名首匹配替换，失败才回退默认；实际账号选择及远端档位未取得。缺字段记“—”，不能当0。下方保留全记录与全部字段；嵌套Filters/Rewards可横向滚动查看。

**OrderSpecialConfig字段含义：** Id按CurrentSpecialOrderId索引，Requirement1..3决定清除链，GeneratorChain为额外清除母体链；Rewards解析货币字符串；EndTimeline为完成标记；Trigger任务进度用于创建前资格；StartReward/StartTimeline/Avatar/图像/颜色属于创建与显示。

<details><summary>OrderSpecialConfig：6条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>AvatarId</th><th>AvatarImage</th><th>BigAvatarImage</th><th>CompleteImage</th><th>DescriptionKey</th><th>EndTimeline</th><th>FrameColor</th><th>GeneratorChain</th><th>Id</th><th>Requirement1</th><th>Requirement2</th><th>RewardImage</th><th>Rewards</th><th>StartReward</th><th>StartTimeline</th><th>Trigger</th></tr></thead><tbody>
<tr><td>101</td><td>sam</td><td>special_order_sam</td><td>special_order_1_complete</td><td>special_order_desc_1</td><td>special_order_1</td><td>{&quot;b&quot;: 1.0, &quot;r&quot;: 0.5568627450980392, &quot;g&quot;: 0.5568627450980392}</td><td>15</td><td>1</td><td>1610</td><td>—</td><td>special_order_1_reward</td><td>[&quot;gem-15&quot;, &quot;energy-100&quot;]</td><td>—</td><td>special_order_1_begin</td><td>taskFinish-2_7</td></tr>
<tr><td>102</td><td>olivia</td><td>special_order_olivia</td><td>special_order_2_complete</td><td>special_order_desc_2</td><td>special_order_2</td><td>{&quot;b&quot;: 0.3215686274509804, &quot;r&quot;: 1.0, &quot;g&quot;: 0.592156862745098}</td><td>19</td><td>2</td><td>2010</td><td>—</td><td>special_order_2_reward</td><td>[&quot;gem-20&quot;, &quot;energy-100&quot;]</td><td>—</td><td>special_order_2_begin</td><td>taskFinish-11_6</td></tr>
<tr><td>103</td><td>harrison</td><td>special_order_harrison</td><td>special_order_3_complete</td><td>special_order_desc_3</td><td>special_order_3_finish</td><td>{&quot;b&quot;: 1.0, &quot;r&quot;: 0.43529411764705883, &quot;g&quot;: 0.6823529411764706}</td><td>sp3_1</td><td>3</td><td>sp3_2_10</td><td>sp3_3_6</td><td>special_order_3_reward</td><td>[&quot;gem-30&quot;, &quot;energy-150&quot;]</td><td>sp3_1_1</td><td>special_order_3_begin</td><td>taskFinish-18_7</td></tr>
<tr><td>104</td><td>carmen</td><td>special_order_carmen</td><td>special_order_4_complete</td><td>special_order_desc_4</td><td>special_order_4</td><td>{&quot;b&quot;: 0.5803921568627451, &quot;r&quot;: 0.9803921568627451, &quot;g&quot;: 0.7450980392156863}</td><td>[&quot;sp4_1&quot;, &quot;sp4_2&quot;]</td><td>4</td><td>sp4_3_10</td><td>—</td><td>special_order_4_reward</td><td>[&quot;gem-30&quot;, &quot;energy-150&quot;]</td><td>sp4_1_1</td><td>special_order_4_begin</td><td>taskFinish-24_3</td></tr>
<tr><td>105</td><td>olivia</td><td>special_order_olivia</td><td>special_order_5_complete</td><td>special_order_desc_5</td><td>special_order_5</td><td>{&quot;b&quot;: 0.3215686274509804, &quot;r&quot;: 1.0, &quot;g&quot;: 0.592156862745098}</td><td>[&quot;sp5_1&quot;]</td><td>5</td><td>sp5_2_10</td><td>—</td><td>special_order_5_reward</td><td>[&quot;gem-25&quot;, &quot;energy-200&quot;]</td><td>sp5_1_1</td><td>special_order_5_begin</td><td>taskFinish-29_8</td></tr>
<tr><td>106</td><td>coconut</td><td>special_order_coconut</td><td>special_order_6_complete</td><td>special_order_desc_6</td><td>special_order_6</td><td>{&quot;b&quot;: 0.7529411764705882, &quot;r&quot;: 1.0, &quot;g&quot;: 0.984313725490196}</td><td>[&quot;sp6_1&quot;]</td><td>6</td><td>sp6_2_10</td><td>—</td><td>special_order_6_reward</td><td>[&quot;gem-25&quot;, &quot;energy-200&quot;]</td><td>sp6_1_1</td><td>special_order_6_begin</td><td>taskFinish-33_9</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderSpecialConfig.json">完整原记录</a></p></details>

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:GetSpecialOrderConfig（恢复文本行1245）；MainBoardModel:_FinishSpecialOrder（恢复文本行1258）；MainBoardModel.IsInGeneratorChain（恢复文本行1335）；MainBoardModel:_BatchRemoveItems（恢复文本行1475）

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)。对应：MainOrderModel:GetSpecialOrderConfig（恢复文本行1214）

- Board.Model.Order.MainOrderCreator：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreator.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreator.disassembly.txt)


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：特殊任务完成清链

**完整输入（演示设定）：** 本地特殊Id1：需求1610、GeneratorChain15、奖励宝石15/能量100；假设任务有效，棋盘1610/1501、仓库1601、缓存1502各1，初始宝石20、能量10，无其它16/15链物。

**按执行顺序代入：** 清链16及15：移除上述4件；Rewards=[Gem15,Energy100]→20+15=35、10+100=110；special_order_1=1；普通价格/扣需求链不执行。

**玩家看到的结果：** 两条任务相关链从棋盘、仓库和缓存清除；宝石变35、能量变110，任务1完成。
