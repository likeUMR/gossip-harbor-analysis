# 初始化字段、进度公式和恢复重置

`Init` 先深拷贝 `Spread_Weight`，再把次数和储备初始化为各自最大值。`Spread_InitDuration` 非空时状态为 `Initializing` 并立即 `UpdatePerSecond`；否则 `Spread_OpenDuration` 非空时状态为 `Closed`；否则直接 `Opened`。教程强制时长只对原本存在的 init/open/item-recovery/storage-recovery 字段替换。计时进度由 `elapsed = serverTime - m_startTimer`、`amount=min(elapsed/duration,1)` 得到；没有 duration 时记录完整字段诊断并把起点清空，duration 为 0 直接视为完成。`GetTimerDuration` 在 Initializing/Opening 读取对应阶段时长，在 Opened 依据 `m_storageRestNumber==0` 选择储备恢复或单轮恢复。完成后 `_UpdateRecoveryState` 要么转为 Opened，要么补满次数并扣除储备；储备耗尽时把起点推进一个 item recovery duration 再递归重算。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
<!-- reconciliation-persistence:start -->
## 存档如何恢复当前母体

主棋盘继承 BaseActionBoardModel；`SaveItemProperty` 调用 ItemManager:SetItem，不是 BaseBoardModel 的空实现。同步数据结束时，ItemManager 逐行读取 Item 表，经 ItemModelFactory.CreateWithData 重建母体。先 CreateWithCode 按当前配置创建对象和组件，再覆盖存档状态；不是只保存类型，重新登录就补满次数。

| 实例字段 | 存档列 | 恢复方法 |
| --- | --- | --- |
| m_state | spreadState | 原样覆盖；无默认状态替代 |
| m_startTimer | spreadStartTimer | 原样覆盖；缺字段成为nil |
| m_itemRestNumber | spreadItemRestNumber | 原样覆盖，不自动补满 |
| m_storageRestNumber | spreadStorageRestNumber | 原样覆盖，不自动补满 |
| m_spreadCount | spreadCount | 缺值才用0 |
| m_codeWeightPairs | spreadCodeWeightPairs | 解析存档字符串，覆盖配置初始池 |

如果按代码创建对象失败，工厂返回nil；ItemManager记ItemNotFound并删除该存档行。主棋盘成功恢复后标记棋子类型已解锁。恢复函数本身没有重新推进冷却；时间推进由随后UpdatePerSecond处理。当前配置的上限、时长和权重模式仍来自创建过程，存档只恢复上表的运行值。

<!-- reconciliation-persistence:end -->

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明状态值如何映射成玩家看到的已打开、开启中等状态，并决定是否允许产出。

### 代入本页的值

假设模型状态值从服务端读到 3，映射为 `Opened`，因此允许点击；若读到 2，映射为 `Opening`，只发送打开中事件，不调用产出函数。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

<a id="configuration-item-model"></a>

## 本页涉及的配表：母体配置与包内变体

**实际读取链**：`ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。`

本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。


### ItemModelConfig：全部可产出母体（163 条）

来源：`analysis_data/json/ItemModelConfig.json`。时长单位为秒；“未配置”不等于 0。完整记录保留本页相关母体的全部原始字段。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 163 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>母体/棋子 ID<small style="display:block">Type</small></th><th>自动产出<small style="display:block">Spread_Auto</small></th><th>是否消耗能量<small style="display:block">Spread_CostEnergy</small></th><th>初始化时长（秒）<small style="display:block">Spread_InitDuration</small></th><th>初始化加速（宝石）<small style="display:block">Spread_InitSpeedUpCost</small></th><th>单轮次数上限<small style="display:block">Spread_ItemMaxNumber</small></th><th>单轮恢复（秒）<small style="display:block">Spread_ItemRecoveryDuration</small></th><th>单轮加速（宝石）<small style="display:block">Spread_ItemSpeedUpCost</small></th><th>开启时长（秒）<small style="display:block">Spread_OpenDuration</small></th><th>开启加速（宝石）<small style="display:block">Spread_OpenSpeedUpCost</small></th><th>储备次数上限<small style="display:block">Spread_StorageMaxNumber</small></th><th>储备恢复（秒）<small style="display:block">Spread_StorageRecoveryDuration</small></th><th>储备加速（宝石）<small style="display:block">Spread_StorageSpeedUpCost</small></th><th>变换点击次数<small style="display:block">Spread_TransformNumber</small></th><th>普通产物 × 权重<small style="display:block">Spread_Weight</small></th><th>产出模式<small style="display:block">Spread_WeightType</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/104.png" alt="104"><span><b>104</b><small>满载购物袋</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>2</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>30</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 100</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;105&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 2,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 2,
  &quot;Spread_ItemSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 30,
  &quot;Spread_StorageSpeedUpCost&quot;: 1,
  &quot;Spread_Weight&quot;: [
    &quot;201-100&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;104&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>30</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>60</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;106&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 3,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 30,
  &quot;Spread_ItemSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 60,
  &quot;Spread_StorageSpeedUpCost&quot;: 1,
  &quot;Spread_Weight&quot;: [
    &quot;201-35&quot;,
    &quot;202-2&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;105&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;107&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 4,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;201-34&quot;,
    &quot;202-2&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;106&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;108&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 5,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;201-33&quot;,
    &quot;202-3&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;107&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;109&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 6,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;201-32&quot;,
    &quot;202-4&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;108&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 31<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;110&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 7,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;201-31&quot;,
    &quot;202-5&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;109&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 31<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;111&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 8,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;201-31&quot;,
    &quot;202-4&quot;,
    &quot;203-2&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;110&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 31<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/302.png" alt="302"><span><b>302</b><small>切片土豆</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 9,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;201-31&quot;,
    &quot;202-4&quot;,
    &quot;203-2&quot;,
    &quot;301-4&quot;,
    &quot;302-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;111&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/404.png" alt="404"><span><b>404</b><small>无咖啡因咖啡壶</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>6</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>120</td><td>2</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 100</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;405&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 2,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 6,
  &quot;Spread_ItemSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 120,
  &quot;Spread_StorageSpeedUpCost&quot;: 2,
  &quot;Spread_Weight&quot;: [
    &quot;501-100&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;404&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 37<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;406&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 3,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;501-37&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;405&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;407&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 4,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;501-34&quot;,
    &quot;502-2&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;406&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;408&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 5,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;501-33&quot;,
    &quot;502-3&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;407&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;409&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 6,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;501-32&quot;,
    &quot;502-4&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;408&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 31<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;410&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 7,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;501-31&quot;,
    &quot;502-5&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;409&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 31<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;411&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 8,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;501-31&quot;,
    &quot;502-4&quot;,
    &quot;503-2&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;410&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>240</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 31<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/602.png" alt="602"><span><b>602</b><small>热茶</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 9,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 240,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;501-31&quot;,
    &quot;502-4&quot;,
    &quot;503-2&quot;,
    &quot;601-4&quot;,
    &quot;602-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;411&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/705.png" alt="705"><span><b>705</b><small>鱼网</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>26</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>78</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 100</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;706&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 3,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 78,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;801-100&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;705&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/706.png" alt="706"><span><b>706</b><small>贝类网</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>26</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>78</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;707&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 4,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 78,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;801-90&quot;,
    &quot;802-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;706&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/707.png" alt="707"><span><b>707</b><small>大贝类网</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>26</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>78</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 85<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;708&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 5,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 78,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;801-85&quot;,
    &quot;802-15&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;707&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/708.png" alt="708"><span><b>708</b><small>高级钓鱼冷却器</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>26</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>78</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 85<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;709&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 6,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 78,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;801-85&quot;,
    &quot;802-10&quot;,
    &quot;803-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;708&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/709.png" alt="709"><span><b>709</b><small>鱼箱</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>26</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>78</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 82<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;710&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 7,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 78,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;801-82&quot;,
    &quot;802-13&quot;,
    &quot;803-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;709&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/710.png" alt="710"><span><b>710</b><small>爱好者鱼缸</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>26</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>78</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 80<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;711&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 8,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 78,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;801-80&quot;,
    &quot;802-15&quot;,
    &quot;803-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;710&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/711.png" alt="711"><span><b>711</b><small>豪华海鲜柜</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>26</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>78</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 80<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/901.png" alt="901"><span><b>901</b><small>鲑鱼片</small></span></span> × 20</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 9,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 78,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;801-80&quot;,
    &quot;802-15&quot;,
    &quot;803-5&quot;,
    &quot;901-20&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;711&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/901.png" alt="901"><span><b>901</b><small>鲑鱼片</small></span></span> × 95<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/902.png" alt="902"><span><b>902</b><small>蜂蜜釉面鲑鱼</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 10,
  &quot;LevelDownPiece&quot;: 1,
  &quot;SellingPrice&quot;: 3,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_Weight&quot;: [
    &quot;901-95&quot;,
    &quot;902-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;805&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1006.png" alt="1006"><span><b>1006</b><small>杂交树</small></span></span></td><td>1</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td>3600</td><td>55</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td>7200</td><td>97</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1101.png" alt="1101"><span><b>1101</b><small>橙子</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1007&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 4,
  &quot;Spread_Auto&quot;: 1,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_ItemRecoveryDuration&quot;: 3600,
  &quot;Spread_ItemSpeedUpCost&quot;: 55,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_StorageRecoveryDuration&quot;: 7200,
  &quot;Spread_StorageSpeedUpCost&quot;: 97,
  &quot;Spread_Weight&quot;: [
    &quot;1101-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1006&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1007.png" alt="1007"><span><b>1007</b><small>成熟的树</small></span></span></td><td>1</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td>4800</td><td>68</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>16</td><td>9600</td><td>121</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1101.png" alt="1101"><span><b>1101</b><small>橙子</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1008&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 5,
  &quot;Spread_Auto&quot;: 1,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_ItemRecoveryDuration&quot;: 4800,
  &quot;Spread_ItemSpeedUpCost&quot;: 68,
  &quot;Spread_StorageMaxNumber&quot;: 16,
  &quot;Spread_StorageRecoveryDuration&quot;: 9600,
  &quot;Spread_StorageSpeedUpCost&quot;: 121,
  &quot;Spread_Weight&quot;: [
    &quot;1101-90&quot;,
    &quot;1102-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1007&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1008.png" alt="1008"><span><b>1008</b><small>盆栽橙树</small></span></span></td><td>1</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td>6600</td><td>88</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>20</td><td>13200</td><td>165</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1101.png" alt="1101"><span><b>1101</b><small>橙子</small></span></span> × 80<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 20</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1009&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 6,
  &quot;Spread_Auto&quot;: 1,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_ItemRecoveryDuration&quot;: 6600,
  &quot;Spread_ItemSpeedUpCost&quot;: 88,
  &quot;Spread_StorageMaxNumber&quot;: 20,
  &quot;Spread_StorageRecoveryDuration&quot;: 13200,
  &quot;Spread_StorageSpeedUpCost&quot;: 165,
  &quot;Spread_Weight&quot;: [
    &quot;1101-80&quot;,
    &quot;1102-20&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1008&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1009.png" alt="1009"><span><b>1009</b><small>丰收橙树</small></span></span></td><td>1</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td>9600</td><td>121</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>24</td><td>19200</td><td>234</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1101.png" alt="1101"><span><b>1101</b><small>橙子</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 25</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1010&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 7,
  &quot;Spread_Auto&quot;: 1,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_ItemRecoveryDuration&quot;: 9600,
  &quot;Spread_ItemSpeedUpCost&quot;: 121,
  &quot;Spread_StorageMaxNumber&quot;: 24,
  &quot;Spread_StorageRecoveryDuration&quot;: 19200,
  &quot;Spread_StorageSpeedUpCost&quot;: 234,
  &quot;Spread_Weight&quot;: [
    &quot;1101-75&quot;,
    &quot;1102-25&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1009&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1010.png" alt="1010"><span><b>1010</b><small>硕果累累橙树</small></span></span></td><td>1</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td>9600</td><td>121</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>24</td><td>19200</td><td>234</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1101.png" alt="1101"><span><b>1101</b><small>橙子</small></span></span> × 80<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 8,
  &quot;Spread_Auto&quot;: 1,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_ItemRecoveryDuration&quot;: 9600,
  &quot;Spread_ItemSpeedUpCost&quot;: 121,
  &quot;Spread_StorageMaxNumber&quot;: 24,
  &quot;Spread_StorageRecoveryDuration&quot;: 19200,
  &quot;Spread_StorageSpeedUpCost&quot;: 234,
  &quot;Spread_Weight&quot;: [
    &quot;1101-80&quot;,
    &quot;1102-15&quot;,
    &quot;1103-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1010&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1205.png" alt="1205"><span><b>1205</b><small>豪华泳池包</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>36</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>108</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 100</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1206&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 3,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 108,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1301-100&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1205&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1206.png" alt="1206"><span><b>1206</b><small>高级海洋储存箱</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>36</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>108</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1207&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 4,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 108,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1301-34&quot;,
    &quot;1401-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1206&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>36</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>108</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1208&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 5,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 108,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1301-33&quot;,
    &quot;1302-1&quot;,
    &quot;1401-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1207&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>36</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>108</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1209&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 6,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 108,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1301-34&quot;,
    &quot;1302-1&quot;,
    &quot;1303-1&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1208&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>36</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>108</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1210&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 7,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 108,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1301-33&quot;,
    &quot;1302-2&quot;,
    &quot;1303-1&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1209&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>36</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>108</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1211&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 8,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 108,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1301-32&quot;,
    &quot;1302-3&quot;,
    &quot;1303-1&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1210&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>36</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>108</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1402.png" alt="1402"><span><b>1402</b><small>潜水护目镜</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 8,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 108,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1301-32&quot;,
    &quot;1302-3&quot;,
    &quot;1303-1&quot;,
    &quot;1401-5&quot;,
    &quot;1402-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1211&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1504.png" alt="1504"><span><b>1504</b><small>入门狗屋</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td>9000</td><td>117</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td>18000</td><td>220</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1601.png" alt="1601"><span><b>1601</b><small>小吉娃娃</small></span></span> × 100</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1505&quot;,
  &quot;SellingPrice&quot;: 2,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_ItemRecoveryDuration&quot;: 9000,
  &quot;Spread_ItemSpeedUpCost&quot;: 117,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_StorageRecoveryDuration&quot;: 18000,
  &quot;Spread_StorageSpeedUpCost&quot;: 220,
  &quot;Spread_Weight&quot;: [
    &quot;1601-100&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1504&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1505.png" alt="1505"><span><b>1505</b><small>普通狗屋</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td>14400</td><td>180</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>16</td><td>28800</td><td>348</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1601.png" alt="1601"><span><b>1601</b><small>小吉娃娃</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1602.png" alt="1602"><span><b>1602</b><small>茶杯犬</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1506&quot;,
  &quot;SellingPrice&quot;: 3,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_ItemRecoveryDuration&quot;: 14400,
  &quot;Spread_ItemSpeedUpCost&quot;: 180,
  &quot;Spread_StorageMaxNumber&quot;: 16,
  &quot;Spread_StorageRecoveryDuration&quot;: 28800,
  &quot;Spread_StorageSpeedUpCost&quot;: 348,
  &quot;Spread_Weight&quot;: [
    &quot;1601-90&quot;,
    &quot;1602-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1505&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1506.png" alt="1506"><span><b>1506</b><small>舒适的狗屋</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td>19800</td><td>242</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>20</td><td>39600</td><td>468</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1601.png" alt="1601"><span><b>1601</b><small>小吉娃娃</small></span></span> × 80<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1602.png" alt="1602"><span><b>1602</b><small>茶杯犬</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1603.png" alt="1603"><span><b>1603</b><small>完美的哈巴狗</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1507&quot;,
  &quot;SellingPrice&quot;: 4,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_ItemRecoveryDuration&quot;: 19800,
  &quot;Spread_ItemSpeedUpCost&quot;: 242,
  &quot;Spread_StorageMaxNumber&quot;: 20,
  &quot;Spread_StorageRecoveryDuration&quot;: 39600,
  &quot;Spread_StorageSpeedUpCost&quot;: 468,
  &quot;Spread_Weight&quot;: [
    &quot;1601-80&quot;,
    &quot;1602-15&quot;,
    &quot;1603-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1506&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1507.png" alt="1507"><span><b>1507</b><small>奢华的狗屋</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td>21600</td><td>266</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>24</td><td>43200</td><td>502</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1601.png" alt="1601"><span><b>1601</b><small>小吉娃娃</small></span></span> × 70<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1602.png" alt="1602"><span><b>1602</b><small>茶杯犬</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1603.png" alt="1603"><span><b>1603</b><small>完美的哈巴狗</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;SellingPrice&quot;: 5,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_ItemRecoveryDuration&quot;: 21600,
  &quot;Spread_ItemSpeedUpCost&quot;: 266,
  &quot;Spread_StorageMaxNumber&quot;: 24,
  &quot;Spread_StorageRecoveryDuration&quot;: 43200,
  &quot;Spread_StorageSpeedUpCost&quot;: 502,
  &quot;Spread_Weight&quot;: [
    &quot;1601-70&quot;,
    &quot;1602-20&quot;,
    &quot;1603-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1507&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1705.png" alt="1705"><span><b>1705</b><small>小珊瑚丛</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 100</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1706&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 3,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 126,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1801-100&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1705&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 95<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1707&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 4,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 126,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1801-95&quot;,
    &quot;1802-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1706&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1708&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 5,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 126,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1801-90&quot;,
    &quot;1802-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1707&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 8<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 2</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1709&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 6,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 126,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1801-90&quot;,
    &quot;1802-8&quot;,
    &quot;1803-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1708&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 89<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 8<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1710&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 7,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 126,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1801-89&quot;,
    &quot;1802-8&quot;,
    &quot;1803-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1709&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 88<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1711&quot;,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 8,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 126,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1801-88&quot;,
    &quot;1802-9&quot;,
    &quot;1803-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1710&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 87<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 9,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_StorageMaxNumber&quot;: 126,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;1801-87&quot;,
    &quot;1802-9&quot;,
    &quot;1803-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1711&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1903.png" alt="1903"><span><b>1903</b><small>散装板条箱</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>4</td><td>3600</td><td>55</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td>7200</td><td>97</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2001.png" alt="2001"><span><b>2001</b><small>单块模型</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1904&quot;,
  &quot;SellingPrice&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 4,
  &quot;Spread_ItemRecoveryDuration&quot;: 3600,
  &quot;Spread_ItemSpeedUpCost&quot;: 55,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_StorageRecoveryDuration&quot;: 7200,
  &quot;Spread_StorageSpeedUpCost&quot;: 97,
  &quot;Spread_Weight&quot;: [
    &quot;2001-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1903&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1904.png" alt="1904"><span><b>1904</b><small>半吊子货箱</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td>7200</td><td>97</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td>14400</td><td>180</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2001.png" alt="2001"><span><b>2001</b><small>单块模型</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2002.png" alt="2002"><span><b>2002</b><small>长条状模型</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1905&quot;,
  &quot;SellingPrice&quot;: 2,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_ItemRecoveryDuration&quot;: 7200,
  &quot;Spread_ItemSpeedUpCost&quot;: 97,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_StorageRecoveryDuration&quot;: 14400,
  &quot;Spread_StorageSpeedUpCost&quot;: 180,
  &quot;Spread_Weight&quot;: [
    &quot;2001-90&quot;,
    &quot;2002-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1904&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1905.png" alt="1905"><span><b>1905</b><small>块状板条箱</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td>10800</td><td>138</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>16</td><td>21600</td><td>266</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2001.png" alt="2001"><span><b>2001</b><small>单块模型</small></span></span> × 80<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2002.png" alt="2002"><span><b>2002</b><small>长条状模型</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2003.png" alt="2003"><span><b>2003</b><small>堆积模型</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;MergedType&quot;: &quot;1906&quot;,
  &quot;SellingPrice&quot;: 3,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_ItemRecoveryDuration&quot;: 10800,
  &quot;Spread_ItemSpeedUpCost&quot;: 138,
  &quot;Spread_StorageMaxNumber&quot;: 16,
  &quot;Spread_StorageRecoveryDuration&quot;: 21600,
  &quot;Spread_StorageSpeedUpCost&quot;: 266,
  &quot;Spread_Weight&quot;: [
    &quot;2001-80&quot;,
    &quot;2002-15&quot;,
    &quot;2003-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1905&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1906.png" alt="1906"><span><b>1906</b><small>积木建筑箱</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td>14400</td><td>180</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>20</td><td>28800</td><td>348</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2001.png" alt="2001"><span><b>2001</b><small>单块模型</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2002.png" alt="2002"><span><b>2002</b><small>长条状模型</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2003.png" alt="2003"><span><b>2003</b><small>堆积模型</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;LevelDownPiece&quot;: 1,
  &quot;SellingPrice&quot;: 4,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_ItemRecoveryDuration&quot;: 14400,
  &quot;Spread_ItemSpeedUpCost&quot;: 180,
  &quot;Spread_StorageMaxNumber&quot;: 20,
  &quot;Spread_StorageRecoveryDuration&quot;: 28800,
  &quot;Spread_StorageSpeedUpCost&quot;: 348,
  &quot;Spread_Weight&quot;: [
    &quot;2001-75&quot;,
    &quot;2002-15&quot;,
    &quot;2003-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;1906&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2701.png" alt="2701"><span><b>2701</b><small>红色宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>480</td><td>8</td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/101.png" alt="101"><span><b>101</b><small>空棕色袋子</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/401.png" alt="401"><span><b>401</b><small>散装咖啡豆</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/701.png" alt="701"><span><b>701</b><small>单钩</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;2702&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_OpenDuration&quot;: 480,
  &quot;Spread_OpenSpeedUpCost&quot;: 8,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_Weight&quot;: [
    &quot;101-2&quot;,
    &quot;401-1&quot;,
    &quot;701-1&quot;,
    &quot;2401-2&quot;,
    &quot;2501-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;2701&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2702.png" alt="2702"><span><b>2702</b><small>高级红色宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>1200</td><td>19</td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/102.png" alt="102"><span><b>102</b><small>小棕色包</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/402.png" alt="402"><span><b>402</b><small>麻布袋装咖啡豆</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/702.png" alt="702"><span><b>702</b><small>钓具</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 3</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_OpenDuration&quot;: 1200,
  &quot;Spread_OpenSpeedUpCost&quot;: 19,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_Weight&quot;: [
    &quot;102-2&quot;,
    &quot;402-1&quot;,
    &quot;702-1&quot;,
    &quot;2401-1&quot;,
    &quot;2501-1&quot;,
    &quot;2402-3&quot;,
    &quot;2502-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;2702&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2801.png" alt="2801"><span><b>2801</b><small>绿色宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>480</td><td>8</td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1201.png" alt="1201"><span><b>1201</b><small>泳池垃圾桶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1001.png" alt="1001"><span><b>1001</b><small>橙子种子</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1701.png" alt="1701"><span><b>1701</b><small>海石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;2802&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_OpenDuration&quot;: 480,
  &quot;Spread_OpenSpeedUpCost&quot;: 8,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_Weight&quot;: [
    &quot;1201-2&quot;,
    &quot;1001-1&quot;,
    &quot;1701-1&quot;,
    &quot;2401-2&quot;,
    &quot;2501-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;2801&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2802.png" alt="2802"><span><b>2802</b><small>高级绿色宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>1200</td><td>19</td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1202.png" alt="1202"><span><b>1202</b><small>泳池篮</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1002.png" alt="1002"><span><b>1002</b><small>橙子芽</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1702.png" alt="1702"><span><b>1702</b><small>堆石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 3</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_OpenDuration&quot;: 1200,
  &quot;Spread_OpenSpeedUpCost&quot;: 19,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_Weight&quot;: [
    &quot;1202-2&quot;,
    &quot;1002-1&quot;,
    &quot;1702-1&quot;,
    &quot;2401-1&quot;,
    &quot;2501-1&quot;,
    &quot;2402-3&quot;,
    &quot;2502-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;2802&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2901.png" alt="2901"><span><b>2901</b><small>体力箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 40<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 30<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 5,
  &quot;Spread_StorageMaxNumber&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;2601-40&quot;,
    &quot;2602-30&quot;,
    &quot;2603-20&quot;,
    &quot;2604-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;2901&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/3001.png" alt="3001"><span><b>3001</b><small>野餐篮</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 5,
  &quot;Spread_StorageMaxNumber&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;203-5&quot;,
    &quot;204-4&quot;,
    &quot;303-1&quot;,
    &quot;503-5&quot;,
    &quot;504-4&quot;,
    &quot;603-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;3001&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/3101.png" alt="3101"><span><b>3101</b><small>存钱罐</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 40<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 30<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2404.png" alt="2404"><span><b>2404</b><small>一叠金币</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 5,
  &quot;Spread_StorageMaxNumber&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;2401-40&quot;,
    &quot;2402-30&quot;,
    &quot;2403-20&quot;,
    &quot;2404-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;3101&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/3501.png" alt="3501"><span><b>3501</b><small>欢迎礼物箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>120</td><td>2</td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_OpenDuration&quot;: 120,
  &quot;Spread_OpenSpeedUpCost&quot;: 2,
  &quot;Spread_StorageMaxNumber&quot;: 6,
  &quot;Spread_Weight&quot;: [
    &quot;2401-2&quot;,
    &quot;2402-1&quot;,
    &quot;2501-2&quot;,
    &quot;2502-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;3501&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/3601.png" alt="3601"><span><b>3601</b><small>入门礼物箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 30<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 30</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;203-10&quot;,
    &quot;204-10&quot;,
    &quot;205-30&quot;,
    &quot;503-10&quot;,
    &quot;504-10&quot;,
    &quot;505-30&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;3601&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/3701.png" alt="3701"><span><b>3701</b><small>野餐礼物箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/902.png" alt="902"><span><b>902</b><small>蜂蜜釉面鲑鱼</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 7</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;202-6&quot;,
    &quot;203-10&quot;,
    &quot;204-10&quot;,
    &quot;205-7&quot;,
    &quot;502-6&quot;,
    &quot;503-10&quot;,
    &quot;504-10&quot;,
    &quot;505-7&quot;,
    &quot;902-6&quot;,
    &quot;903-10&quot;,
    &quot;904-10&quot;,
    &quot;905-7&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;3701&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/3801.png" alt="3801"><span><b>3801</b><small>泳池礼品箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1104.png" alt="1104"><span><b>1104</b><small>橙色纸杯蛋糕</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1105.png" alt="1105"><span><b>1105</b><small>令人惬意的橘子蛋糕</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 7</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;1102-6&quot;,
    &quot;1103-10&quot;,
    &quot;1104-10&quot;,
    &quot;1105-7&quot;,
    &quot;1302-6&quot;,
    &quot;1303-10&quot;,
    &quot;1304-10&quot;,
    &quot;1305-7&quot;,
    &quot;1802-6&quot;,
    &quot;1803-10&quot;,
    &quot;1804-10&quot;,
    &quot;1805-7&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;3801&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/3901.png" alt="3901"><span><b>3901</b><small>海洋礼物箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/902.png" alt="902"><span><b>902</b><small>蜂蜜釉面鲑鱼</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1402.png" alt="1402"><span><b>1402</b><small>潜水护目镜</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 7</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;902-6&quot;,
    &quot;903-10&quot;,
    &quot;904-10&quot;,
    &quot;905-7&quot;,
    &quot;1302-6&quot;,
    &quot;1303-10&quot;,
    &quot;1304-10&quot;,
    &quot;1305-7&quot;,
    &quot;1402-6&quot;,
    &quot;1403-10&quot;,
    &quot;1404-10&quot;,
    &quot;1405-7&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;3901&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>sp3_1_1</b><small>陶艺机</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td>7200</td><td>97</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td>14400</td><td>180</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><span><b>sp3_2_1</b><small>陶杯</small></span></span> × 12<br><span class="config-piece"><span><b>sp3_3_1</b><small>易碎小鸟</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_ItemRecoveryDuration&quot;: 7200,
  &quot;Spread_ItemSpeedUpCost&quot;: 97,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_StorageRecoveryDuration&quot;: 14400,
  &quot;Spread_StorageSpeedUpCost&quot;: 180,
  &quot;Spread_Weight&quot;: [
    &quot;sp3_2_1-12&quot;,
    &quot;sp3_3_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;sp3_1_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>BPsp_gift_1</b><small>通行证礼包</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;BPsp_gift_2&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;203-1&quot;,
    &quot;204-1&quot;,
    &quot;205-1&quot;,
    &quot;603-1&quot;,
    &quot;2503-1&quot;,
    &quot;1102-1&quot;,
    &quot;503-1&quot;,
    &quot;504-1&quot;,
    &quot;1803-1&quot;,
    &quot;304-1&quot;,
    &quot;903-1&quot;,
    &quot;904-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;BPsp_gift_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>BPsp_gift_2</b><small>通行证礼包</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1201.png" alt="1201"><span><b>1201</b><small>泳池垃圾桶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;BPsp_gift_3&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 15,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 15,
  &quot;Spread_Weight&quot;: [
    &quot;203-1&quot;,
    &quot;204-1&quot;,
    &quot;205-2&quot;,
    &quot;206-1&quot;,
    &quot;603-1&quot;,
    &quot;604-1&quot;,
    &quot;2503-1&quot;,
    &quot;1102-1&quot;,
    &quot;1103-1&quot;,
    &quot;1201-1&quot;,
    &quot;503-1&quot;,
    &quot;504-1&quot;,
    &quot;505-1&quot;,
    &quot;1803-1&quot;,
    &quot;903-1&quot;,
    &quot;904-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;BPsp_gift_2&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>BPsp_gift_3</b><small>通行证礼包</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>22</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>22</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2504.png" alt="2504"><span><b>2504</b><small>宝石堆</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1201.png" alt="1201"><span><b>1201</b><small>泳池垃圾桶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 22,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 22,
  &quot;Spread_Weight&quot;: [
    &quot;203-1&quot;,
    &quot;204-1&quot;,
    &quot;205-3&quot;,
    &quot;206-1&quot;,
    &quot;207-1&quot;,
    &quot;603-1&quot;,
    &quot;604-1&quot;,
    &quot;2504-1&quot;,
    &quot;2503-1&quot;,
    &quot;1102-1&quot;,
    &quot;1103-1&quot;,
    &quot;1201-1&quot;,
    &quot;503-1&quot;,
    &quot;504-1&quot;,
    &quot;505-1&quot;,
    &quot;506-1&quot;,
    &quot;1803-1&quot;,
    &quot;304-1&quot;,
    &quot;903-1&quot;,
    &quot;904-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;BPsp_gift_3&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/BPob_gift_1.png" alt="BPob_gift_1"><span><b>BPob_gift_1</b><small>BPsp_gift_1</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;BPob_gift_2&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;203-1&quot;,
    &quot;204-1&quot;,
    &quot;205-1&quot;,
    &quot;603-1&quot;,
    &quot;2503-1&quot;,
    &quot;1102-1&quot;,
    &quot;503-1&quot;,
    &quot;504-1&quot;,
    &quot;1803-1&quot;,
    &quot;304-1&quot;,
    &quot;903-1&quot;,
    &quot;904-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;BPob_gift_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/BPob_gift_2.png" alt="BPob_gift_2"><span><b>BPob_gift_2</b><small>BPsp_gift_2</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1201.png" alt="1201"><span><b>1201</b><small>泳池垃圾桶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;BPob_gift_3&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 15,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 15,
  &quot;Spread_Weight&quot;: [
    &quot;203-1&quot;,
    &quot;204-1&quot;,
    &quot;205-2&quot;,
    &quot;206-1&quot;,
    &quot;603-1&quot;,
    &quot;604-1&quot;,
    &quot;2503-1&quot;,
    &quot;1102-1&quot;,
    &quot;1103-1&quot;,
    &quot;1201-1&quot;,
    &quot;503-1&quot;,
    &quot;504-1&quot;,
    &quot;505-1&quot;,
    &quot;1803-1&quot;,
    &quot;903-1&quot;,
    &quot;904-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;BPob_gift_2&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/BPob_gift_3.png" alt="BPob_gift_3"><span><b>BPob_gift_3</b><small>BPsp_gift_3</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>22</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>22</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2504.png" alt="2504"><span><b>2504</b><small>宝石堆</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1201.png" alt="1201"><span><b>1201</b><small>泳池垃圾桶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 22,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 22,
  &quot;Spread_Weight&quot;: [
    &quot;203-1&quot;,
    &quot;204-1&quot;,
    &quot;205-3&quot;,
    &quot;206-1&quot;,
    &quot;207-1&quot;,
    &quot;603-1&quot;,
    &quot;604-1&quot;,
    &quot;2504-1&quot;,
    &quot;2503-1&quot;,
    &quot;1102-1&quot;,
    &quot;1103-1&quot;,
    &quot;1201-1&quot;,
    &quot;503-1&quot;,
    &quot;504-1&quot;,
    &quot;505-1&quot;,
    &quot;506-1&quot;,
    &quot;1803-1&quot;,
    &quot;304-1&quot;,
    &quot;903-1&quot;,
    &quot;904-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;BPob_gift_3&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/BP_gift_1.png" alt="BP_gift_1"><span><b>BP_gift_1</b><small>BPsp_gift_1</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;BP_gift_2&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;203-1&quot;,
    &quot;204-1&quot;,
    &quot;205-1&quot;,
    &quot;603-1&quot;,
    &quot;2503-1&quot;,
    &quot;1102-1&quot;,
    &quot;503-1&quot;,
    &quot;504-1&quot;,
    &quot;1803-1&quot;,
    &quot;304-1&quot;,
    &quot;903-1&quot;,
    &quot;904-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;BP_gift_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/BP_gift_2.png" alt="BP_gift_2"><span><b>BP_gift_2</b><small>BPsp_gift_2</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1201.png" alt="1201"><span><b>1201</b><small>泳池垃圾桶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;BP_gift_3&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 15,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 15,
  &quot;Spread_Weight&quot;: [
    &quot;203-1&quot;,
    &quot;204-1&quot;,
    &quot;205-2&quot;,
    &quot;206-1&quot;,
    &quot;603-1&quot;,
    &quot;604-1&quot;,
    &quot;2503-1&quot;,
    &quot;1102-1&quot;,
    &quot;1103-1&quot;,
    &quot;1201-1&quot;,
    &quot;503-1&quot;,
    &quot;504-1&quot;,
    &quot;505-1&quot;,
    &quot;1803-1&quot;,
    &quot;903-1&quot;,
    &quot;904-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;BP_gift_2&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/BP_gift_3.png" alt="BP_gift_3"><span><b>BP_gift_3</b><small>BPsp_gift_3</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>22</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>22</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2504.png" alt="2504"><span><b>2504</b><small>宝石堆</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1201.png" alt="1201"><span><b>1201</b><small>泳池垃圾桶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 22,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 22,
  &quot;Spread_Weight&quot;: [
    &quot;203-1&quot;,
    &quot;204-1&quot;,
    &quot;205-3&quot;,
    &quot;206-1&quot;,
    &quot;207-1&quot;,
    &quot;603-1&quot;,
    &quot;604-1&quot;,
    &quot;2504-1&quot;,
    &quot;2503-1&quot;,
    &quot;1102-1&quot;,
    &quot;1103-1&quot;,
    &quot;1201-1&quot;,
    &quot;503-1&quot;,
    &quot;504-1&quot;,
    &quot;505-1&quot;,
    &quot;506-1&quot;,
    &quot;1803-1&quot;,
    &quot;304-1&quot;,
    &quot;903-1&quot;,
    &quot;904-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;BP_gift_3&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>md_hw_gift_1</b><small>惊喜礼盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_StorageMaxNumber&quot;: 6,
  &quot;Spread_Weight&quot;: [
    &quot;2602-5&quot;,
    &quot;2603-5&quot;,
    &quot;2604-5&quot;,
    &quot;2401-5&quot;,
    &quot;2402-5&quot;,
    &quot;2501-5&quot;,
    &quot;2502-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;md_hw_gift_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>md_hw_gift_2</b><small>惊喜礼盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2404.png" alt="2404"><span><b>2404</b><small>一叠金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 7,
  &quot;Spread_StorageMaxNumber&quot;: 7,
  &quot;Spread_Weight&quot;: [
    &quot;2603-5&quot;,
    &quot;2604-5&quot;,
    &quot;2402-5&quot;,
    &quot;2403-5&quot;,
    &quot;2404-1&quot;,
    &quot;2502-5&quot;,
    &quot;2503-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;md_hw_gift_2&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>sp4_1_1</b><small>梳妆台</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>4</td><td>9000</td><td>117</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td>18000</td><td>220</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><span><b>sp4_2_1</b><small>戒指盒</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 4,
  &quot;Spread_ItemRecoveryDuration&quot;: 9000,
  &quot;Spread_ItemSpeedUpCost&quot;: 117,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_StorageRecoveryDuration&quot;: 18000,
  &quot;Spread_StorageSpeedUpCost&quot;: 220,
  &quot;Spread_Weight&quot;: [
    &quot;sp4_2_1-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;sp4_1_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>sp4_2_4</b><small>精致首饰盒</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><span><b>sp4_3_1</b><small>珍珠</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 25,
  &quot;SellingPrice&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_StorageMaxNumber&quot;: 6,
  &quot;Spread_Weight&quot;: [
    &quot;sp4_3_1-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;sp4_2_4&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>ShopNewChest_1</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;ShopNewChest_2&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 5,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;2401-4&quot;,
    &quot;2601-6&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;ShopNewChest_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>ShopNewChest_2</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>11</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>11</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 8<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 2</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;ShopNewChest_3&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 11,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 11,
  &quot;Spread_Weight&quot;: [
    &quot;2401-8&quot;,
    &quot;2402-2&quot;,
    &quot;2601-10&quot;,
    &quot;2602-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;ShopNewChest_2&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>ShopNewChest_3</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>23</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>23</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 16<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 16<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 2</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 23,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 23,
  &quot;Spread_Weight&quot;: [
    &quot;2401-16&quot;,
    &quot;2402-6&quot;,
    &quot;2403-2&quot;,
    &quot;2601-16&quot;,
    &quot;2602-4&quot;,
    &quot;2603-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;ShopNewChest_3&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>sp5_1_1</b><small>飞溅鱼缸</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>4</td><td>10800</td><td>137</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td>21600</td><td>266</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><span><b>sp5_2_1</b><small>霓虹灯鱼</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 4,
  &quot;Spread_ItemRecoveryDuration&quot;: 10800,
  &quot;Spread_ItemSpeedUpCost&quot;: 137,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_StorageRecoveryDuration&quot;: 21600,
  &quot;Spread_StorageSpeedUpCost&quot;: 266,
  &quot;Spread_Weight&quot;: [
    &quot;sp5_2_1-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;sp5_1_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>sp6_1_1</b><small>玩具箱</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>4</td><td>10800</td><td>137</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td>21600</td><td>266</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><span><b>sp6_2_1</b><small>猫玩具球</small></span></span> × 10</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemMaxNumber&quot;: 4,
  &quot;Spread_ItemRecoveryDuration&quot;: 10800,
  &quot;Spread_ItemSpeedUpCost&quot;: 137,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_StorageRecoveryDuration&quot;: 21600,
  &quot;Spread_StorageSpeedUpCost&quot;: 266,
  &quot;Spread_Weight&quot;: [
    &quot;sp6_2_1-10&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;sp6_1_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/daily_task_chestA_1.png" alt="daily_task_chestA_1"><span><b>daily_task_chestA_1</b><small>豪华宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_Weight&quot;: [
    &quot;2502-4&quot;,
    &quot;2403-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;daily_task_chestA_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/daily_task_chestB_1.png" alt="daily_task_chestB_1"><span><b>daily_task_chestB_1</b><small>豪华宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>4</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>4</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/4101.png" alt="4101"><span><b>4101</b><small>红色挑选箱</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 4,
  &quot;Spread_StorageMaxNumber&quot;: 4,
  &quot;Spread_Weight&quot;: [
    &quot;4101-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;daily_task_chestB_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/daily_task_chestC_1.png" alt="daily_task_chestC_1"><span><b>daily_task_chestC_1</b><small>豪华宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>4</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>4</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/4101.png" alt="4101"><span><b>4101</b><small>红色挑选箱</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 4,
  &quot;Spread_StorageMaxNumber&quot;: 4,
  &quot;Spread_Weight&quot;: [
    &quot;4101-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;daily_task_chestC_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>truckbox_1</b><small>惊喜礼盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 3</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;truckbox_2&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 6,
  &quot;Spread_Weight&quot;: [
    &quot;2601-3&quot;,
    &quot;2401-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;truckbox_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>truckbox_2</b><small>惊喜礼盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;truckbox_3&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;2601-2&quot;,
    &quot;2602-2&quot;,
    &quot;2401-3&quot;,
    &quot;2402-1&quot;,
    &quot;2501-1&quot;,
    &quot;2502-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;truckbox_2&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>truckbox_3</b><small>惊喜礼盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 15,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 15,
  &quot;Spread_Weight&quot;: [
    &quot;2601-3&quot;,
    &quot;2602-3&quot;,
    &quot;2603-1&quot;,
    &quot;2401-3&quot;,
    &quot;2402-2&quot;,
    &quot;2403-1&quot;,
    &quot;2502-1&quot;,
    &quot;2503-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;truckbox_3&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>deco_event_gift_s_1</b><small>惊喜礼盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_StorageMaxNumber&quot;: 6,
  &quot;Spread_Weight&quot;: [
    &quot;2602-5&quot;,
    &quot;2603-5&quot;,
    &quot;2604-5&quot;,
    &quot;2401-5&quot;,
    &quot;2402-5&quot;,
    &quot;2501-5&quot;,
    &quot;2502-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;deco_event_gift_s_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>deco_event_gift_b_1</b><small>惊喜礼盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2404.png" alt="2404"><span><b>2404</b><small>一叠金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 7,
  &quot;Spread_StorageMaxNumber&quot;: 7,
  &quot;Spread_Weight&quot;: [
    &quot;2603-5&quot;,
    &quot;2604-5&quot;,
    &quot;2402-5&quot;,
    &quot;2403-5&quot;,
    &quot;2404-1&quot;,
    &quot;2502-5&quot;,
    &quot;2503-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;deco_event_gift_b_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>re_ch_1_1_1</b><small>海洋礼物箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;IsTemplate&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_Weight&quot;: [
    &quot;2501-2&quot;,
    &quot;2502-2&quot;,
    &quot;2601-2&quot;,
    &quot;2602-1&quot;,
    &quot;2603-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;re_ch_1_1_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>re_ch_1_2_1</b><small>神秘的宝藏</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;IsTemplate&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_Weight&quot;: [
    &quot;2501-4&quot;,
    &quot;2502-5&quot;,
    &quot;2503-1&quot;,
    &quot;2601-5&quot;,
    &quot;2602-5&quot;,
    &quot;2603-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;re_ch_1_2_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>re_ch_1_3_1</b><small>豪华宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>16</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>16</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;IsTemplate&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 16,
  &quot;Spread_StorageMaxNumber&quot;: 16,
  &quot;Spread_Weight&quot;: [
    &quot;2502-5&quot;,
    &quot;2503-3&quot;,
    &quot;2602-4&quot;,
    &quot;2603-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;re_ch_1_3_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>re_ch_2_1_1</b><small>普通宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_Weight&quot;: [
    &quot;2501-2&quot;,
    &quot;2502-2&quot;,
    &quot;2601-2&quot;,
    &quot;2602-1&quot;,
    &quot;2603-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;re_ch_2_1_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>re_ch_2_2_1</b><small>时尚宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_Weight&quot;: [
    &quot;2501-4&quot;,
    &quot;2502-5&quot;,
    &quot;2503-1&quot;,
    &quot;2601-5&quot;,
    &quot;2602-5&quot;,
    &quot;2603-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;re_ch_2_2_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>re_ch_2_3_1</b><small>豪华宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>16</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>16</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 16,
  &quot;Spread_StorageMaxNumber&quot;: 16,
  &quot;Spread_Weight&quot;: [
    &quot;2502-5&quot;,
    &quot;2503-3&quot;,
    &quot;2602-4&quot;,
    &quot;2603-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;re_ch_2_3_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>rc_a_1</b><small>简易宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_Weight&quot;: [
    &quot;2401-3&quot;,
    &quot;2402-1&quot;,
    &quot;2601-3&quot;,
    &quot;2602-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;rc_a_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>rc_b_1</b><small>金色宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;2401-2&quot;,
    &quot;2402-2&quot;,
    &quot;2501-2&quot;,
    &quot;2601-2&quot;,
    &quot;2602-1&quot;,
    &quot;2603-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;rc_b_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>rc_c_1</b><small>红宝石宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 2</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 13,
  &quot;Spread_StorageMaxNumber&quot;: 13,
  &quot;Spread_Weight&quot;: [
    &quot;2401-2&quot;,
    &quot;2402-2&quot;,
    &quot;2403-1&quot;,
    &quot;2501-2&quot;,
    &quot;2502-1&quot;,
    &quot;2601-2&quot;,
    &quot;2602-1&quot;,
    &quot;2603-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;rc_c_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>rc_d_1</b><small>华丽宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 15,
  &quot;Spread_StorageMaxNumber&quot;: 15,
  &quot;Spread_Weight&quot;: [
    &quot;2401-2&quot;,
    &quot;2402-2&quot;,
    &quot;2403-2&quot;,
    &quot;2501-2&quot;,
    &quot;2502-1&quot;,
    &quot;2503-1&quot;,
    &quot;2602-2&quot;,
    &quot;2603-2&quot;,
    &quot;2604-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;rc_d_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>rc_e_1</b><small>皇室宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>17</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>17</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2404.png" alt="2404"><span><b>2404</b><small>一叠金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 2</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 17,
  &quot;Spread_StorageMaxNumber&quot;: 17,
  &quot;Spread_Weight&quot;: [
    &quot;2402-2&quot;,
    &quot;2403-2&quot;,
    &quot;2404-1&quot;,
    &quot;2501-2&quot;,
    &quot;2502-2&quot;,
    &quot;2503-2&quot;,
    &quot;2602-2&quot;,
    &quot;2603-2&quot;,
    &quot;2604-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;rc_e_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>rc_f_1</b><small>大师宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>20</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>20</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2404.png" alt="2404"><span><b>2404</b><small>一叠金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2405.png" alt="2405"><span><b>2405</b><small>金币堆</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2504.png" alt="2504"><span><b>2504</b><small>宝石堆</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2605.png" alt="2605"><span><b>2605</b><small>终极体力瓶</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 20,
  &quot;Spread_StorageMaxNumber&quot;: 20,
  &quot;Spread_Weight&quot;: [
    &quot;2402-2&quot;,
    &quot;2403-1&quot;,
    &quot;2404-1&quot;,
    &quot;2405-1&quot;,
    &quot;2502-4&quot;,
    &quot;2503-2&quot;,
    &quot;2504-2&quot;,
    &quot;2603-4&quot;,
    &quot;2604-2&quot;,
    &quot;2605-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;rc_f_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>scratch_a_1</b><small>刮刮卡</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2404.png" alt="2404"><span><b>2404</b><small>一叠金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2405.png" alt="2405"><span><b>2405</b><small>金币堆</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2504.png" alt="2504"><span><b>2504</b><small>宝石堆</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 1,
  &quot;Spread_Weight&quot;: [
    &quot;2403-3&quot;,
    &quot;2404-2&quot;,
    &quot;2405-1&quot;,
    &quot;2502-3&quot;,
    &quot;2503-2&quot;,
    &quot;2504-1&quot;,
    &quot;2602-3&quot;,
    &quot;2603-2&quot;,
    &quot;2604-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;scratch_a_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>scratch_b_1</b><small>一叠刮刮卡</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><span><b>scratch_a_1</b><small>刮刮卡</small></span></span> × 5</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 5,
  &quot;Spread_StorageMaxNumber&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;scratch_a_1-5&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;scratch_b_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>gift_olivia_1</b><small>奥利维亚的太空礼盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_down_piece_1.png" alt="level_down_piece_1"><span><b>level_down_piece_1</b><small>剪刀</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_up_piece_1.png" alt="level_up_piece_1"><span><b>level_up_piece_1</b><small>万能宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 13,
  &quot;Spread_StorageMaxNumber&quot;: 13,
  &quot;Spread_Weight&quot;: [
    &quot;2402-1&quot;,
    &quot;2403-3&quot;,
    &quot;2502-2&quot;,
    &quot;2503-1&quot;,
    &quot;2603-3&quot;,
    &quot;2604-1&quot;,
    &quot;level_down_piece_1-1&quot;,
    &quot;level_up_piece_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;gift_olivia_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>gift_quinn_1</b><small>奎因的礼物</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_down_piece_1.png" alt="level_down_piece_1"><span><b>level_down_piece_1</b><small>剪刀</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_up_piece_1.png" alt="level_up_piece_1"><span><b>level_up_piece_1</b><small>万能宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 13,
  &quot;Spread_StorageMaxNumber&quot;: 13,
  &quot;Spread_Weight&quot;: [
    &quot;206-2&quot;,
    &quot;304-2&quot;,
    &quot;506-2&quot;,
    &quot;604-2&quot;,
    &quot;2502-2&quot;,
    &quot;2503-1&quot;,
    &quot;level_down_piece_1-1&quot;,
    &quot;level_up_piece_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;gift_quinn_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>gift_harrison_1</b><small>哈里森的礼物</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/906.png" alt="906"><span><b>906</b><small>海鲜意面</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_down_piece_1.png" alt="level_down_piece_1"><span><b>level_down_piece_1</b><small>剪刀</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_up_piece_1.png" alt="level_up_piece_1"><span><b>level_up_piece_1</b><small>万能宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 13,
  &quot;Spread_StorageMaxNumber&quot;: 13,
  &quot;Spread_Weight&quot;: [
    &quot;805-2&quot;,
    &quot;904-2&quot;,
    &quot;905-2&quot;,
    &quot;906-2&quot;,
    &quot;2502-2&quot;,
    &quot;2503-1&quot;,
    &quot;level_down_piece_1-1&quot;,
    &quot;level_up_piece_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;gift_harrison_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>Bp_chest_a_1</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;Bp_chest_a_2&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 6,
  &quot;Spread_Weight&quot;: [
    &quot;205-4&quot;,
    &quot;206-1&quot;,
    &quot;303-2&quot;,
    &quot;2503-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;Bp_chest_a_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>Bp_chest_a_2</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2504.png" alt="2504"><span><b>2504</b><small>宝石堆</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;Bp_chest_a_3&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_Weight&quot;: [
    &quot;206-3&quot;,
    &quot;207-2&quot;,
    &quot;303-1&quot;,
    &quot;304-2&quot;,
    &quot;2503-1&quot;,
    &quot;2504-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;Bp_chest_a_2&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>Bp_chest_a_3</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2504.png" alt="2504"><span><b>2504</b><small>宝石堆</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;206-2&quot;,
    &quot;207-2&quot;,
    &quot;304-4&quot;,
    &quot;2504-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;Bp_chest_a_3&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>Bp_chest_b_1</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;Bp_chest_b_2&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 6,
  &quot;Spread_Weight&quot;: [
    &quot;504-5&quot;,
    &quot;505-1&quot;,
    &quot;603-2&quot;,
    &quot;604-1&quot;,
    &quot;1103-2&quot;,
    &quot;2503-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;Bp_chest_b_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>Bp_chest_b_2</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1104.png" alt="1104"><span><b>1104</b><small>橙色纸杯蛋糕</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2504.png" alt="2504"><span><b>2504</b><small>宝石堆</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;Bp_chest_b_3&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_Weight&quot;: [
    &quot;505-1&quot;,
    &quot;506-3&quot;,
    &quot;603-5&quot;,
    &quot;604-1&quot;,
    &quot;1103-2&quot;,
    &quot;1104-1&quot;,
    &quot;2504-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;Bp_chest_b_2&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>Bp_chest_b_3</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/507.png" alt="507"><span><b>507</b><small>加糖咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1104.png" alt="1104"><span><b>1104</b><small>橙色纸杯蛋糕</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2504.png" alt="2504"><span><b>2504</b><small>宝石堆</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;506-7&quot;,
    &quot;507-1&quot;,
    &quot;604-6&quot;,
    &quot;605-3&quot;,
    &quot;1103-1&quot;,
    &quot;1104-5&quot;,
    &quot;2504-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;Bp_chest_b_3&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>Bp_chest_c_1</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1201.png" alt="1201"><span><b>1201</b><small>泳池垃圾桶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;Bp_chest_c_2&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 6,
  &quot;Spread_Weight&quot;: [
    &quot;903-6&quot;,
    &quot;1201-1&quot;,
    &quot;1803-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;Bp_chest_c_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>Bp_chest_c_2</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1201.png" alt="1201"><span><b>1201</b><small>泳池垃圾桶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;MergedType&quot;: &quot;Bp_chest_c_3&quot;,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_Weight&quot;: [
    &quot;903-2&quot;,
    &quot;904-5&quot;,
    &quot;1201-2&quot;,
    &quot;1803-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;Bp_chest_c_2&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>Bp_chest_c_3</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td>1</td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1201.png" alt="1201"><span><b>1201</b><small>泳池垃圾桶</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_OpenDuration&quot;: 5,
  &quot;Spread_OpenSpeedUpCost&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;904-5&quot;,
    &quot;905-2&quot;,
    &quot;1201-3&quot;,
    &quot;1803-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;Bp_chest_c_3&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>re_ch_1_4_1</b><small>闹鬼宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>18</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>18</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2504.png" alt="2504"><span><b>2504</b><small>宝石堆</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;IsTemplate&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 18,
  &quot;Spread_StorageMaxNumber&quot;: 18,
  &quot;Spread_Weight&quot;: [
    &quot;2502-7&quot;,
    &quot;2503-10&quot;,
    &quot;2504-1&quot;,
    &quot;2602-7&quot;,
    &quot;2603-10&quot;,
    &quot;2604-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;re_ch_1_4_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>re_ch_spe_1</b><small>弗兰肯箱子</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>15</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2504.png" alt="2504"><span><b>2504</b><small>宝石堆</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_up_piece_1.png" alt="level_up_piece_1"><span><b>level_up_piece_1</b><small>万能宝石</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;IsTemplate&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 15,
  &quot;Spread_StorageMaxNumber&quot;: 15,
  &quot;Spread_Weight&quot;: [
    &quot;2502-12&quot;,
    &quot;2503-7&quot;,
    &quot;2504-3&quot;,
    &quot;2602-12&quot;,
    &quot;2603-7&quot;,
    &quot;2604-3&quot;,
    &quot;level_up_piece_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 1,
  &quot;Type&quot;: &quot;re_ch_spe_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>gift_sam_1</b><small>山姆的工具箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1307.png" alt="1307"><span><b>1307</b><small>鸭子漂浮圈</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_down_piece_1.png" alt="level_down_piece_1"><span><b>level_down_piece_1</b><small>剪刀</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_up_piece_1.png" alt="level_up_piece_1"><span><b>level_up_piece_1</b><small>万能宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 13,
  &quot;Spread_StorageMaxNumber&quot;: 13,
  &quot;Spread_Weight&quot;: [
    &quot;1405-2&quot;,
    &quot;1305-2&quot;,
    &quot;1306-2&quot;,
    &quot;1307-2&quot;,
    &quot;2502-2&quot;,
    &quot;2503-1&quot;,
    &quot;level_down_piece_1-1&quot;,
    &quot;level_up_piece_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;gift_sam_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>fish_trophy_a_1</b><small>钓鱼大师奖杯</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_TransformNumber&quot;: 12,
  &quot;Spread_Weight&quot;: [
    &quot;2403-4&quot;,
    &quot;2502-4&quot;,
    &quot;2603-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;fish_trophy_b_1-10&quot;
  ],
  &quot;Type&quot;: &quot;fish_trophy_a_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/fish_trophy_b_1.png" alt="fish_trophy_b_1"><span><b>fish_trophy_b_1</b><small>钓鱼大师奖杯</small></span></span></td><td>0</td><td>0</td><td>86400</td><td>98</td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 86400,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_TransformNumber&quot;: 12,
  &quot;Spread_Weight&quot;: [
    &quot;2403-4&quot;,
    &quot;2502-4&quot;,
    &quot;2603-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;fish_trophy_c_1-10&quot;
  ],
  &quot;Type&quot;: &quot;fish_trophy_b_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/fish_trophy_c_1.png" alt="fish_trophy_c_1"><span><b>fish_trophy_c_1</b><small>钓鱼大师奖杯</small></span></span></td><td>0</td><td>0</td><td>86400</td><td>98</td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 86400,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_Weight&quot;: [
    &quot;2403-4&quot;,
    &quot;2502-4&quot;,
    &quot;2603-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;fish_trophy_c_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>gift_mark_1</b><small>马克的园艺盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_down_piece_1.png" alt="level_down_piece_1"><span><b>level_down_piece_1</b><small>剪刀</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_up_piece_1.png" alt="level_up_piece_1"><span><b>level_up_piece_1</b><small>万能宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 13,
  &quot;Spread_StorageMaxNumber&quot;: 13,
  &quot;Spread_Weight&quot;: [
    &quot;2602-2&quot;,
    &quot;2603-2&quot;,
    &quot;506-2&quot;,
    &quot;604-2&quot;,
    &quot;2502-2&quot;,
    &quot;2503-1&quot;,
    &quot;level_down_piece_1-1&quot;,
    &quot;level_up_piece_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;gift_mark_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>gift_amala_1</b><small>阿玛拉的读书奖励盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_down_piece_1.png" alt="level_down_piece_1"><span><b>level_down_piece_1</b><small>剪刀</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_up_piece_1.png" alt="level_up_piece_1"><span><b>level_up_piece_1</b><small>万能宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 13,
  &quot;Spread_StorageMaxNumber&quot;: 13,
  &quot;Spread_Weight&quot;: [
    &quot;2602-2&quot;,
    &quot;2603-2&quot;,
    &quot;506-2&quot;,
    &quot;604-2&quot;,
    &quot;2502-2&quot;,
    &quot;2503-1&quot;,
    &quot;level_down_piece_1-1&quot;,
    &quot;level_up_piece_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;gift_amala_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>gift_colton_1</b><small>科尔顿鼓囊囊的公文包</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_down_piece_1.png" alt="level_down_piece_1"><span><b>level_down_piece_1</b><small>剪刀</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_up_piece_1.png" alt="level_up_piece_1"><span><b>level_up_piece_1</b><small>万能宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 13,
  &quot;Spread_StorageMaxNumber&quot;: 13,
  &quot;Spread_Weight&quot;: [
    &quot;2602-2&quot;,
    &quot;2603-2&quot;,
    &quot;303-2&quot;,
    &quot;603-2&quot;,
    &quot;2502-2&quot;,
    &quot;2503-1&quot;,
    &quot;level_down_piece_1-1&quot;,
    &quot;level_up_piece_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;gift_colton_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>s5_fly_a_1</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_TransformNumber&quot;: 12,
  &quot;Spread_Weight&quot;: [
    &quot;205-4&quot;,
    &quot;204-4&quot;,
    &quot;303-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;s5_fly_b_1-10&quot;
  ],
  &quot;Type&quot;: &quot;s5_fly_a_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>s5_fly_b_1</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td>86400</td><td>98</td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 86400,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_TransformNumber&quot;: 12,
  &quot;Spread_Weight&quot;: [
    &quot;505-4&quot;,
    &quot;504-4&quot;,
    &quot;603-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;s5_fly_c_1-10&quot;
  ],
  &quot;Type&quot;: &quot;s5_fly_b_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>s5_fly_c_1</b><small>无本地视图映射</small></span></span></td><td>0</td><td>0</td><td>86400</td><td>98</td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 86400,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_StorageMaxNumber&quot;: 12,
  &quot;Spread_Weight&quot;: [
    &quot;2403-4&quot;,
    &quot;2502-4&quot;,
    &quot;2603-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;s5_fly_c_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_order_chest_s_1.png" alt="main_order_chest_s_1"><span><b>main_order_chest_s_1</b><small>聪明宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>75</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>75</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13</div></td><td>3</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 75,
  &quot;Spread_StorageMaxNumber&quot;: 75,
  &quot;Spread_Weight&quot;: [
    &quot;204-5&quot;,
    &quot;205-10&quot;,
    &quot;303-10&quot;,
    &quot;304-20&quot;,
    &quot;504-5&quot;,
    &quot;505-10&quot;,
    &quot;603-10&quot;,
    &quot;604-20&quot;,
    &quot;903-7&quot;,
    &quot;904-13&quot;,
    &quot;1103-9&quot;,
    &quot;1304-6&quot;,
    &quot;1305-13&quot;,
    &quot;1403-9&quot;,
    &quot;1804-7&quot;,
    &quot;1805-13&quot;
  ],
  &quot;Spread_WeightType&quot;: 3,
  &quot;Type&quot;: &quot;main_order_chest_s_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_order_chest_m_1.png" alt="main_order_chest_m_1"><span><b>main_order_chest_m_1</b><small>睿智宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>150</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>150</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 27<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 26<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 27</div></td><td>3</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 150,
  &quot;Spread_StorageMaxNumber&quot;: 150,
  &quot;Spread_Weight&quot;: [
    &quot;205-10&quot;,
    &quot;206-20&quot;,
    &quot;303-10&quot;,
    &quot;304-20&quot;,
    &quot;505-10&quot;,
    &quot;506-20&quot;,
    &quot;603-10&quot;,
    &quot;604-20&quot;,
    &quot;904-13&quot;,
    &quot;905-27&quot;,
    &quot;1103-9&quot;,
    &quot;1305-13&quot;,
    &quot;1306-26&quot;,
    &quot;1403-9&quot;,
    &quot;1805-13&quot;,
    &quot;1806-27&quot;
  ],
  &quot;Spread_WeightType&quot;: 3,
  &quot;Type&quot;: &quot;main_order_chest_m_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_order_chest_b_1.png" alt="main_order_chest_b_1"><span><b>main_order_chest_b_1</b><small>天才宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>225</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>225</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 27<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 26<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 27</div></td><td>3</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 225,
  &quot;Spread_StorageMaxNumber&quot;: 225,
  &quot;Spread_Weight&quot;: [
    &quot;205-10&quot;,
    &quot;206-20&quot;,
    &quot;303-10&quot;,
    &quot;304-20&quot;,
    &quot;505-10&quot;,
    &quot;506-20&quot;,
    &quot;603-10&quot;,
    &quot;604-20&quot;,
    &quot;904-13&quot;,
    &quot;905-27&quot;,
    &quot;1103-9&quot;,
    &quot;1305-13&quot;,
    &quot;1306-26&quot;,
    &quot;1403-9&quot;,
    &quot;1805-13&quot;,
    &quot;1806-27&quot;
  ],
  &quot;Spread_WeightType&quot;: 3,
  &quot;Type&quot;: &quot;main_order_chest_b_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_fry_chest_1</b><small>薯条补给箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/302.png" alt="302"><span><b>302</b><small>切片土豆</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 9,
  &quot;Spread_StorageMaxNumber&quot;: 9,
  &quot;Spread_Weight&quot;: [
    &quot;303-5&quot;,
    &quot;302-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;main_fry_chest_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_tea_chest_1</b><small>红茶补给箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/602.png" alt="602"><span><b>602</b><small>热茶</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 9,
  &quot;Spread_StorageMaxNumber&quot;: 9,
  &quot;Spread_Weight&quot;: [
    &quot;603-5&quot;,
    &quot;602-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;main_tea_chest_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_seafood_chest_1</b><small>海鲜补给箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>8</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 8,
  &quot;Spread_StorageMaxNumber&quot;: 8,
  &quot;Spread_Weight&quot;: [
    &quot;904-4&quot;,
    &quot;903-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;main_seafood_chest_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_orange_chest_1</b><small>橘子补给箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>14</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>14</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1101.png" alt="1101"><span><b>1101</b><small>橙子</small></span></span> × 6</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 14,
  &quot;Spread_StorageMaxNumber&quot;: 14,
  &quot;Spread_Weight&quot;: [
    &quot;1103-3&quot;,
    &quot;1102-5&quot;,
    &quot;1101-6&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;main_orange_chest_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_dive_chest_1</b><small>潜水道具补给箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1402.png" alt="1402"><span><b>1402</b><small>潜水护目镜</small></span></span> × 4</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 9,
  &quot;Spread_StorageMaxNumber&quot;: 9,
  &quot;Spread_Weight&quot;: [
    &quot;1403-5&quot;,
    &quot;1402-4&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;main_dive_chest_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>gift_lori_1</b><small>罗莉的珠宝盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/906.png" alt="906"><span><b>906</b><small>海鲜意面</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_down_piece_1.png" alt="level_down_piece_1"><span><b>level_down_piece_1</b><small>剪刀</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_up_piece_1.png" alt="level_up_piece_1"><span><b>level_up_piece_1</b><small>万能宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 13,
  &quot;Spread_StorageMaxNumber&quot;: 13,
  &quot;Spread_Weight&quot;: [
    &quot;2602-2&quot;,
    &quot;2603-2&quot;,
    &quot;905-2&quot;,
    &quot;906-2&quot;,
    &quot;2502-2&quot;,
    &quot;2503-1&quot;,
    &quot;level_down_piece_1-1&quot;,
    &quot;level_up_piece_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;gift_lori_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_anni_cake_a_1</b><small>四周年蛋糕</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 5,
  &quot;Spread_StorageMaxNumber&quot;: 5,
  &quot;Spread_TransformNumber&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;2601-4&quot;,
    &quot;2401-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;main_anni_cake_b_1-10&quot;
  ],
  &quot;Type&quot;: &quot;main_anni_cake_a_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_anni_cake_b_1</b><small>四周年蛋糕</small></span></span></td><td>0</td><td>0</td><td>14400</td><td>98</td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 14400,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_StorageMaxNumber&quot;: 6,
  &quot;Spread_TransformNumber&quot;: 6,
  &quot;Spread_Weight&quot;: [
    &quot;2601-4&quot;,
    &quot;2401-1&quot;,
    &quot;2501-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;main_anni_cake_c_1-10&quot;
  ],
  &quot;Type&quot;: &quot;main_anni_cake_b_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_anni_cake_c_1</b><small>四周年蛋糕</small></span></span></td><td>0</td><td>0</td><td>28800</td><td>98</td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>7</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 28800,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 7,
  &quot;Spread_StorageMaxNumber&quot;: 7,
  &quot;Spread_TransformNumber&quot;: 7,
  &quot;Spread_Weight&quot;: [
    &quot;2601-4&quot;,
    &quot;2401-2&quot;,
    &quot;2501-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;main_anni_cake_d_1-10&quot;
  ],
  &quot;Type&quot;: &quot;main_anni_cake_c_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_anni_cake_d_1</b><small>四周年蛋糕</small></span></span></td><td>0</td><td>0</td><td>43200</td><td>98</td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>7</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 43200,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 7,
  &quot;Spread_StorageMaxNumber&quot;: 7,
  &quot;Spread_TransformNumber&quot;: 7,
  &quot;Spread_Weight&quot;: [
    &quot;2601-4&quot;,
    &quot;2401-2&quot;,
    &quot;2501-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;main_anni_cake_e_1-10&quot;
  ],
  &quot;Type&quot;: &quot;main_anni_cake_d_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_anni_cake_e_1</b><small>四周年蛋糕</small></span></span></td><td>0</td><td>0</td><td>57600</td><td>98</td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 57600,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 9,
  &quot;Spread_StorageMaxNumber&quot;: 9,
  &quot;Spread_TransformNumber&quot;: 9,
  &quot;Spread_Weight&quot;: [
    &quot;2601-4&quot;,
    &quot;2401-3&quot;,
    &quot;2501-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;main_anni_cake_f_1-10&quot;
  ],
  &quot;Type&quot;: &quot;main_anni_cake_e_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_anni_cake_f_1</b><small>四周年蛋糕</small></span></span></td><td>0</td><td>0</td><td>86400</td><td>98</td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 3</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 86400,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;2601-4&quot;,
    &quot;2401-3&quot;,
    &quot;2501-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;main_anni_cake_f_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>gift_ziva_1</b><small>姬瓦的复古珠宝盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2403.png" alt="2403"><span><b>2403</b><small>大量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2404.png" alt="2404"><span><b>2404</b><small>一叠金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2405.png" alt="2405"><span><b>2405</b><small>金币堆</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_down_piece_1.png" alt="level_down_piece_1"><span><b>level_down_piece_1</b><small>剪刀</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_up_piece_1.png" alt="level_up_piece_1"><span><b>level_up_piece_1</b><small>万能宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 13,
  &quot;Spread_StorageMaxNumber&quot;: 13,
  &quot;Spread_Weight&quot;: [
    &quot;2402-2&quot;,
    &quot;2403-2&quot;,
    &quot;2404-2&quot;,
    &quot;2405-2&quot;,
    &quot;2502-2&quot;,
    &quot;2503-1&quot;,
    &quot;level_down_piece_1-1&quot;,
    &quot;level_up_piece_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;gift_ziva_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_hallow_ball_1.png" alt="main_hallow_ball_1"><span><b>main_hallow_ball_1</b><small>魔力水晶球</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>225</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>225</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 27<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 26<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 27</div></td><td>3</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 225,
  &quot;Spread_StorageMaxNumber&quot;: 225,
  &quot;Spread_Weight&quot;: [
    &quot;205-10&quot;,
    &quot;206-20&quot;,
    &quot;303-10&quot;,
    &quot;304-20&quot;,
    &quot;505-10&quot;,
    &quot;506-20&quot;,
    &quot;603-10&quot;,
    &quot;604-20&quot;,
    &quot;904-13&quot;,
    &quot;905-27&quot;,
    &quot;1103-9&quot;,
    &quot;1305-13&quot;,
    &quot;1306-26&quot;,
    &quot;1403-9&quot;,
    &quot;1805-13&quot;,
    &quot;1806-27&quot;
  ],
  &quot;Spread_WeightType&quot;: 3,
  &quot;Type&quot;: &quot;main_hallow_ball_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_hallow_book_1.png" alt="main_hallow_book_1"><span><b>main_hallow_book_1</b><small>怪异书籍</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>225</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>225</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 27<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 26<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 27</div></td><td>3</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 225,
  &quot;Spread_StorageMaxNumber&quot;: 225,
  &quot;Spread_Weight&quot;: [
    &quot;205-10&quot;,
    &quot;206-20&quot;,
    &quot;303-10&quot;,
    &quot;304-20&quot;,
    &quot;505-10&quot;,
    &quot;506-20&quot;,
    &quot;603-10&quot;,
    &quot;604-20&quot;,
    &quot;904-13&quot;,
    &quot;905-27&quot;,
    &quot;1103-9&quot;,
    &quot;1305-13&quot;,
    &quot;1306-26&quot;,
    &quot;1403-9&quot;,
    &quot;1805-13&quot;,
    &quot;1806-27&quot;
  ],
  &quot;Spread_WeightType&quot;: 3,
  &quot;Type&quot;: &quot;main_hallow_book_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_crystal_ball_1</b><small>如意水晶球</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>450</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>450</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span> × 40<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span> × 40<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/507.png" alt="507"><span><b>507</b><small>加糖咖啡</small></span></span> × 40<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span> × 40<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 27<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/906.png" alt="906"><span><b>906</b><small>海鲜意面</small></span></span> × 54<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1104.png" alt="1104"><span><b>1104</b><small>橙色纸杯蛋糕</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 27<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1307.png" alt="1307"><span><b>1307</b><small>鸭子漂浮圈</small></span></span> × 54<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 27<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1807.png" alt="1807"><span><b>1807</b><small>喇叭海螺</small></span></span> × 54</div></td><td>3</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 450,
  &quot;Spread_StorageMaxNumber&quot;: 450,
  &quot;Spread_Weight&quot;: [
    &quot;206-20&quot;,
    &quot;207-40&quot;,
    &quot;304-20&quot;,
    &quot;305-40&quot;,
    &quot;506-20&quot;,
    &quot;507-40&quot;,
    &quot;604-20&quot;,
    &quot;605-40&quot;,
    &quot;905-27&quot;,
    &quot;906-54&quot;,
    &quot;1104-20&quot;,
    &quot;1306-27&quot;,
    &quot;1307-54&quot;,
    &quot;1404-20&quot;,
    &quot;1806-27&quot;,
    &quot;1807-54&quot;
  ],
  &quot;Spread_WeightType&quot;: 3,
  &quot;Type&quot;: &quot;main_crystal_ball_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_super_ball_1</b><small>如意水晶球</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>450</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>450</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>4</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 450,
  &quot;Spread_StorageMaxNumber&quot;: 450,
  &quot;Spread_WeightType&quot;: 4,
  &quot;Type&quot;: &quot;main_super_ball_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_xmas_cake_a_1</b><small>节日庆典蛋糕</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>6</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 6,
  &quot;Spread_StorageMaxNumber&quot;: 6,
  &quot;Spread_TransformNumber&quot;: 6,
  &quot;Spread_Weight&quot;: [
    &quot;2601-4&quot;,
    &quot;2401-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;main_xmas_cake_b_1-10&quot;
  ],
  &quot;Type&quot;: &quot;main_xmas_cake_a_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_xmas_cake_b_1</b><small>节日庆典蛋糕</small></span></span></td><td>0</td><td>0</td><td>14400</td><td>98</td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>7</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 14400,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 7,
  &quot;Spread_StorageMaxNumber&quot;: 7,
  &quot;Spread_TransformNumber&quot;: 7,
  &quot;Spread_Weight&quot;: [
    &quot;2601-4&quot;,
    &quot;2401-1&quot;,
    &quot;2402-1&quot;,
    &quot;2501-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;main_xmas_cake_c_1-10&quot;
  ],
  &quot;Type&quot;: &quot;main_xmas_cake_b_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_xmas_cake_c_1</b><small>节日庆典蛋糕</small></span></span></td><td>0</td><td>0</td><td>28800</td><td>98</td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 28800,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 9,
  &quot;Spread_StorageMaxNumber&quot;: 9,
  &quot;Spread_TransformNumber&quot;: 9,
  &quot;Spread_Weight&quot;: [
    &quot;2601-3&quot;,
    &quot;2602-1&quot;,
    &quot;2401-2&quot;,
    &quot;2402-1&quot;,
    &quot;2501-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;main_xmas_cake_d_1-10&quot;
  ],
  &quot;Type&quot;: &quot;main_xmas_cake_c_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_xmas_cake_d_1</b><small>节日庆典蛋糕</small></span></span></td><td>0</td><td>0</td><td>43200</td><td>98</td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>9</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 43200,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 9,
  &quot;Spread_StorageMaxNumber&quot;: 9,
  &quot;Spread_TransformNumber&quot;: 9,
  &quot;Spread_Weight&quot;: [
    &quot;2601-3&quot;,
    &quot;2602-1&quot;,
    &quot;2401-2&quot;,
    &quot;2402-1&quot;,
    &quot;2501-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Transform_Weight&quot;: [
    &quot;main_xmas_cake_e_1-10&quot;
  ],
  &quot;Type&quot;: &quot;main_xmas_cake_d_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_xmas_cake_e_1</b><small>节日庆典蛋糕</small></span></span></td><td>0</td><td>0</td><td>57600</td><td>98</td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>10</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 3</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Rare&quot;: 1,
  &quot;SellingPrice&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_InitDuration&quot;: 57600,
  &quot;Spread_InitSpeedUpCost&quot;: 98,
  &quot;Spread_ItemMaxNumber&quot;: 10,
  &quot;Spread_StorageMaxNumber&quot;: 10,
  &quot;Spread_Weight&quot;: [
    &quot;2601-2&quot;,
    &quot;2602-2&quot;,
    &quot;2401-1&quot;,
    &quot;2402-2&quot;,
    &quot;2501-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;main_xmas_cake_e_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>gift_carmen_1</b><small>卡门的音乐盒</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>13</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2503.png" alt="2503"><span><b>2503</b><small>大量宝石</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_down_piece_1.png" alt="level_down_piece_1"><span><b>level_down_piece_1</b><small>剪刀</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/level_up_piece_1.png" alt="level_up_piece_1"><span><b>level_up_piece_1</b><small>万能宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 13,
  &quot;Spread_StorageMaxNumber&quot;: 13,
  &quot;Spread_Weight&quot;: [
    &quot;2601-2&quot;,
    &quot;2602-2&quot;,
    &quot;2603-2&quot;,
    &quot;2604-2&quot;,
    &quot;2502-2&quot;,
    &quot;2503-1&quot;,
    &quot;level_down_piece_1-1&quot;,
    &quot;level_up_piece_1-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;gift_carmen_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_e_chest_new_1.png" alt="main_e_chest_new_1"><span><b>main_e_chest_new_1</b><small>体力箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2604.png" alt="2604"><span><b>2604</b><small>四级体力瓶</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 5,
  &quot;Spread_StorageMaxNumber&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;2601-2&quot;,
    &quot;2602-1&quot;,
    &quot;2603-1&quot;,
    &quot;2604-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;main_e_chest_new_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_e_chest_new2_1.png" alt="main_e_chest_new2_1"><span><b>main_e_chest_new2_1</b><small>体力箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2601.png" alt="2601"><span><b>2601</b><small>一级体力瓶</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2602.png" alt="2602"><span><b>2602</b><small>二级体力瓶</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2603.png" alt="2603"><span><b>2603</b><small>三级体力瓶</small></span></span> × 2</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 5,
  &quot;Spread_StorageMaxNumber&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;2601-2&quot;,
    &quot;2602-1&quot;,
    &quot;2603-2&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;main_e_chest_new2_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_g_chest_new_1.png" alt="main_g_chest_new_1"><span><b>main_g_chest_new_1</b><small>存钱罐</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 3</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 5,
  &quot;Spread_StorageMaxNumber&quot;: 5,
  &quot;Spread_Weight&quot;: [
    &quot;2401-2&quot;,
    &quot;2402-3&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;main_g_chest_new_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_t_chest_new_1.png" alt="main_t_chest_new_1"><span><b>main_t_chest_new_1</b><small>欢迎礼物箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>120</td><td>2</td><td>7</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2401.png" alt="2401"><span><b>2401</b><small>一枚金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2402.png" alt="2402"><span><b>2402</b><small>少量金币</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2501.png" alt="2501"><span><b>2501</b><small>一颗宝石</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/2502.png" alt="2502"><span><b>2502</b><small>少量宝石</small></span></span> × 1</div></td><td>2</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 0,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 7,
  &quot;Spread_OpenDuration&quot;: 120,
  &quot;Spread_OpenSpeedUpCost&quot;: 2,
  &quot;Spread_StorageMaxNumber&quot;: 7,
  &quot;Spread_Weight&quot;: [
    &quot;2401-2&quot;,
    &quot;2402-2&quot;,
    &quot;2501-2&quot;,
    &quot;2502-1&quot;
  ],
  &quot;Spread_WeightType&quot;: 2,
  &quot;Type&quot;: &quot;main_t_chest_new_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_smart_pot_a_1</b><small>匠人花瓶</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>35</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>14</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 35,
  &quot;Spread_StorageMaxNumber&quot;: 14,
  &quot;Spread_WeightType&quot;: 5,
  &quot;Type&quot;: &quot;main_smart_pot_a_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_smart_pot_b_1</b><small>赤土陶器</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>80</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>27</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_StorageMaxNumber&quot;: 27,
  &quot;Spread_WeightType&quot;: 5,
  &quot;Type&quot;: &quot;main_smart_pot_b_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_smart_pot_c_1</b><small>祥瑞玉罐</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>150</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>27</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 150,
  &quot;Spread_StorageMaxNumber&quot;: 27,
  &quot;Spread_WeightType&quot;: 5,
  &quot;Type&quot;: &quot;main_smart_pot_c_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_smart_pot_d_1</b><small>松石茶瓮</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>250</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 250,
  &quot;Spread_StorageMaxNumber&quot;: 42,
  &quot;Spread_WeightType&quot;: 5,
  &quot;Type&quot;: &quot;main_smart_pot_d_1&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_smart_pot_e_1</b><small>鎏金宝罐</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>400</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>55</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>5</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_CostEnergy&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 400,
  &quot;Spread_StorageMaxNumber&quot;: 55,
  &quot;Spread_WeightType&quot;: 5,
  &quot;Type&quot;: &quot;main_smart_pot_e_1&quot;
}</pre></details></td></tr></tbody></table></div></div>


`ItemModelConfig_shell`：本页涉及 163 条；与默认表不同 9 条。相同记录的完整值见上表；不同记录完整列于下表，变体由配置选择决定。


### ItemModelConfig_shell 的不同记录（9 条）

来源：`Data.Config.ItemModelConfig_shell`。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 9 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>母体/棋子 ID<small style="display:block">Type</small></th><th>自动产出<small style="display:block">Spread_Auto</small></th><th>是否消耗能量<small style="display:block">Spread_CostEnergy</small></th><th>初始化时长（秒）<small style="display:block">Spread_InitDuration</small></th><th>初始化加速（宝石）<small style="display:block">Spread_InitSpeedUpCost</small></th><th>单轮次数上限<small style="display:block">Spread_ItemMaxNumber</small></th><th>单轮恢复（秒）<small style="display:block">Spread_ItemRecoveryDuration</small></th><th>单轮加速（宝石）<small style="display:block">Spread_ItemSpeedUpCost</small></th><th>开启时长（秒）<small style="display:block">Spread_OpenDuration</small></th><th>开启加速（宝石）<small style="display:block">Spread_OpenSpeedUpCost</small></th><th>储备次数上限<small style="display:block">Spread_StorageMaxNumber</small></th><th>储备恢复（秒）<small style="display:block">Spread_StorageRecoveryDuration</small></th><th>储备加速（宝石）<small style="display:block">Spread_StorageSpeedUpCost</small></th><th>变换点击次数<small style="display:block">Spread_TransformNumber</small></th><th>普通产物 × 权重<small style="display:block">Spread_Weight</small></th><th>产出模式<small style="display:block">Spread_WeightType</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 95<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 5<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1707&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-95&quot;,
    &quot;1802-5&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;1706&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 10<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1708&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-90&quot;,
    &quot;1802-10&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;1707&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 8<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 2<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1709&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-90&quot;,
    &quot;1802-8&quot;,
    &quot;1803-2&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;1708&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 89<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 8<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 3<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1710&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-89&quot;,
    &quot;1802-8&quot;,
    &quot;1803-3&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;1709&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 88<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 3<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1711&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-88&quot;,
    &quot;1802-9&quot;,
    &quot;1803-3&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1710&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>0</td><td>1</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>42</td><td>180</td><td>3</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>126</td><td>300</td><td>5</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 87<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 4<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-87&quot;,
    &quot;1802-9&quot;,
    &quot;1803-4&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;1711&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_order_chest_s_1.png" alt="main_order_chest_s_1"><span><b>main_order_chest_s_1</b><small>聪明宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>75</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>75</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 9</div></td><td>3</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Weight&quot;: [
    &quot;204-5&quot;,
    &quot;205-10&quot;,
    &quot;303-10&quot;,
    &quot;304-20&quot;,
    &quot;504-5&quot;,
    &quot;505-10&quot;,
    &quot;603-10&quot;,
    &quot;604-20&quot;,
    &quot;903-7&quot;,
    &quot;904-13&quot;,
    &quot;1103-9&quot;,
    &quot;1304-6&quot;,
    &quot;1305-13&quot;,
    &quot;1403-9&quot;,
    &quot;1804-7&quot;,
    &quot;1805-13&quot;,
    &quot;main_g_artifact_3-9&quot;
  ],
  &quot;Spread_ItemMaxNumber&quot;: 75,
  &quot;Spread_StorageMaxNumber&quot;: 75,
  &quot;Spread_Auto&quot;: 0,
  &quot;Type&quot;: &quot;main_order_chest_s_1&quot;,
  &quot;Spread_WeightType&quot;: 3,
  &quot;Spread_CostEnergy&quot;: 0
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_order_chest_m_1.png" alt="main_order_chest_m_1"><span><b>main_order_chest_m_1</b><small>睿智宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>150</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>150</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 27<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 26<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 27<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 9</div></td><td>3</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Weight&quot;: [
    &quot;205-10&quot;,
    &quot;206-20&quot;,
    &quot;303-10&quot;,
    &quot;304-20&quot;,
    &quot;505-10&quot;,
    &quot;506-20&quot;,
    &quot;603-10&quot;,
    &quot;604-20&quot;,
    &quot;904-13&quot;,
    &quot;905-27&quot;,
    &quot;1103-9&quot;,
    &quot;1305-13&quot;,
    &quot;1306-26&quot;,
    &quot;1403-9&quot;,
    &quot;1805-13&quot;,
    &quot;1806-27&quot;,
    &quot;main_g_artifact_3-9&quot;
  ],
  &quot;Spread_ItemMaxNumber&quot;: 150,
  &quot;Spread_StorageMaxNumber&quot;: 150,
  &quot;Spread_Auto&quot;: 0,
  &quot;Type&quot;: &quot;main_order_chest_m_1&quot;,
  &quot;Spread_WeightType&quot;: 3,
  &quot;Spread_CostEnergy&quot;: 0
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/main_order_chest_b_1.png" alt="main_order_chest_b_1"><span><b>main_order_chest_b_1</b><small>天才宝箱</small></span></span></td><td>0</td><td>0</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>225</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td>225</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 27<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 26<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 27<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 9</div></td><td>3</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Spread_Weight&quot;: [
    &quot;205-10&quot;,
    &quot;206-20&quot;,
    &quot;303-10&quot;,
    &quot;304-20&quot;,
    &quot;505-10&quot;,
    &quot;506-20&quot;,
    &quot;603-10&quot;,
    &quot;604-20&quot;,
    &quot;904-13&quot;,
    &quot;905-27&quot;,
    &quot;1103-9&quot;,
    &quot;1305-13&quot;,
    &quot;1306-26&quot;,
    &quot;1403-9&quot;,
    &quot;1805-13&quot;,
    &quot;1806-27&quot;,
    &quot;main_g_artifact_3-9&quot;
  ],
  &quot;Spread_ItemMaxNumber&quot;: 225,
  &quot;Spread_StorageMaxNumber&quot;: 225,
  &quot;Spread_Auto&quot;: 0,
  &quot;Type&quot;: &quot;main_order_chest_b_1&quot;,
  &quot;Spread_WeightType&quot;: 3,
  &quot;Spread_CostEnergy&quot;: 0
}</pre></details></td></tr></tbody></table></div></div>


`ItemModelConfig_carditem2`：本页涉及 163 条；与默认表不同 0 条。相同记录的完整值见上表；不同记录完整列于下表，变体由配置选择决定。


`ItemModelConfig_extracust`：本页涉及 163 条；与默认表不同 0 条。相同记录的完整值见上表；不同记录完整列于下表，变体由配置选择决定。


<!-- generator-configs:end -->
