# 配置选择、预处理与重载

## 1. 装载并建立母体索引

`Init` 先执行 BaseActivityModel 初始化，`_LoadFileConfig` 优先使用显式传入的 boostConfig，否则读取 LocalConfigKey.LuckyProduce。遍历每条配置的 generator，将同一母体的记录按源列表顺序放入 `m_mapGeneratorType2Config`；同一母体可以有多个等级段。

`LateInit → CalculateItemChainMap` 将 `"204-63"` 等字符串拆成 `{Item="204",Weight=63}`，补 ItemChainLevel 与 itemChainMap。模型配置不存在的候选保留在幸运物品列表，但不进入链索引。如果某配置第一项已经包含 Item，源码直接退出整个预处理函数；这依赖载入数据状态，不是逐条跳过。

## 2. 本次点击选择适用记录

`_GetLevelFitConfig` 先查母体键，再按列表顺序寻找玩家等级满足的第一条记录。level_min / level_max 缺失分别表示没有该侧限制，存在时两端均包含。区间重叠时第一条优先；没有适配记录就没有 Lucky 资格。实际使用哪个分组还取决于上层 ConfigModel 与活动配置，不能把所有包内变体相加。

## 3. GeneratorBoost 与重新加载

`GetGeneratorBoostConfig` 查询已开始的 GeneratorBoost 活动并读取 GetLuckyProduceConfig。`ReloadFileConfig(boostConfig,bUpdate)` 重新装载并预处理；bUpdate 为真时，只对新配置列出的母体调用两种机会计数清除方法。清除方法还要求该类型的数据库键已进入本进程键缓存，未缓存时直接返回。源码没有遍历数据库删除所有旧母体，也没有在这里清免费或连续状态。

## 4. 重装周期机会

点击读到总剩余为0时，才用已选配置的 `lucky_chance[1]`、`[2]` 重装总机会和 Lucky 配额。它不是每点击都重置。首次计数缺失按总剩余0处理；非零总剩余却缺 Lucky 计数的损坏状态没有这段代码的独立修复兜底。

**配表字段**：generator、level_min、level_max、lucky_chance、lucky_items、super_items。下方保留全部包内变体和记录；它们是可选来源，不代表账号同时生效。**源码**：Init、_LoadFileConfig、LateInit、CalculateItemChainMap、_GetLevelFitConfig、GetGeneratorBoostConfig、ReloadFileConfig、_ClearLuckyLeftSpreadCount、_ClearTotalLeftSpreadCount。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：食品袋105按母体类型与玩家等级选择一条Lucky配置，使用该条机会与产物池；活动重载可能改变来源并清已缓存键对应的周期计数。

### 代入本页的值

本地默认105配置等级[1,999]，lucky_chance=[60,1]，Lucky池总100。等级10选择此记录；若假设另一个来源有重叠等级记录，第一条适配优先。bUpdate=true重载会请求清105的周期键，但清除方法只有键在本进程缓存时才执行；免费与连续资格不在本函数清除。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- source-links:start -->

## 对应源码

[LuckyProduceModel.lua](../../../../assets/recovered-source/LuckyProduceModel.lua)

<!-- source-links:end -->

<!-- generator-configs:start -->

<a id="configuration-lucky"></a>

## 本页涉及的配表：Lucky 包内配置及活动变体

**实际读取链**：`LuckyProduceModel:_LoadFileConfig → _GetLevelFitConfig → Try2ProduceLuckyItem；按 generator、等级区间选择记录，再用 lucky_chance 重装机会池。`

本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。


### LuckyProduceConfig / 包内默认（10 条）

来源：`Data.Config.LuckyProduceConfig`。`lucky_chance=[总机会,Lucky配额]`；等级上下界均包含。不同变体由配置选择/活动决定，不同时叠加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 10 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>适用母体<small style="display:block">generator</small></th><th>玩家等级下限<small style="display:block">level_min</small></th><th>玩家等级上限<small style="display:block">level_max</small></th><th>总机会 / Lucky 配额<small style="display:block">lucky_chance</small></th><th>Lucky 产物 × 权重<small style="display:block">lucky_items</small></th><th>Super Lucky 产物<small style="display:block">super_items</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 63<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;205&quot;,
    &quot;304&quot;,
    &quot;305&quot;
  ],
  &quot;generator&quot;: [
    &quot;105&quot;,
    &quot;106&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;204-63&quot;,
    &quot;205-10&quot;,
    &quot;303-15&quot;,
    &quot;304-10&quot;,
    &quot;305-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 56<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;206&quot;,
    &quot;207&quot;,
    &quot;304&quot;,
    &quot;305&quot;
  ],
  &quot;generator&quot;: [
    &quot;107&quot;,
    &quot;108&quot;,
    &quot;109&quot;,
    &quot;110&quot;,
    &quot;111&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;205-56&quot;,
    &quot;206-15&quot;,
    &quot;207-2&quot;,
    &quot;303-15&quot;,
    &quot;304-10&quot;,
    &quot;305-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 63<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;505&quot;,
    &quot;604&quot;,
    &quot;605&quot;
  ],
  &quot;generator&quot;: [
    &quot;405&quot;,
    &quot;406&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;504-63&quot;,
    &quot;505-10&quot;,
    &quot;603-15&quot;,
    &quot;604-10&quot;,
    &quot;605-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 56<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/507.png" alt="507"><span><b>507</b><small>加糖咖啡</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/507.png" alt="507"><span><b>507</b><small>加糖咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;506&quot;,
    &quot;507&quot;,
    &quot;604&quot;,
    &quot;605&quot;
  ],
  &quot;generator&quot;: [
    &quot;407&quot;,
    &quot;408&quot;,
    &quot;409&quot;,
    &quot;410&quot;,
    &quot;411&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;505-56&quot;,
    &quot;506-15&quot;,
    &quot;507-2&quot;,
    &quot;603-15&quot;,
    &quot;604-10&quot;,
    &quot;605-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 10</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;905&quot;
  ],
  &quot;generator&quot;: [
    &quot;805&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;904-90&quot;,
    &quot;905-10&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1205.png" alt="1205"><span><b>1205</b><small>豪华泳池包</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;
  ],
  &quot;generator&quot;: [
    &quot;1205&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-75&quot;,
    &quot;1304-20&quot;,
    &quot;1305-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1206.png" alt="1206"><span><b>1206</b><small>高级海洋储存箱</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 53<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1206&quot;,
    &quot;1207&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-53&quot;,
    &quot;1304-15&quot;,
    &quot;1305-5&quot;,
    &quot;1403-12&quot;,
    &quot;1404-12&quot;,
    &quot;1405-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 53<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1306&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1208&quot;,
    &quot;1209&quot;,
    &quot;1210&quot;,
    &quot;1211&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1304-53&quot;,
    &quot;1305-15&quot;,
    &quot;1306-5&quot;,
    &quot;1403-12&quot;,
    &quot;1404-12&quot;,
    &quot;1405-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1705.png" alt="1705"><span><b>1705</b><small>小珊瑚丛</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>1</td><td>999</td><td><code>[70, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 30<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 10</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;
  ],
  &quot;generator&quot;: [
    &quot;1705&quot;,
    &quot;1706&quot;,
    &quot;1707&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    70,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-60&quot;,
    &quot;1804-30&quot;,
    &quot;1805-10&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>1</td><td>999</td><td><code>[50, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 30<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 10</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;1806&quot;
  ],
  &quot;generator&quot;: [
    &quot;1708&quot;,
    &quot;1709&quot;,
    &quot;1710&quot;,
    &quot;1711&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    50,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1804-60&quot;,
    &quot;1805-30&quot;,
    &quot;1806-10&quot;
  ]
}</pre></details></td></tr></tbody></table></div></div>


### LuckyProduceConfig_shell / 包内默认（11 条）

来源：`Data.Config.LuckyProduceConfig_shell`。`lucky_chance=[总机会,Lucky配额]`；等级上下界均包含。不同变体由配置选择/活动决定，不同时叠加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 11 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>适用母体<small style="display:block">generator</small></th><th>玩家等级下限<small style="display:block">level_min</small></th><th>玩家等级上限<small style="display:block">level_max</small></th><th>总机会 / Lucky 配额<small style="display:block">lucky_chance</small></th><th>Lucky 产物 × 权重<small style="display:block">lucky_items</small></th><th>Super Lucky 产物<small style="display:block">super_items</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 63<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;205&quot;,
    &quot;304&quot;,
    &quot;305&quot;
  ],
  &quot;generator&quot;: [
    &quot;105&quot;,
    &quot;106&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;204-63&quot;,
    &quot;205-10&quot;,
    &quot;303-15&quot;,
    &quot;304-10&quot;,
    &quot;305-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 56<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;206&quot;,
    &quot;207&quot;,
    &quot;304&quot;,
    &quot;305&quot;
  ],
  &quot;generator&quot;: [
    &quot;107&quot;,
    &quot;108&quot;,
    &quot;109&quot;,
    &quot;110&quot;,
    &quot;111&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;205-56&quot;,
    &quot;206-15&quot;,
    &quot;207-2&quot;,
    &quot;303-15&quot;,
    &quot;304-10&quot;,
    &quot;305-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 63<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;505&quot;,
    &quot;604&quot;,
    &quot;605&quot;
  ],
  &quot;generator&quot;: [
    &quot;405&quot;,
    &quot;406&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;504-63&quot;,
    &quot;505-10&quot;,
    &quot;603-15&quot;,
    &quot;604-10&quot;,
    &quot;605-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 56<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/507.png" alt="507"><span><b>507</b><small>加糖咖啡</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/507.png" alt="507"><span><b>507</b><small>加糖咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;506&quot;,
    &quot;507&quot;,
    &quot;604&quot;,
    &quot;605&quot;
  ],
  &quot;generator&quot;: [
    &quot;407&quot;,
    &quot;408&quot;,
    &quot;409&quot;,
    &quot;410&quot;,
    &quot;411&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;505-56&quot;,
    &quot;506-15&quot;,
    &quot;507-2&quot;,
    &quot;603-15&quot;,
    &quot;604-10&quot;,
    &quot;605-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 10</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;905&quot;
  ],
  &quot;generator&quot;: [
    &quot;805&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;904-90&quot;,
    &quot;905-10&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1205.png" alt="1205"><span><b>1205</b><small>豪华泳池包</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;
  ],
  &quot;generator&quot;: [
    &quot;1205&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-75&quot;,
    &quot;1304-20&quot;,
    &quot;1305-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1206.png" alt="1206"><span><b>1206</b><small>高级海洋储存箱</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 53<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1206&quot;,
    &quot;1207&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-53&quot;,
    &quot;1304-15&quot;,
    &quot;1305-5&quot;,
    &quot;1403-12&quot;,
    &quot;1404-12&quot;,
    &quot;1405-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 53<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1306&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1208&quot;,
    &quot;1209&quot;,
    &quot;1210&quot;,
    &quot;1211&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1304-53&quot;,
    &quot;1305-15&quot;,
    &quot;1306-5&quot;,
    &quot;1403-12&quot;,
    &quot;1404-12&quot;,
    &quot;1405-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1705.png" alt="1705"><span><b>1705</b><small>小珊瑚丛</small></span></span></td><td>1</td><td>999</td><td><code>[70, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 30<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 10</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;
  ],
  &quot;generator&quot;: [
    &quot;1705&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    70,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-60&quot;,
    &quot;1804-30&quot;,
    &quot;1805-10&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>1</td><td>999</td><td><code>[70, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 30<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 10<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 12<br><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span> × 5<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span><span class="config-piece"><span><b>main_g_artifact_5</b><small>无本地视图映射</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;main_g_artifact_4&quot;,
    &quot;main_g_artifact_5&quot;
  ],
  &quot;generator&quot;: [
    &quot;1706&quot;,
    &quot;1707&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    70,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-60&quot;,
    &quot;1804-30&quot;,
    &quot;1805-10&quot;,
    &quot;main_g_artifact_3-12&quot;,
    &quot;main_g_artifact_4-5&quot;,
    &quot;main_g_artifact_3-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>1</td><td>999</td><td><code>[50, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 30<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 10<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 12<br><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span> × 5<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span><span class="config-piece"><span><b>main_g_artifact_5</b><small>无本地视图映射</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;1806&quot;,
    &quot;main_g_artifact_4&quot;,
    &quot;main_g_artifact_5&quot;
  ],
  &quot;generator&quot;: [
    &quot;1708&quot;,
    &quot;1709&quot;,
    &quot;1710&quot;,
    &quot;1711&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    50,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1804-60&quot;,
    &quot;1805-30&quot;,
    &quot;1806-10&quot;,
    &quot;main_g_artifact_3-12&quot;,
    &quot;main_g_artifact_4-5&quot;,
    &quot;main_g_artifact_3-2&quot;
  ]
}</pre></details></td></tr></tbody></table></div></div>


### LuckyProduceConfig_triple / 包内默认（10 条）

来源：`Data.Config.LuckyProduceConfig_triple`。`lucky_chance=[总机会,Lucky配额]`；等级上下界均包含。不同变体由配置选择/活动决定，不同时叠加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 10 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>适用母体<small style="display:block">generator</small></th><th>玩家等级下限<small style="display:block">level_min</small></th><th>玩家等级上限<small style="display:block">level_max</small></th><th>总机会 / Lucky 配额<small style="display:block">lucky_chance</small></th><th>Lucky 产物 × 权重<small style="display:block">lucky_items</small></th><th>Super Lucky 产物<small style="display:block">super_items</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>1</td><td>999</td><td><code>[65, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 63<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 18<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;205&quot;,
    &quot;304&quot;,
    &quot;305&quot;
  ],
  &quot;generator&quot;: [
    &quot;105&quot;,
    &quot;106&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    65,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;204-63&quot;,
    &quot;205-10&quot;,
    &quot;303-18&quot;,
    &quot;304-7&quot;,
    &quot;305-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>1</td><td>999</td><td><code>[65, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 65<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 18<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;206&quot;,
    &quot;207&quot;,
    &quot;304&quot;,
    &quot;305&quot;
  ],
  &quot;generator&quot;: [
    &quot;107&quot;,
    &quot;108&quot;,
    &quot;109&quot;,
    &quot;110&quot;,
    &quot;111&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    65,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;205-65&quot;,
    &quot;206-10&quot;,
    &quot;207-1&quot;,
    &quot;303-18&quot;,
    &quot;304-7&quot;,
    &quot;305-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>1</td><td>999</td><td><code>[65, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 63<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 18<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;505&quot;,
    &quot;604&quot;,
    &quot;605&quot;
  ],
  &quot;generator&quot;: [
    &quot;405&quot;,
    &quot;406&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    65,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;504-63&quot;,
    &quot;505-10&quot;,
    &quot;603-18&quot;,
    &quot;604-7&quot;,
    &quot;605-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>1</td><td>999</td><td><code>[65, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 65<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/507.png" alt="507"><span><b>507</b><small>加糖咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 18<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/507.png" alt="507"><span><b>507</b><small>加糖咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;506&quot;,
    &quot;507&quot;,
    &quot;604&quot;,
    &quot;605&quot;
  ],
  &quot;generator&quot;: [
    &quot;407&quot;,
    &quot;408&quot;,
    &quot;409&quot;,
    &quot;410&quot;,
    &quot;411&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    65,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;505-65&quot;,
    &quot;506-10&quot;,
    &quot;507-1&quot;,
    &quot;603-18&quot;,
    &quot;604-7&quot;,
    &quot;605-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>1</td><td>999</td><td><code>[65, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 95<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;905&quot;
  ],
  &quot;generator&quot;: [
    &quot;805&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    65,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;904-95&quot;,
    &quot;905-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1205.png" alt="1205"><span><b>1205</b><small>豪华泳池包</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;
  ],
  &quot;generator&quot;: [
    &quot;1205&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-75&quot;,
    &quot;1304-20&quot;,
    &quot;1305-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1206.png" alt="1206"><span><b>1206</b><small>高级海洋储存箱</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1206&quot;,
    &quot;1207&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-60&quot;,
    &quot;1304-10&quot;,
    &quot;1305-3&quot;,
    &quot;1403-13&quot;,
    &quot;1404-9&quot;,
    &quot;1405-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1306&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1208&quot;,
    &quot;1209&quot;,
    &quot;1210&quot;,
    &quot;1211&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1304-60&quot;,
    &quot;1305-10&quot;,
    &quot;1306-3&quot;,
    &quot;1403-13&quot;,
    &quot;1404-9&quot;,
    &quot;1405-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1705.png" alt="1705"><span><b>1705</b><small>小珊瑚丛</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>1</td><td>999</td><td><code>[70, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 70<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 25<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;
  ],
  &quot;generator&quot;: [
    &quot;1705&quot;,
    &quot;1706&quot;,
    &quot;1707&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    70,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-70&quot;,
    &quot;1804-25&quot;,
    &quot;1805-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>1</td><td>999</td><td><code>[55, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 68<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 25<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 7</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;1806&quot;
  ],
  &quot;generator&quot;: [
    &quot;1708&quot;,
    &quot;1709&quot;,
    &quot;1710&quot;,
    &quot;1711&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    55,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1804-68&quot;,
    &quot;1805-25&quot;,
    &quot;1806-7&quot;
  ]
}</pre></details></td></tr></tbody></table></div></div>


### LuckyProduceConfig_tripleshell / 包内默认（11 条）

来源：`Data.Config.LuckyProduceConfig_tripleshell`。`lucky_chance=[总机会,Lucky配额]`；等级上下界均包含。不同变体由配置选择/活动决定，不同时叠加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 11 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>适用母体<small style="display:block">generator</small></th><th>玩家等级下限<small style="display:block">level_min</small></th><th>玩家等级上限<small style="display:block">level_max</small></th><th>总机会 / Lucky 配额<small style="display:block">lucky_chance</small></th><th>Lucky 产物 × 权重<small style="display:block">lucky_items</small></th><th>Super Lucky 产物<small style="display:block">super_items</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>1</td><td>999</td><td><code>[65, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 63<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 18<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;205&quot;,
    &quot;304&quot;,
    &quot;305&quot;
  ],
  &quot;generator&quot;: [
    &quot;105&quot;,
    &quot;106&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    65,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;204-63&quot;,
    &quot;205-10&quot;,
    &quot;303-18&quot;,
    &quot;304-7&quot;,
    &quot;305-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>1</td><td>999</td><td><code>[65, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 65<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 18<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;206&quot;,
    &quot;207&quot;,
    &quot;304&quot;,
    &quot;305&quot;
  ],
  &quot;generator&quot;: [
    &quot;107&quot;,
    &quot;108&quot;,
    &quot;109&quot;,
    &quot;110&quot;,
    &quot;111&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    65,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;205-65&quot;,
    &quot;206-10&quot;,
    &quot;207-1&quot;,
    &quot;303-18&quot;,
    &quot;304-7&quot;,
    &quot;305-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>1</td><td>999</td><td><code>[65, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 63<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 18<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;505&quot;,
    &quot;604&quot;,
    &quot;605&quot;
  ],
  &quot;generator&quot;: [
    &quot;405&quot;,
    &quot;406&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    65,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;504-63&quot;,
    &quot;505-10&quot;,
    &quot;603-18&quot;,
    &quot;604-7&quot;,
    &quot;605-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>1</td><td>999</td><td><code>[65, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 65<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/507.png" alt="507"><span><b>507</b><small>加糖咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 18<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/507.png" alt="507"><span><b>507</b><small>加糖咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;506&quot;,
    &quot;507&quot;,
    &quot;604&quot;,
    &quot;605&quot;
  ],
  &quot;generator&quot;: [
    &quot;407&quot;,
    &quot;408&quot;,
    &quot;409&quot;,
    &quot;410&quot;,
    &quot;411&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    65,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;505-65&quot;,
    &quot;506-10&quot;,
    &quot;507-1&quot;,
    &quot;603-18&quot;,
    &quot;604-7&quot;,
    &quot;605-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>1</td><td>999</td><td><code>[65, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 95<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;905&quot;
  ],
  &quot;generator&quot;: [
    &quot;805&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    65,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;904-95&quot;,
    &quot;905-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1205.png" alt="1205"><span><b>1205</b><small>豪华泳池包</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;
  ],
  &quot;generator&quot;: [
    &quot;1205&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-75&quot;,
    &quot;1304-20&quot;,
    &quot;1305-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1206.png" alt="1206"><span><b>1206</b><small>高级海洋储存箱</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1206&quot;,
    &quot;1207&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-60&quot;,
    &quot;1304-10&quot;,
    &quot;1305-3&quot;,
    &quot;1403-13&quot;,
    &quot;1404-9&quot;,
    &quot;1405-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1306&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1208&quot;,
    &quot;1209&quot;,
    &quot;1210&quot;,
    &quot;1211&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1304-60&quot;,
    &quot;1305-10&quot;,
    &quot;1306-3&quot;,
    &quot;1403-13&quot;,
    &quot;1404-9&quot;,
    &quot;1405-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1705.png" alt="1705"><span><b>1705</b><small>小珊瑚丛</small></span></span></td><td>1</td><td>999</td><td><code>[70, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 70<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 25<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;
  ],
  &quot;generator&quot;: [
    &quot;1705&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    70,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-70&quot;,
    &quot;1804-25&quot;,
    &quot;1805-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>1</td><td>999</td><td><code>[70, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 70<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 25<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 5<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 14<br><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span> × 4<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 1</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span><span class="config-piece"><span><b>main_g_artifact_5</b><small>无本地视图映射</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;main_g_artifact_4&quot;,
    &quot;main_g_artifact_5&quot;
  ],
  &quot;generator&quot;: [
    &quot;1706&quot;,
    &quot;1707&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    70,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-70&quot;,
    &quot;1804-25&quot;,
    &quot;1805-5&quot;,
    &quot;main_g_artifact_3-14&quot;,
    &quot;main_g_artifact_4-4&quot;,
    &quot;main_g_artifact_3-1&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>1</td><td>999</td><td><code>[55, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 68<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 25<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 7<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 14<br><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span> × 4<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 1</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span><span class="config-piece"><span><b>main_g_artifact_5</b><small>无本地视图映射</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;1806&quot;,
    &quot;main_g_artifact_4&quot;,
    &quot;main_g_artifact_5&quot;
  ],
  &quot;generator&quot;: [
    &quot;1708&quot;,
    &quot;1709&quot;,
    &quot;1710&quot;,
    &quot;1711&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    55,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1804-68&quot;,
    &quot;1805-25&quot;,
    &quot;1806-7&quot;,
    &quot;main_g_artifact_3-14&quot;,
    &quot;main_g_artifact_4-4&quot;,
    &quot;main_g_artifact_3-1&quot;
  ]
}</pre></details></td></tr></tbody></table></div></div>


### GeneratorBoostLuckyProduceConfig / MoreLuckyProduce（10 条）

来源：`Data.Config.GeneratorBoostLuckyProduceConfig`。`lucky_chance=[总机会,Lucky配额]`；等级上下界均包含。不同变体由配置选择/活动决定，不同时叠加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 10 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>适用母体<small style="display:block">generator</small></th><th>玩家等级下限<small style="display:block">level_min</small></th><th>玩家等级上限<small style="display:block">level_max</small></th><th>总机会 / Lucky 配额<small style="display:block">lucky_chance</small></th><th>Lucky 产物 × 权重<small style="display:block">lucky_items</small></th><th>Super Lucky 产物<small style="display:block">super_items</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 66<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;205&quot;,
    &quot;304&quot;
  ],
  &quot;generator&quot;: [
    &quot;105&quot;,
    &quot;106&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;204-66&quot;,
    &quot;205-7&quot;,
    &quot;303-24&quot;,
    &quot;304-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 25<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;205&quot;,
    &quot;206&quot;,
    &quot;304&quot;
  ],
  &quot;generator&quot;: [
    &quot;107&quot;,
    &quot;108&quot;,
    &quot;109&quot;,
    &quot;110&quot;,
    &quot;111&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;204-10&quot;,
    &quot;205-60&quot;,
    &quot;206-3&quot;,
    &quot;303-25&quot;,
    &quot;304-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 66<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;505&quot;,
    &quot;604&quot;
  ],
  &quot;generator&quot;: [
    &quot;405&quot;,
    &quot;406&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;504-66&quot;,
    &quot;505-7&quot;,
    &quot;603-24&quot;,
    &quot;604-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 25<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;505&quot;,
    &quot;506&quot;,
    &quot;604&quot;
  ],
  &quot;generator&quot;: [
    &quot;407&quot;,
    &quot;408&quot;,
    &quot;409&quot;,
    &quot;410&quot;,
    &quot;411&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;504-10&quot;,
    &quot;505-60&quot;,
    &quot;506-3&quot;,
    &quot;603-25&quot;,
    &quot;604-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 30<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 50<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;905&quot;
  ],
  &quot;generator&quot;: [
    &quot;805&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;903-30&quot;,
    &quot;904-50&quot;,
    &quot;905-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1205.png" alt="1205"><span><b>1205</b><small>豪华泳池包</small></span></span></td><td>1</td><td>999</td><td><code>[30, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 82<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;
  ],
  &quot;generator&quot;: [
    &quot;1205&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    30,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-82&quot;,
    &quot;1304-15&quot;,
    &quot;1305-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1206.png" alt="1206"><span><b>1206</b><small>高级海洋储存箱</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>1</td><td>999</td><td><code>[30, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 58<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 19<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1404&quot;
  ],
  &quot;generator&quot;: [
    &quot;1206&quot;,
    &quot;1207&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    30,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-58&quot;,
    &quot;1304-15&quot;,
    &quot;1305-3&quot;,
    &quot;1403-19&quot;,
    &quot;1404-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>1</td><td>999</td><td><code>[30, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 62<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1404&quot;
  ],
  &quot;generator&quot;: [
    &quot;1208&quot;,
    &quot;1209&quot;,
    &quot;1210&quot;,
    &quot;1211&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    30,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1304-62&quot;,
    &quot;1305-13&quot;,
    &quot;1403-20&quot;,
    &quot;1404-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1705.png" alt="1705"><span><b>1705</b><small>小珊瑚丛</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>1</td><td>999</td><td><code>[30, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;
  ],
  &quot;generator&quot;: [
    &quot;1705&quot;,
    &quot;1706&quot;,
    &quot;1707&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    30,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-75&quot;,
    &quot;1804-20&quot;,
    &quot;1805-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 84<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;1806&quot;
  ],
  &quot;generator&quot;: [
    &quot;1708&quot;,
    &quot;1709&quot;,
    &quot;1710&quot;,
    &quot;1711&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1804-84&quot;,
    &quot;1805-13&quot;,
    &quot;1806-3&quot;
  ]
}</pre></details></td></tr></tbody></table></div></div>


### GeneratorBoostLuckyProduceConfig / ExtraLuckyProduce（10 条）

来源：`Data.Config.GeneratorBoostLuckyProduceConfig`。`lucky_chance=[总机会,Lucky配额]`；等级上下界均包含。不同变体由配置选择/活动决定，不同时叠加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 10 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>适用母体<small style="display:block">generator</small></th><th>玩家等级下限<small style="display:block">level_min</small></th><th>玩家等级上限<small style="display:block">level_max</small></th><th>总机会 / Lucky 配额<small style="display:block">lucky_chance</small></th><th>Lucky 产物 × 权重<small style="display:block">lucky_items</small></th><th>Super Lucky 产物<small style="display:block">super_items</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 66<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;205&quot;,
    &quot;304&quot;
  ],
  &quot;generator&quot;: [
    &quot;105&quot;,
    &quot;106&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;204-66&quot;,
    &quot;205-7&quot;,
    &quot;303-24&quot;,
    &quot;304-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 70<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;206&quot;,
    &quot;304&quot;
  ],
  &quot;generator&quot;: [
    &quot;107&quot;,
    &quot;108&quot;,
    &quot;109&quot;,
    &quot;110&quot;,
    &quot;111&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;205-70&quot;,
    &quot;206-3&quot;,
    &quot;303-24&quot;,
    &quot;304-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 66<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;505&quot;,
    &quot;604&quot;
  ],
  &quot;generator&quot;: [
    &quot;405&quot;,
    &quot;406&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;504-66&quot;,
    &quot;505-7&quot;,
    &quot;603-24&quot;,
    &quot;604-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 70<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;506&quot;,
    &quot;604&quot;
  ],
  &quot;generator&quot;: [
    &quot;407&quot;,
    &quot;408&quot;,
    &quot;409&quot;,
    &quot;410&quot;,
    &quot;411&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;505-70&quot;,
    &quot;506-3&quot;,
    &quot;603-24&quot;,
    &quot;604-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 10</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;905&quot;
  ],
  &quot;generator&quot;: [
    &quot;805&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;904-90&quot;,
    &quot;905-10&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1205.png" alt="1205"><span><b>1205</b><small>豪华泳池包</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 80<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;
  ],
  &quot;generator&quot;: [
    &quot;1205&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-80&quot;,
    &quot;1304-15&quot;,
    &quot;1305-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1206.png" alt="1206"><span><b>1206</b><small>高级海洋储存箱</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 56<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 17<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 1</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1206&quot;,
    &quot;1207&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-56&quot;,
    &quot;1304-15&quot;,
    &quot;1305-5&quot;,
    &quot;1403-17&quot;,
    &quot;1404-6&quot;,
    &quot;1405-1&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 17<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1306&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1208&quot;,
    &quot;1209&quot;,
    &quot;1210&quot;,
    &quot;1211&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1304-60&quot;,
    &quot;1305-12&quot;,
    &quot;1306-3&quot;,
    &quot;1403-17&quot;,
    &quot;1404-6&quot;,
    &quot;1405-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1705.png" alt="1705"><span><b>1705</b><small>小珊瑚丛</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>1</td><td>999</td><td><code>[70, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;
  ],
  &quot;generator&quot;: [
    &quot;1705&quot;,
    &quot;1706&quot;,
    &quot;1707&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    70,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-75&quot;,
    &quot;1804-20&quot;,
    &quot;1805-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>1</td><td>999</td><td><code>[50, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 84<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;1806&quot;
  ],
  &quot;generator&quot;: [
    &quot;1708&quot;,
    &quot;1709&quot;,
    &quot;1710&quot;,
    &quot;1711&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    50,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1804-84&quot;,
    &quot;1805-13&quot;,
    &quot;1806-3&quot;
  ]
}</pre></details></td></tr></tbody></table></div></div>


### GeneratorBoostLuckyProduceConfig_shell / MoreLuckyProduce（11 条）

来源：`Data.Config.GeneratorBoostLuckyProduceConfig_shell`。`lucky_chance=[总机会,Lucky配额]`；等级上下界均包含。不同变体由配置选择/活动决定，不同时叠加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 11 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>适用母体<small style="display:block">generator</small></th><th>玩家等级下限<small style="display:block">level_min</small></th><th>玩家等级上限<small style="display:block">level_max</small></th><th>总机会 / Lucky 配额<small style="display:block">lucky_chance</small></th><th>Lucky 产物 × 权重<small style="display:block">lucky_items</small></th><th>Super Lucky 产物<small style="display:block">super_items</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 66<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;205&quot;,
    &quot;304&quot;
  ],
  &quot;generator&quot;: [
    &quot;105&quot;,
    &quot;106&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;204-66&quot;,
    &quot;205-7&quot;,
    &quot;303-24&quot;,
    &quot;304-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 25<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;205&quot;,
    &quot;206&quot;,
    &quot;304&quot;
  ],
  &quot;generator&quot;: [
    &quot;107&quot;,
    &quot;108&quot;,
    &quot;109&quot;,
    &quot;110&quot;,
    &quot;111&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;204-10&quot;,
    &quot;205-60&quot;,
    &quot;206-3&quot;,
    &quot;303-25&quot;,
    &quot;304-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 66<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;505&quot;,
    &quot;604&quot;
  ],
  &quot;generator&quot;: [
    &quot;405&quot;,
    &quot;406&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;504-66&quot;,
    &quot;505-7&quot;,
    &quot;603-24&quot;,
    &quot;604-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 10<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 25<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;505&quot;,
    &quot;506&quot;,
    &quot;604&quot;
  ],
  &quot;generator&quot;: [
    &quot;407&quot;,
    &quot;408&quot;,
    &quot;409&quot;,
    &quot;410&quot;,
    &quot;411&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;504-10&quot;,
    &quot;505-60&quot;,
    &quot;506-3&quot;,
    &quot;603-25&quot;,
    &quot;604-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span> × 30<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 50<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;905&quot;
  ],
  &quot;generator&quot;: [
    &quot;805&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;903-30&quot;,
    &quot;904-50&quot;,
    &quot;905-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1205.png" alt="1205"><span><b>1205</b><small>豪华泳池包</small></span></span></td><td>1</td><td>999</td><td><code>[30, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 82<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;
  ],
  &quot;generator&quot;: [
    &quot;1205&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    30,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-82&quot;,
    &quot;1304-15&quot;,
    &quot;1305-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1206.png" alt="1206"><span><b>1206</b><small>高级海洋储存箱</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>1</td><td>999</td><td><code>[30, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 58<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 19<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1404&quot;
  ],
  &quot;generator&quot;: [
    &quot;1206&quot;,
    &quot;1207&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    30,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-58&quot;,
    &quot;1304-15&quot;,
    &quot;1305-3&quot;,
    &quot;1403-19&quot;,
    &quot;1404-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>1</td><td>999</td><td><code>[30, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 62<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1404&quot;
  ],
  &quot;generator&quot;: [
    &quot;1208&quot;,
    &quot;1209&quot;,
    &quot;1210&quot;,
    &quot;1211&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    30,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1304-62&quot;,
    &quot;1305-13&quot;,
    &quot;1403-20&quot;,
    &quot;1404-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1705.png" alt="1705"><span><b>1705</b><small>小珊瑚丛</small></span></span></td><td>1</td><td>999</td><td><code>[30, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;
  ],
  &quot;generator&quot;: [
    &quot;1705&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    30,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-75&quot;,
    &quot;1804-20&quot;,
    &quot;1805-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>1</td><td>999</td><td><code>[30, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 5<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 12<br><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span> × 3<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 1</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span><span class="config-piece"><span><b>main_g_artifact_5</b><small>无本地视图映射</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;main_g_artifact_4&quot;,
    &quot;main_g_artifact_5&quot;
  ],
  &quot;generator&quot;: [
    &quot;1706&quot;,
    &quot;1707&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    30,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-75&quot;,
    &quot;1804-20&quot;,
    &quot;1805-5&quot;,
    &quot;main_g_artifact_3-12&quot;,
    &quot;main_g_artifact_4-3&quot;,
    &quot;main_g_artifact_3-1&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>1</td><td>999</td><td><code>[25, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 84<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 3<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 12<br><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span> × 3<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 1</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span><span class="config-piece"><span><b>main_g_artifact_5</b><small>无本地视图映射</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;1806&quot;,
    &quot;main_g_artifact_4&quot;,
    &quot;main_g_artifact_5&quot;
  ],
  &quot;generator&quot;: [
    &quot;1708&quot;,
    &quot;1709&quot;,
    &quot;1710&quot;,
    &quot;1711&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    25,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1804-84&quot;,
    &quot;1805-13&quot;,
    &quot;1806-3&quot;,
    &quot;main_g_artifact_3-12&quot;,
    &quot;main_g_artifact_4-3&quot;,
    &quot;main_g_artifact_3-1&quot;
  ]
}</pre></details></td></tr></tbody></table></div></div>


### GeneratorBoostLuckyProduceConfig_shell / ExtraLuckyProduce（11 条）

来源：`Data.Config.GeneratorBoostLuckyProduceConfig_shell`。`lucky_chance=[总机会,Lucky配额]`；等级上下界均包含。不同变体由配置选择/活动决定，不同时叠加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 11 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>适用母体<small style="display:block">generator</small></th><th>玩家等级下限<small style="display:block">level_min</small></th><th>玩家等级上限<small style="display:block">level_max</small></th><th>总机会 / Lucky 配额<small style="display:block">lucky_chance</small></th><th>Lucky 产物 × 权重<small style="display:block">lucky_items</small></th><th>Super Lucky 产物<small style="display:block">super_items</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span> × 66<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;205&quot;,
    &quot;304&quot;
  ],
  &quot;generator&quot;: [
    &quot;105&quot;,
    &quot;106&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;204-66&quot;,
    &quot;205-7&quot;,
    &quot;303-24&quot;,
    &quot;304-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span> × 70<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;206&quot;,
    &quot;304&quot;
  ],
  &quot;generator&quot;: [
    &quot;107&quot;,
    &quot;108&quot;,
    &quot;109&quot;,
    &quot;110&quot;,
    &quot;111&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;205-70&quot;,
    &quot;206-3&quot;,
    &quot;303-24&quot;,
    &quot;304-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span> × 66<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;505&quot;,
    &quot;604&quot;
  ],
  &quot;generator&quot;: [
    &quot;405&quot;,
    &quot;406&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;504-66&quot;,
    &quot;505-7&quot;,
    &quot;603-24&quot;,
    &quot;604-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span> × 70<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span> × 24<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span> × 3</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;506&quot;,
    &quot;604&quot;
  ],
  &quot;generator&quot;: [
    &quot;407&quot;,
    &quot;408&quot;,
    &quot;409&quot;,
    &quot;410&quot;,
    &quot;411&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;505-70&quot;,
    &quot;506-3&quot;,
    &quot;603-24&quot;,
    &quot;604-3&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>1</td><td>999</td><td><code>[60, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span> × 90<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span> × 10</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;905&quot;
  ],
  &quot;generator&quot;: [
    &quot;805&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    60,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;904-90&quot;,
    &quot;905-10&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1205.png" alt="1205"><span><b>1205</b><small>豪华泳池包</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 80<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;
  ],
  &quot;generator&quot;: [
    &quot;1205&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-80&quot;,
    &quot;1304-15&quot;,
    &quot;1305-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1206.png" alt="1206"><span><b>1206</b><small>高级海洋储存箱</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span> × 56<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 15<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 17<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 1</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1206&quot;,
    &quot;1207&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1303-56&quot;,
    &quot;1304-15&quot;,
    &quot;1305-5&quot;,
    &quot;1403-17&quot;,
    &quot;1404-6&quot;,
    &quot;1405-1&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>1</td><td>999</td><td><code>[80, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span> × 60<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span> × 12<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span> × 17<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span> × 2</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1305&quot;,
    &quot;1306&quot;,
    &quot;1404&quot;,
    &quot;1405&quot;
  ],
  &quot;generator&quot;: [
    &quot;1208&quot;,
    &quot;1209&quot;,
    &quot;1210&quot;,
    &quot;1211&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    80,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1304-60&quot;,
    &quot;1305-12&quot;,
    &quot;1306-3&quot;,
    &quot;1403-17&quot;,
    &quot;1404-6&quot;,
    &quot;1405-2&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1705.png" alt="1705"><span><b>1705</b><small>小珊瑚丛</small></span></span></td><td>1</td><td>999</td><td><code>[70, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 5</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;
  ],
  &quot;generator&quot;: [
    &quot;1705&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    70,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-75&quot;,
    &quot;1804-20&quot;,
    &quot;1805-5&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>1</td><td>999</td><td><code>[70, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 75<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 20<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 5<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 12<br><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span> × 3<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 1</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span><span class="config-piece"><span><b>main_g_artifact_5</b><small>无本地视图映射</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;main_g_artifact_4&quot;,
    &quot;main_g_artifact_5&quot;
  ],
  &quot;generator&quot;: [
    &quot;1706&quot;,
    &quot;1707&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    70,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1803-75&quot;,
    &quot;1804-20&quot;,
    &quot;1805-5&quot;,
    &quot;main_g_artifact_3-12&quot;,
    &quot;main_g_artifact_4-3&quot;,
    &quot;main_g_artifact_3-1&quot;
  ]
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>1</td><td>999</td><td><code>[50, 1]</code></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span> × 84<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span> × 13<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span> × 3<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 12<br><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span> × 3<br><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span> × 1</div></td><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span><span class="config-piece"><span><b>main_g_artifact_5</b><small>无本地视图映射</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;super_items&quot;: [
    &quot;1805&quot;,
    &quot;1806&quot;,
    &quot;main_g_artifact_4&quot;,
    &quot;main_g_artifact_5&quot;
  ],
  &quot;generator&quot;: [
    &quot;1708&quot;,
    &quot;1709&quot;,
    &quot;1710&quot;,
    &quot;1711&quot;
  ],
  &quot;level_max&quot;: 999,
  &quot;level_min&quot;: 1,
  &quot;lucky_chance&quot;: [
    50,
    1
  ],
  &quot;lucky_items&quot;: [
    &quot;1804-84&quot;,
    &quot;1805-13&quot;,
    &quot;1806-3&quot;,
    &quot;main_g_artifact_3-12&quot;,
    &quot;main_g_artifact_4-3&quot;,
    &quot;main_g_artifact_3-1&quot;
  ]
}</pre></details></td></tr></tbody></table></div></div>


### 机会池数据库键（运行时状态，不是配表文件）（29 条）

来源：`LuckyProduceModel DBKey`。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 29 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>母体/棋子 ID<small style="display:block">Type</small></th><th>总机会键</th><th>Lucky配额键</th><th>当前值</th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span></td><td>tl_105</td><td>ll_105</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;105&quot;,
  &quot;总机会键&quot;: &quot;tl_105&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_105&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>tl_106</td><td>ll_106</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;106&quot;,
  &quot;总机会键&quot;: &quot;tl_106&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_106&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span></td><td>tl_107</td><td>ll_107</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;107&quot;,
  &quot;总机会键&quot;: &quot;tl_107&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_107&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span></td><td>tl_108</td><td>ll_108</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;108&quot;,
  &quot;总机会键&quot;: &quot;tl_108&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_108&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span></td><td>tl_109</td><td>ll_109</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;109&quot;,
  &quot;总机会键&quot;: &quot;tl_109&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_109&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span></td><td>tl_110</td><td>ll_110</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;110&quot;,
  &quot;总机会键&quot;: &quot;tl_110&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_110&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>tl_111</td><td>ll_111</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;111&quot;,
  &quot;总机会键&quot;: &quot;tl_111&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_111&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1205.png" alt="1205"><span><b>1205</b><small>豪华泳池包</small></span></span></td><td>tl_1205</td><td>ll_1205</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1205&quot;,
  &quot;总机会键&quot;: &quot;tl_1205&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1205&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1206.png" alt="1206"><span><b>1206</b><small>高级海洋储存箱</small></span></span></td><td>tl_1206</td><td>ll_1206</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1206&quot;,
  &quot;总机会键&quot;: &quot;tl_1206&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1206&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>tl_1207</td><td>ll_1207</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1207&quot;,
  &quot;总机会键&quot;: &quot;tl_1207&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1207&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span></td><td>tl_1208</td><td>ll_1208</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1208&quot;,
  &quot;总机会键&quot;: &quot;tl_1208&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1208&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span></td><td>tl_1209</td><td>ll_1209</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1209&quot;,
  &quot;总机会键&quot;: &quot;tl_1209&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1209&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span></td><td>tl_1210</td><td>ll_1210</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1210&quot;,
  &quot;总机会键&quot;: &quot;tl_1210&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1210&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>tl_1211</td><td>ll_1211</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1211&quot;,
  &quot;总机会键&quot;: &quot;tl_1211&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1211&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1705.png" alt="1705"><span><b>1705</b><small>小珊瑚丛</small></span></span></td><td>tl_1705</td><td>ll_1705</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1705&quot;,
  &quot;总机会键&quot;: &quot;tl_1705&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1705&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span></td><td>tl_1706</td><td>ll_1706</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1706&quot;,
  &quot;总机会键&quot;: &quot;tl_1706&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1706&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>tl_1707</td><td>ll_1707</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1707&quot;,
  &quot;总机会键&quot;: &quot;tl_1707&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1707&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span></td><td>tl_1708</td><td>ll_1708</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1708&quot;,
  &quot;总机会键&quot;: &quot;tl_1708&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1708&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span></td><td>tl_1709</td><td>ll_1709</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1709&quot;,
  &quot;总机会键&quot;: &quot;tl_1709&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1709&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span></td><td>tl_1710</td><td>ll_1710</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1710&quot;,
  &quot;总机会键&quot;: &quot;tl_1710&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1710&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>tl_1711</td><td>ll_1711</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1711&quot;,
  &quot;总机会键&quot;: &quot;tl_1711&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_1711&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span></td><td>tl_405</td><td>ll_405</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;405&quot;,
  &quot;总机会键&quot;: &quot;tl_405&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_405&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>tl_406</td><td>ll_406</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;406&quot;,
  &quot;总机会键&quot;: &quot;tl_406&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_406&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span></td><td>tl_407</td><td>ll_407</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;407&quot;,
  &quot;总机会键&quot;: &quot;tl_407&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_407&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span></td><td>tl_408</td><td>ll_408</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;408&quot;,
  &quot;总机会键&quot;: &quot;tl_408&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_408&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span></td><td>tl_409</td><td>ll_409</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;409&quot;,
  &quot;总机会键&quot;: &quot;tl_409&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_409&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span></td><td>tl_410</td><td>ll_410</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;410&quot;,
  &quot;总机会键&quot;: &quot;tl_410&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_410&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>tl_411</td><td>ll_411</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;411&quot;,
  &quot;总机会键&quot;: &quot;tl_411&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_411&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>tl_805</td><td>ll_805</td><td>运行时状态，非包内配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;805&quot;,
  &quot;总机会键&quot;: &quot;tl_805&quot;,
  &quot;Lucky配额键&quot;: &quot;ll_805&quot;,
  &quot;当前值&quot;: &quot;运行时状态，非包内配置&quot;
}</pre></details></td></tr></tbody></table></div></div>


<!-- generator-configs:end -->

