# 烹饪狂热：选奖、选物与落点：具体算法与配置

GetCurBuffConifgByOrder要求curData与当前doingBuff存在；按buff_id且diff_score_min≤订单难度≤diff_score_max取首条。AcquireRandomRewards先GetCookingFrenzyItemCode。win_all≠1：把CookingFrenzyItem各份Weight合成类别权重，其它奖励原权重，先ListWeightSelectOne；若选棋子类别再次读取棋子缓存，对内部奖励按state给Weight×10000(微笑订单缺口)、×100(普通缺口)、否则原Weight，再抽一项；win_all==1用全部配置。所有抽奖只读候选，不扣全局份额。

GetOptionalChessPieces：复制普通缺口，逐项扣掉当前订单需求，到0删除；逐链记录最大缺口等级，微笑缺口也扣当前需求且仅num>0参与。候选须OrderItem.DiffScore在reward.MinNum..MaxNum含端点、UnlockLevel≤玩家等级且至少一个该链母体已解锁；分组1微笑缺口链1..目标等级、2普通缺口链、3全部合法候选。没有ProgressUnlock等其它随机订单过滤不能自行添加。

GetCookingFrenzyItemCode按order对象缓存；配置棋子奖数量变化或缓存代码不再适用则重建。重建时将奖励槽候选分组复制，按前置非空组和候选数更少的槽优先处理，取该槽第一个非空组，ListRandomSelectOne等权抽；从其它槽各组删除选中code，尽量不重复；全组为空时回退原全候选，state为repeat，所以不是绝对禁止重复。重用缓存仍保留先前state；当前源码排序比较器存在返回true/非严格边界，不能自造稳定优先顺序。

统计固定棋子MaxNum，为(#动态棋子+fixedMaxNum)从(4,9)找可用格。动态棋子每项count1，固定棋子数量ceil(Random(MinNum,MaxNum))逐个生成，货币也这样选数量；两整数Random为含端点整数，ceil通常不变。无格标isCookingFrenzyItem交API；有格填itemPos。结果DeepCopy并m_mapCacheAcquireReward[order]保存。主盘按itemPos分两组，有位逐份GenerateItems，其他AcquireRewardsLogic(Give,FinishOrder,gameMode,Type2)。远端Buff/奖励值尚未取得，不用演示倍率替代。

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

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:TryAcquireCookingFrenzyReward（恢复文本行1398）

- Board.Model.Order.MainOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrder.disassembly.txt)

- CookingFrenzy.Model.CookingFrenzyModel：[恢复源码](../../../../assets/order-evidence/CookingFrenzy.Model.CookingFrenzyModel.lua) · [原始指令](../../../../assets/order-evidence/CookingFrenzy.Model.CookingFrenzyModel.disassembly.txt)。对应：CookingFrenzyModel:GetCurBuffConifgByOrder（恢复文本行207）；CookingFrenzyModel:AcquireRandomRewards（恢复文本行374）；CookingFrenzyModel:GetCookingFrenzyItemCode（恢复文本行479）；CookingFrenzyModel:GetOptionalChessPieces（恢复文本行676）

- Common.Utility.Table：[恢复源码](../../../../assets/order-evidence/Common.Utility.Table.lua) · [原始指令](../../../../assets/order-evidence/Common.Utility.Table.disassembly.txt)

- Common.Utility.MathUtil：[恢复源码](../../../../assets/order-evidence/Common.Utility.MathUtil.lua) · [原始指令](../../../../assets/order-evidence/Common.Utility.MathUtil.disassembly.txt)


---

## 演示案例

下面分别改变前提，让各条分支实际发生；互斥结果属于不同场景。

### 场景1：烹饪奖励优先帮助微笑缺口

**完整输入（演示设定）：** 假设Started且当前Buff有效，订单难度9命中[0,10]档、win_all=0；配置动态棋子槽Weight1、Diff范围[2,5]，另金币Weight1/Min2/Max2。扣本订单后其它微笑单缺203、普通单缺204，玩家10级、链母体均解锁；完整合法候选203/204分别Diff2/5；棋盘仅(4,9)可用。

**按执行顺序代入：** 候选分组：微笑组[203]、普通组[204]、备用[203,204]；等权组内唯一→缓存code203/state微笑；类别权重棋子1/金币1，R1=1选棋子；内部权重1×10000=10000，R2=1选203；落点(4,9)，缓存本次结果。

**玩家看到的结果：** 扣物后额外在棋盘生成一件203，优先帮助剩余微笑订单；本次没有领取那份2金币候选奖励。

### 场景2：全奖模式含棋子与货币

**完整输入（演示设定）：** 同一有效Buff改win_all=1；假设仅固定棋子204 Min=Max=2、金币Min=Max=3；扣物后有两个合法空格(4,9)/(5,9)，Gold108。

**按执行顺序代入：** 固定棋子ceil(Random(2,2))=2，占两格；金币ceil(Random(3,3))=3；Gold108+3=111；结果深拷贝保存。

**玩家看到的结果：** 棋盘多两件204，金币余额111；全奖模式同时得到配置中的两种奖励。
