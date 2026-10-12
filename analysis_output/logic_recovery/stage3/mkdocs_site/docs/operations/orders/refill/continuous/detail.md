# 连续订单：具体算法与配置

CanCreateOrder仅槽18，状态Started或Ended；Ended还要求GetStarted真，index在0..TotalOrderCount闭区间，GetStarted真，主活动窗未打开且m_canCreateOrderFlag不恰为false。不要擅自将index0排除；Create随后直接取m_ordersConfig[index]，有效配置是调用前提。每项GetAvailableItems传alreadyRequiredItems，主池和备用池分别FilterByLevel；主非空用主，否则备用非空用备用，两者空返回nil。每次衰减重复链权重、加权抽Code、加入已需集合、标选中链。第一项后，只有前一项成功且配置有下一项才抽第二/第三；第一项空兜底ItemType.Flour09=209并记错误。最后UpdateMapInfo保存衰减历史，MainOrder.Create槽18、Id=curIndex、内部20、avatar2001、Luckyfalse。

远端m_ordersConfig.item1/2/3.range_entry为含端点等级区间；没有ItemAmounts项数轮盘。这里没有普通动态上限修正。候选备用可以用于每项，不仅第一项；前项失败后跳过后续，即使第一项随后兜底209也不会补抽第二项。

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

- Contiorders.Model.ContiordersModel：[恢复源码](../../../../assets/order-evidence/Contiorders.Model.ContiordersModel.lua) · [原始指令](../../../../assets/order-evidence/Contiorders.Model.ContiordersModel.disassembly.txt)。对应：ContiordersModel:CanCreateOrder（恢复文本行29）；ContiordersModel:CreateOrder（恢复文本行54）

- Board.Model.Order.MainOrderCreatorRandom：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreatorRandom.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreatorRandom.disassembly.txt)。对应：RandomOrderHelper.GetAvailableItems（恢复文本行512）；RandomOrderHelper.FilterByLevel（恢复文本行898）

- Board.Model.Item.ItemDefinition：[恢复源码](../../../../assets/order-evidence/Board.Model.Item.ItemDefinition.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Item.ItemDefinition.disassembly.txt)


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：三项连续订单

**完整输入（演示设定）：** 槽18空，假设活动Started、GetStarted=true、index1/Total3、主窗关闭、flag=true；本轮三项range分别[3,3]、[3,3]、[3,3]；玩家10，母体已解锁，逐轮主池分别仅203/503/903，权重100，无重复链减权。

**按执行顺序代入：** 每项唯一候选，R1=R2=R3=1→203/503/903；alreadyRequired逐次追加；UpdateMapInfo；创建槽18、Id1、innerType20、avatar2001、Luckyfalse。

**玩家看到的结果：** 连续顾客要求203、503、903三件；三项来自活动档位，没有普通随机订单的一二三项轮盘。
