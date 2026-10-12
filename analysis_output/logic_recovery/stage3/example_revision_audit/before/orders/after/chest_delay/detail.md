# 宝箱顾客通知，再发延迟奖励：具体算法与配置

ChestCustomer.IsChestCustomerOrder(order.Slot)为真DispatchEvent(ChestCustomerOrderFinish)，这里没有payload。随后pairs(mapDelayRewards)，每组AcquireRewardsLogic(Give,FinishOrder,gameMode,Type2)。Chest处理器按ipairs逐条交AcquireChestCustomOrderReward；活动非Started立即结束。标记解析innerType与slot，再取该槽旧订单，无订单记录错误并返回。预算按DiffScore匹配eventOrderScore区间，百分比非nil时diff×percentage/10000，否则固定数；匹配不break，重叠档后者覆盖。Random2槽3预算最多18。按orderPool含类型筛方案，按weight抽一个。普通方案逐轮等权从rewards抽一项，把该项count当预算成本，发该code一件并减预算，直到预算≤0；可重复抽，允许最后超预算，不是发配置count件。成本≤0可能无法终止，源码没有修复。含chestcustomeritem标记则走缺口定向算法。展开后从(1,1)按扩散序找足量格，已有格逐件GenerateItems并记日志，剩余交奖励API入缓存。保存完整展开结果到innerType_slot映射并SaveCacheData，供视图领取显示。不能把标记数量1当必定只给一件，也不能因为delay就断言等待动画才落账。视图会稍后展示同一组，Logic与View分离。

### 缺口定向奖励的完整预算过程

先复制棋盘加仓库的计数（不含缓存），以pairs遍历所有未完成订单，再按各单需求顺序消耗这份共享库存；不够的代码列入该单缺口，累加其DiffScore。缺配置需求略过。订单按缺口难度从小到大排序，同分未另设稳定排序。依次处理：预算已经≤0停止；预算+10≥该单缺口总分，直接发全部缺口并扣总分，允许最多10分的超预算。否则按单内代码DiffScore升序处理，预算够整件就发整件并扣分；不够则降阶补足。

旧降阶算法沿同链从当前等级向下，找到第一件有配置且DiffScore≤21的代码；发ceil(剩余预算/该件DiffScore)份并逐份扣预算，允许末份超预算。优化分支还要求RewardStockCount开关：按CalculateOrderCodeLackNumMap(false,true,false)取得合成等价值缺口，每份低阶物扣2^(等级−1)等价值；只在此目标仍有缺口时发，预算或缺口任一个耗尽就停止。找不到有效≤21分代码直接跳过，不替换成任意物。整件分支同步减少缺口且下限钳至0，降阶分支可减至负数。

完成缺口后若预算仍>0，收集玩家等级可用、任一母体已解锁的5级代码；空集合用205。每轮从集合等权有放回抽一件，扣其DiffScore直到预算≤0。这些步骤使用同一预算，不能将每个订单分别重新赋预算。远端chestOrderScoreConfig与chestOrderRewardConfig决定实际分档、比例、方案权重和成本；当前包没有账号实际活动记录，因此给出算法和字段含义，不编造默认档位。

## 对应本地配表

各后缀为可选变体，不是同时叠加。require受FileReplace精确文件名首匹配替换，失败才回退默认；实际账号选择及远端档位未取得。缺字段记“—”，不能当0。下方保留全记录与全部字段；嵌套Filters/Rewards可横向滚动查看。

**OrderItemConfig字段含义：** Code是精确需求代码；Price/RecommendedPrice用于普通/基准单价格；DiffScore为难度累计与活动输入；UnlockLevel含端点门槛；ProgressUnlock=1要求前一级已解锁；ForbiddenSlot排槽；Weight为原始份额；WeightMultiple参与库存链倍率；RepeatWeightDecrease为除数；DifficultyLevel覆盖链等级筛选；RecommendedNumber控制基准单重复数。

<details><summary>OrderItemConfig：74条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>1170</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>2000</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>2500</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>1229</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>2000</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2500</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>25</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>18</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>318</td><td>1</td><td>1</td><td>318</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>12</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>22</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>34</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>54</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>86</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>7</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>27</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>58</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>91</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>183</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>366</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>36</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>731</td><td>—</td><td>[10, 11]</td><td>304</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1463</td><td>—</td><td>[10, 11]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>41</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig.json">完整原记录</a></p></details>

<details><summary>OrderItemConfig_extracust：76条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>878</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>1317</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>1976</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>926</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>1389</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2084</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>911</td><td>1436</td><td>12</td><td>[10, 11]</td><td>309</td><td>1</td><td>1</td><td>309</td><td>100</td><td>51</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>25</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>18</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>318</td><td>1</td><td>—</td><td>—</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1312</td><td>1056</td><td>—</td><td>[10, 11]</td><td>501</td><td>1</td><td>1</td><td>501</td><td>100</td><td>51</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>12</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>22</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>34</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>54</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>86</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>7</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>27</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>58</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>91</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>183</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>366</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>36</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>731</td><td>—</td><td>[10, 11]</td><td>304</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1097</td><td>—</td><td>[10, 11]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>41</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig_extracust.json">完整原记录</a></p></details>

<details><summary>OrderItemConfig_hard：74条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>1170</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>2000</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>2500</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>16</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>1229</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>2000</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2500</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>16</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>100</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>318</td><td>1</td><td>1</td><td>318</td><td>100</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>12</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>22</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>34</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>54</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>86</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>7</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>27</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>58</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>91</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>183</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>366</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>731</td><td>—</td><td>[10, 11]</td><td>304</td><td>1</td><td>—</td><td>—</td><td>100</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1463</td><td>—</td><td>[10, 11]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>10</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig_hard.json">完整原记录</a></p></details>

<details><summary>OrderItemConfig_nerf：74条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>1170</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>2000</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>2500</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>1229</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>2000</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2500</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>25</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>7</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>20</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>30</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>47</td><td>1</td><td>—</td><td>—</td><td>—</td><td>18</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>73</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>110</td><td>1</td><td>—</td><td>—</td><td>10</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>168</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>265</td><td>1</td><td>1</td><td>318</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>10</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>18</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>28</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>45</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>72</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>7</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>7</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>13</td><td>—</td><td>[10]</td><td>20</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>27</td><td>—</td><td>[10, 11]</td><td>30</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>58</td><td>—</td><td>[10, 11]</td><td>47</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>91</td><td>—</td><td>[10, 11]</td><td>73</td><td>1</td><td>—</td><td>—</td><td>—</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>183</td><td>—</td><td>[10, 11]</td><td>110</td><td>1</td><td>—</td><td>—</td><td>10</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>366</td><td>—</td><td>[10, 11]</td><td>168</td><td>1</td><td>—</td><td>—</td><td>50</td><td>36</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>731</td><td>—</td><td>[10, 11]</td><td>253</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1463</td><td>—</td><td>[10, 11]</td><td>382</td><td>1</td><td>1</td><td>458</td><td>—</td><td>41</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig_nerf.json">完整原记录</a></p></details>

<details><summary>OrderItemConfig_nerf_more：74条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>1170</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>2000</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>2500</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>1229</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>2000</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2500</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>25</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>6</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>10</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>17</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>26</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>40</td><td>1</td><td>—</td><td>—</td><td>—</td><td>18</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>63</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>94</td><td>1</td><td>—</td><td>—</td><td>10</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>144</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>227</td><td>1</td><td>1</td><td>318</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>9</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>16</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>39</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>61</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>6</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>7</td><td>—</td><td>—</td><td>10</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>13</td><td>—</td><td>[10]</td><td>17</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>27</td><td>—</td><td>[10, 11]</td><td>26</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>58</td><td>—</td><td>[10, 11]</td><td>40</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>91</td><td>—</td><td>[10, 11]</td><td>63</td><td>1</td><td>—</td><td>—</td><td>—</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>183</td><td>—</td><td>[10, 11]</td><td>94</td><td>1</td><td>—</td><td>—</td><td>10</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>366</td><td>—</td><td>[10, 11]</td><td>144</td><td>1</td><td>—</td><td>—</td><td>50</td><td>36</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>731</td><td>—</td><td>[10, 11]</td><td>217</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1463</td><td>—</td><td>[10, 11]</td><td>327</td><td>1</td><td>1</td><td>458</td><td>—</td><td>41</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig_nerf_more.json">完整原记录</a></p></details>

<details><summary>OrderItemConfig_shell：80条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>1170</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>2000</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>2500</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>1229</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>2000</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2500</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>25</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>18</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>318</td><td>1</td><td>1</td><td>318</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>12</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>22</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>34</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>54</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>86</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>7</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>6</td><td>—</td><td>—</td><td>13</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>11</td><td>—</td><td>[10]</td><td>21</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>22</td><td>—</td><td>[10, 11]</td><td>32</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>43</td><td>—</td><td>[10, 11]</td><td>50</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>86</td><td>—</td><td>[10, 11]</td><td>79</td><td>1</td><td>—</td><td>—</td><td>—</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>171</td><td>—</td><td>[10, 11]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>10</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>341</td><td>—</td><td>[10, 11]</td><td>180</td><td>1</td><td>—</td><td>—</td><td>50</td><td>36</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>682</td><td>—</td><td>[10, 11]</td><td>271</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1364</td><td>—</td><td>[10, 11]</td><td>409</td><td>1</td><td>1</td><td>409</td><td>—</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>main_g_artifact_3</td><td>11</td><td>4</td><td>—</td><td>13</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>main_g_artifact_4</td><td>22</td><td>5</td><td>—</td><td>21</td><td>—</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>—</td></tr>
<tr><td>main_g_artifact_5</td><td>43</td><td>6</td><td>—</td><td>32</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>main_g_artifact_6</td><td>86</td><td>7</td><td>[10, 11]</td><td>50</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>main_g_artifact_7</td><td>171</td><td>8</td><td>[10, 11]</td><td>79</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>main_g_artifact_8</td><td>341</td><td>9</td><td>[10, 11]</td><td>118</td><td>1</td><td>2</td><td>118</td><td>100</td><td>51</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig_shell.json">完整原记录</a></p></details>

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:FinishOrder（恢复文本行1101）

- Model.RewardHandler.RewardCategoryHandler.ChestCustomOrderRewardCategoryHandler：[恢复源码](../../../../assets/order-evidence/Model.RewardHandler.RewardCategoryHandler.ChestCustomOrderRewardCategoryHandler.lua) · [原始指令](../../../../assets/order-evidence/Model.RewardHandler.RewardCategoryHandler.ChestCustomOrderRewardCategoryHandler.disassembly.txt)。对应：ChestCustomOrderRewardCategoryHandler:LogicHandle（恢复文本行9）

- ChestCustomer.Model.ChestCustomerModel：[恢复源码](../../../../assets/order-evidence/ChestCustomer.Model.ChestCustomerModel.lua) · [原始指令](../../../../assets/order-evidence/ChestCustomer.Model.ChestCustomerModel.disassembly.txt)。对应：ChestCustomerModel:FindNormalRewardConfig（恢复文本行186）；ChestCustomerModel:AcquireChestCustomOrderReward（恢复文本行205）

- Board.Model.RandomGenerateCodeHelper：[恢复源码](../../../../assets/order-evidence/Board.Model.RandomGenerateCodeHelper.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.RandomGenerateCodeHelper.disassembly.txt)。对应：RandomGenerateCodeHelper.GenerateChestCustomCodeRule（恢复文本行4）


---

## 贯穿案例：203×2与204×1，使用仓库补交

槽1不属于宝箱顾客，延迟为空，所以不派宝箱通知也不发这组奖励。

### 代入本页的值

IsChestCustomerOrder=false，pairs({})0次。

对照普通方案预算5、仅一个候选成本3：等权选两次，具体发两件，每件count1，总成本6、预算−1。对照缺口总分14、预算4：4+10≥14，整组交付后预算−10；这是阈值边界的演示，不是远端配置。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
