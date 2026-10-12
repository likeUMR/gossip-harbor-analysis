# 临时物未生成，再尝试卡片：具体算法与配置

TryGenerateItem先CanGenerateCardItem：Started，CheckFinish，再CheckCanMergeMaxCardItem为false。读m_mapCardItemProduceConfig[source itemType]，按ipairs选第一条LevelMin≤玩家等级且LevelMax缺省或等级≤Max的记录；两端包含。

然后遍历m_mapCardItemTypeConfig，任一level≥UnlockLevel就isLevelLock=false；源码这里`if not isLevelLock then return nil`。但这个条件是否执行取决于下方解释的映射结构，不能只看变量名推断真实账号会被等级门槛拒绝。原字节码受控验证数组与字符串映射两条路径。

math.random(10000)得到1..10000，R≤Chance或测试TestForceCreateCard=1时GenerateCardItem。测试强制只绕过此随机，不能绕过前面的资格/等级返回。当前chain非nil且isFinish=false，返回同链一级；否则TryGenerateNewChain，保存chain与isFinish=false，再返回一级。换链、库存最高级整数倍暂停和stack模式由卡片模型内部处理。

落子用SpreadItem，spreadType=CardItem、logSpread=false；mergeInfo.CardType、hasCreateItem=true，再全局CardItemGenerate消息取实际位置对象。相关5份完整本地卡片配置随本页展示；账号后缀由全局require FileReplace精确匹配选择，实际分组未取得。

## 本分支的落点与写入顺序

FindEmptyPositionInSpreadOrder从New.Position开始，maxTiles=max(7,9)=9；r=1..8。每轮当前位置先(−1,−1)，然后按dir右/上/左/下，每边走2r步，每步之后检查合法且GetItem=nil就return。无位return openedPosition（本链未传即nil）。中心不扫描，角落越界跳过但步进继续。

例如中心(4,3)，r1依次(4,2),(5,2),(5,3),(5,4),(4,4),(3,4),(3,3),(3,2)。若唯一空位为源S=(3,3)，落在r1第7项；不是总优先源格。

SpreadItem内GenerateItem→SaveItemProperty→_SetItem（默认刷新订单）→局部SpreadItem→主盘全局ItemSpread→日志/满盘检查。本操作传logSpread=false禁产出日志，但不禁上述通知。消息CostEnergy缺省值与BoardSpreadType由SpreadItem实现填充，活动应读取实际消息，不把合成来源冒充母体消耗能量。

EnergyBubble分支缺外层满盘检查是前述例外；GenerateItem(nil,code)仍保存对象但不写格，不能当落子已成功。顺序写入不是统一事务。

## 等级循环与真实配置结构的区别

LoadCardItemConfig把记录按ItemChain作为键建m_mapCardItemTypeConfig；本地ItemChain是字符串，如main_card_item_energy_b。上述备用入口却用ipairs遍历这张映射；对只有字符串键的正常映射，循环不访问任何记录，isLevelLock保留true，不会因已解锁链而提前返回。只有存在从1开始连续数字键的不同结构才执行那个等级拒绝分支。原始字节码与恢复源码的两种结构均做受控验证；复刻当前行为不能擅自把ipairs改成pairs。

CheckCanMergeMaxCardItem统计棋盘、缓存和仓库里当前卡片链的裸普通代码，按2^(等级−1)转一级等价；总量非零且能被最高级所需2^(maxLevel−1)整除才暂停，不是总量≥需求。stack开关为1时CheckFinish先把旧链标finished并保存，随后暂停检查可能返回false，允许新链生成。

TryGenerateNewChain遍历已解锁链，先排除旧链；没有其它可选链才退回旧链，按Weight选择。未取得可选链时加权工具的异常边界须保留，不自造奖励。ItemMerged监听在新物为最高级卡片、活动Started且该链未记录已展示时保存提示标志并派CardItemFirstPopWindow；这属于基础合成通知时的同步响应，不是本次备用卡片随机的再次判定。


## 对应本地配表

| 字段 | 在本步骤中的含义 |
| --- | --- |
| ItemChain / UnlockLevel / Weight / Rarity | 卡片链、选链等级门槛、选链权重、表现稀有度 |
| ItemType / LevelMin / LevelMax / Chance | 被合成输入类型、玩家等级含端点区间、万分整数阈值；Max缺省无上限 |

同一文件后缀是可选变体，不代表本次账号全部同时生效。全局require按FileReplace的首个精确file匹配追加后缀，替换装载失败才回退默认；账号实际后缀尚未取得。下表列出此步骤所用字段，下载保留完整原记录。字段缺省以“—”表示，不能当作数值0。

<details><summary>CardItemConfig：26条相关记录（原表26条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>ItemChain</th><th>Rarity</th><th>UnlockLevel</th><th>Weight</th></tr></thead><tbody>
<tr><td>main_card_item_energy_b</td><td>4</td><td>25</td><td>600</td></tr>
<tr><td>main_card_item_energy_m</td><td>3</td><td>25</td><td>1667</td></tr>
<tr><td>main_card_item_energy_s</td><td>1</td><td>25</td><td>3752</td></tr>
<tr><td>main_card_item_gem_b</td><td>4</td><td>25</td><td>600</td></tr>
<tr><td>main_card_item_gem_m</td><td>3</td><td>25</td><td>1667</td></tr>
<tr><td>main_card_item_gem_s</td><td>1</td><td>25</td><td>6669</td></tr>
<tr><td>main_card_item_levelup</td><td>4</td><td>25</td><td>234</td></tr>
<tr><td>main_card_item_plane_b</td><td>3</td><td>25</td><td>938</td></tr>
<tr><td>main_card_item_plane_m</td><td>2</td><td>25</td><td>1667</td></tr>
<tr><td>main_card_item_plane_s</td><td>1</td><td>25</td><td>3752</td></tr>
<tr><td>main_card_item_pot_b</td><td>4</td><td>25</td><td>234</td></tr>
<tr><td>main_card_item_pot_m</td><td>3</td><td>25</td><td>600</td></tr>
<tr><td>main_card_item_pot_s</td><td>2</td><td>25</td><td>1667</td></tr>
<tr><td>main_card_item_superball</td><td>4</td><td>30</td><td>234</td></tr>
<tr><td>main_card_item_raccoon_b</td><td>3</td><td>35</td><td>938</td></tr>
<tr><td>main_card_item_raccoon_m</td><td>2</td><td>35</td><td>1667</td></tr>
<tr><td>main_card_item_raccoon_s</td><td>1</td><td>35</td><td>3752</td></tr>
<tr><td>main_card_item_smart_buff</td><td>3</td><td>45</td><td>938</td></tr>
<tr><td>main_card_item_raccoon_customer</td><td>4</td><td>50</td><td>417</td></tr>
<tr><td>main_card_item_cannon_b</td><td>3</td><td>55</td><td>417</td></tr>
<tr><td>main_card_item_cannon_s</td><td>2</td><td>55</td><td>938</td></tr>
<tr><td>main_card_item_disco_b</td><td>3</td><td>60</td><td>938</td></tr>
<tr><td>main_card_item_disco_m</td><td>2</td><td>60</td><td>1667</td></tr>
<tr><td>main_card_item_disco_s</td><td>1</td><td>60</td><td>3752</td></tr>
<tr><td>main_card_item_infi_e_s</td><td>3</td><td>70</td><td>234</td></tr>
<tr><td>main_card_item_infi_e_b</td><td>4</td><td>80</td><td>59</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/CardItemConfig.json">完整原记录</a></p>
</details>

<details><summary>CardItemConfig_more：26条相关记录（原表26条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>ItemChain</th><th>Rarity</th><th>UnlockLevel</th><th>Weight</th></tr></thead><tbody>
<tr><td>main_card_item_energy_b</td><td>4</td><td>25</td><td>515</td></tr>
<tr><td>main_card_item_energy_m</td><td>3</td><td>25</td><td>1431</td></tr>
<tr><td>main_card_item_energy_s</td><td>1</td><td>25</td><td>3221</td></tr>
<tr><td>main_card_item_gem_b</td><td>4</td><td>25</td><td>515</td></tr>
<tr><td>main_card_item_gem_m</td><td>3</td><td>25</td><td>2061</td></tr>
<tr><td>main_card_item_gem_s</td><td>1</td><td>25</td><td>12882</td></tr>
<tr><td>main_card_item_levelup</td><td>4</td><td>25</td><td>201</td></tr>
<tr><td>main_card_item_plane_b</td><td>3</td><td>25</td><td>1431</td></tr>
<tr><td>main_card_item_plane_m</td><td>2</td><td>25</td><td>2061</td></tr>
<tr><td>main_card_item_plane_s</td><td>1</td><td>25</td><td>5725</td></tr>
<tr><td>main_card_item_pot_b</td><td>4</td><td>25</td><td>201</td></tr>
<tr><td>main_card_item_pot_m</td><td>3</td><td>25</td><td>515</td></tr>
<tr><td>main_card_item_pot_s</td><td>2</td><td>25</td><td>1431</td></tr>
<tr><td>main_card_item_superball</td><td>4</td><td>30</td><td>201</td></tr>
<tr><td>main_card_item_raccoon_b</td><td>3</td><td>35</td><td>1431</td></tr>
<tr><td>main_card_item_raccoon_m</td><td>2</td><td>35</td><td>2061</td></tr>
<tr><td>main_card_item_raccoon_s</td><td>1</td><td>35</td><td>5725</td></tr>
<tr><td>main_card_item_smart_buff</td><td>3</td><td>45</td><td>805</td></tr>
<tr><td>main_card_item_raccoon_customer</td><td>4</td><td>50</td><td>358</td></tr>
<tr><td>main_card_item_cannon_b</td><td>3</td><td>55</td><td>515</td></tr>
<tr><td>main_card_item_cannon_s</td><td>2</td><td>55</td><td>1431</td></tr>
<tr><td>main_card_item_disco_b</td><td>3</td><td>60</td><td>1431</td></tr>
<tr><td>main_card_item_disco_m</td><td>2</td><td>60</td><td>2061</td></tr>
<tr><td>main_card_item_disco_s</td><td>1</td><td>60</td><td>5725</td></tr>
<tr><td>main_card_item_infi_e_s</td><td>3</td><td>70</td><td>201</td></tr>
<tr><td>main_card_item_infi_e_b</td><td>4</td><td>80</td><td>50</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/CardItemConfig_more.json">完整原记录</a></p>
</details>

<details><summary>CardItemProduceConfig：177条相关记录（原表177条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Chance</th><th>ItemType</th><th>LevelMax</th><th>LevelMin</th></tr></thead><tbody>
<tr><td>35</td><td>203</td><td>60</td><td>1</td></tr>
<tr><td>70</td><td>204</td><td>60</td><td>1</td></tr>
<tr><td>105</td><td>205</td><td>60</td><td>1</td></tr>
<tr><td>140</td><td>206</td><td>60</td><td>1</td></tr>
<tr><td>175</td><td>207</td><td>60</td><td>1</td></tr>
<tr><td>210</td><td>208</td><td>60</td><td>1</td></tr>
<tr><td>245</td><td>209</td><td>60</td><td>1</td></tr>
<tr><td>280</td><td>210</td><td>60</td><td>1</td></tr>
<tr><td>315</td><td>211</td><td>60</td><td>1</td></tr>
<tr><td>350</td><td>212</td><td>60</td><td>1</td></tr>
<tr><td>385</td><td>213</td><td>60</td><td>1</td></tr>
<tr><td>420</td><td>214</td><td>60</td><td>1</td></tr>
<tr><td>35</td><td>303</td><td>60</td><td>1</td></tr>
<tr><td>70</td><td>304</td><td>60</td><td>1</td></tr>
<tr><td>105</td><td>305</td><td>60</td><td>1</td></tr>
<tr><td>140</td><td>306</td><td>60</td><td>1</td></tr>
<tr><td>35</td><td>503</td><td>60</td><td>1</td></tr>
<tr><td>70</td><td>504</td><td>60</td><td>1</td></tr>
<tr><td>105</td><td>505</td><td>60</td><td>1</td></tr>
<tr><td>140</td><td>506</td><td>60</td><td>1</td></tr>
<tr><td>175</td><td>507</td><td>60</td><td>1</td></tr>
<tr><td>210</td><td>508</td><td>60</td><td>1</td></tr>
<tr><td>245</td><td>509</td><td>60</td><td>1</td></tr>
<tr><td>280</td><td>510</td><td>60</td><td>1</td></tr>
<tr><td>315</td><td>511</td><td>60</td><td>1</td></tr>
<tr><td>350</td><td>512</td><td>60</td><td>1</td></tr>
<tr><td>385</td><td>513</td><td>60</td><td>1</td></tr>
<tr><td>35</td><td>603</td><td>60</td><td>1</td></tr>
<tr><td>70</td><td>604</td><td>60</td><td>1</td></tr>
<tr><td>105</td><td>605</td><td>60</td><td>1</td></tr>
<tr><td>140</td><td>606</td><td>60</td><td>1</td></tr>
<tr><td>35</td><td>903</td><td>60</td><td>1</td></tr>
<tr><td>70</td><td>904</td><td>60</td><td>1</td></tr>
<tr><td>105</td><td>905</td><td>60</td><td>1</td></tr>
<tr><td>140</td><td>906</td><td>60</td><td>1</td></tr>
<tr><td>175</td><td>907</td><td>60</td><td>1</td></tr>
<tr><td>210</td><td>908</td><td>60</td><td>1</td></tr>
<tr><td>245</td><td>909</td><td>60</td><td>1</td></tr>
<tr><td>35</td><td>1303</td><td>60</td><td>1</td></tr>
<tr><td>70</td><td>1304</td><td>60</td><td>1</td></tr>
<tr><td>105</td><td>1305</td><td>60</td><td>1</td></tr>
<tr><td>140</td><td>1306</td><td>60</td><td>1</td></tr>
<tr><td>175</td><td>1307</td><td>60</td><td>1</td></tr>
<tr><td>210</td><td>1308</td><td>60</td><td>1</td></tr>
<tr><td>245</td><td>1309</td><td>60</td><td>1</td></tr>
<tr><td>280</td><td>1310</td><td>60</td><td>1</td></tr>
<tr><td>35</td><td>1403</td><td>60</td><td>1</td></tr>
<tr><td>70</td><td>1404</td><td>60</td><td>1</td></tr>
<tr><td>105</td><td>1405</td><td>60</td><td>1</td></tr>
<tr><td>140</td><td>1406</td><td>60</td><td>1</td></tr>
<tr><td>35</td><td>1803</td><td>60</td><td>1</td></tr>
<tr><td>70</td><td>1804</td><td>60</td><td>1</td></tr>
<tr><td>105</td><td>1805</td><td>60</td><td>1</td></tr>
<tr><td>140</td><td>1806</td><td>60</td><td>1</td></tr>
<tr><td>175</td><td>1807</td><td>60</td><td>1</td></tr>
<tr><td>210</td><td>1808</td><td>60</td><td>1</td></tr>
<tr><td>245</td><td>1809</td><td>60</td><td>1</td></tr>
<tr><td>280</td><td>1810</td><td>60</td><td>1</td></tr>
<tr><td>315</td><td>1811</td><td>60</td><td>1</td></tr>
<tr><td>28</td><td>203</td><td>120</td><td>61</td></tr>
<tr><td>56</td><td>204</td><td>120</td><td>61</td></tr>
<tr><td>84</td><td>205</td><td>120</td><td>61</td></tr>
<tr><td>112</td><td>206</td><td>120</td><td>61</td></tr>
<tr><td>140</td><td>207</td><td>120</td><td>61</td></tr>
<tr><td>168</td><td>208</td><td>120</td><td>61</td></tr>
<tr><td>196</td><td>209</td><td>120</td><td>61</td></tr>
<tr><td>224</td><td>210</td><td>120</td><td>61</td></tr>
<tr><td>252</td><td>211</td><td>120</td><td>61</td></tr>
<tr><td>280</td><td>212</td><td>120</td><td>61</td></tr>
<tr><td>308</td><td>213</td><td>120</td><td>61</td></tr>
<tr><td>336</td><td>214</td><td>120</td><td>61</td></tr>
<tr><td>28</td><td>303</td><td>120</td><td>61</td></tr>
<tr><td>56</td><td>304</td><td>120</td><td>61</td></tr>
<tr><td>84</td><td>305</td><td>120</td><td>61</td></tr>
<tr><td>112</td><td>306</td><td>120</td><td>61</td></tr>
<tr><td>28</td><td>503</td><td>120</td><td>61</td></tr>
<tr><td>56</td><td>504</td><td>120</td><td>61</td></tr>
<tr><td>84</td><td>505</td><td>120</td><td>61</td></tr>
<tr><td>112</td><td>506</td><td>120</td><td>61</td></tr>
<tr><td>140</td><td>507</td><td>120</td><td>61</td></tr>
<tr><td>168</td><td>508</td><td>120</td><td>61</td></tr>
<tr><td>196</td><td>509</td><td>120</td><td>61</td></tr>
<tr><td>224</td><td>510</td><td>120</td><td>61</td></tr>
<tr><td>252</td><td>511</td><td>120</td><td>61</td></tr>
<tr><td>280</td><td>512</td><td>120</td><td>61</td></tr>
<tr><td>308</td><td>513</td><td>120</td><td>61</td></tr>
<tr><td>28</td><td>603</td><td>120</td><td>61</td></tr>
<tr><td>56</td><td>604</td><td>120</td><td>61</td></tr>
<tr><td>84</td><td>605</td><td>120</td><td>61</td></tr>
<tr><td>112</td><td>606</td><td>120</td><td>61</td></tr>
<tr><td>28</td><td>903</td><td>120</td><td>61</td></tr>
<tr><td>56</td><td>904</td><td>120</td><td>61</td></tr>
<tr><td>84</td><td>905</td><td>120</td><td>61</td></tr>
<tr><td>112</td><td>906</td><td>120</td><td>61</td></tr>
<tr><td>140</td><td>907</td><td>120</td><td>61</td></tr>
<tr><td>168</td><td>908</td><td>120</td><td>61</td></tr>
<tr><td>196</td><td>909</td><td>120</td><td>61</td></tr>
<tr><td>28</td><td>1303</td><td>120</td><td>61</td></tr>
<tr><td>56</td><td>1304</td><td>120</td><td>61</td></tr>
<tr><td>84</td><td>1305</td><td>120</td><td>61</td></tr>
<tr><td>112</td><td>1306</td><td>120</td><td>61</td></tr>
<tr><td>140</td><td>1307</td><td>120</td><td>61</td></tr>
<tr><td>168</td><td>1308</td><td>120</td><td>61</td></tr>
<tr><td>196</td><td>1309</td><td>120</td><td>61</td></tr>
<tr><td>224</td><td>1310</td><td>120</td><td>61</td></tr>
<tr><td>28</td><td>1403</td><td>120</td><td>61</td></tr>
<tr><td>56</td><td>1404</td><td>120</td><td>61</td></tr>
<tr><td>84</td><td>1405</td><td>120</td><td>61</td></tr>
<tr><td>112</td><td>1406</td><td>120</td><td>61</td></tr>
<tr><td>28</td><td>1803</td><td>120</td><td>61</td></tr>
<tr><td>56</td><td>1804</td><td>120</td><td>61</td></tr>
<tr><td>84</td><td>1805</td><td>120</td><td>61</td></tr>
<tr><td>112</td><td>1806</td><td>120</td><td>61</td></tr>
<tr><td>140</td><td>1807</td><td>120</td><td>61</td></tr>
<tr><td>168</td><td>1808</td><td>120</td><td>61</td></tr>
<tr><td>196</td><td>1809</td><td>120</td><td>61</td></tr>
<tr><td>224</td><td>1810</td><td>120</td><td>61</td></tr>
<tr><td>252</td><td>1811</td><td>120</td><td>61</td></tr>
<tr><td>19</td><td>203</td><td>999</td><td>121</td></tr>
<tr><td>38</td><td>204</td><td>999</td><td>121</td></tr>
<tr><td>57</td><td>205</td><td>999</td><td>121</td></tr>
<tr><td>76</td><td>206</td><td>999</td><td>121</td></tr>
<tr><td>95</td><td>207</td><td>999</td><td>121</td></tr>
<tr><td>114</td><td>208</td><td>999</td><td>121</td></tr>
<tr><td>133</td><td>209</td><td>999</td><td>121</td></tr>
<tr><td>152</td><td>210</td><td>999</td><td>121</td></tr>
<tr><td>171</td><td>211</td><td>999</td><td>121</td></tr>
<tr><td>190</td><td>212</td><td>999</td><td>121</td></tr>
<tr><td>208</td><td>213</td><td>999</td><td>121</td></tr>
<tr><td>228</td><td>214</td><td>999</td><td>121</td></tr>
<tr><td>19</td><td>303</td><td>999</td><td>121</td></tr>
<tr><td>38</td><td>304</td><td>999</td><td>121</td></tr>
<tr><td>57</td><td>305</td><td>999</td><td>121</td></tr>
<tr><td>76</td><td>306</td><td>999</td><td>121</td></tr>
<tr><td>19</td><td>503</td><td>999</td><td>121</td></tr>
<tr><td>38</td><td>504</td><td>999</td><td>121</td></tr>
<tr><td>57</td><td>505</td><td>999</td><td>121</td></tr>
<tr><td>76</td><td>506</td><td>999</td><td>121</td></tr>
<tr><td>95</td><td>507</td><td>999</td><td>121</td></tr>
<tr><td>114</td><td>508</td><td>999</td><td>121</td></tr>
<tr><td>133</td><td>509</td><td>999</td><td>121</td></tr>
<tr><td>152</td><td>510</td><td>999</td><td>121</td></tr>
<tr><td>171</td><td>511</td><td>999</td><td>121</td></tr>
<tr><td>190</td><td>512</td><td>999</td><td>121</td></tr>
<tr><td>208</td><td>513</td><td>999</td><td>121</td></tr>
<tr><td>19</td><td>603</td><td>999</td><td>121</td></tr>
<tr><td>38</td><td>604</td><td>999</td><td>121</td></tr>
<tr><td>57</td><td>605</td><td>999</td><td>121</td></tr>
<tr><td>76</td><td>606</td><td>999</td><td>121</td></tr>
<tr><td>19</td><td>903</td><td>999</td><td>121</td></tr>
<tr><td>38</td><td>904</td><td>999</td><td>121</td></tr>
<tr><td>57</td><td>905</td><td>999</td><td>121</td></tr>
<tr><td>76</td><td>906</td><td>999</td><td>121</td></tr>
<tr><td>95</td><td>907</td><td>999</td><td>121</td></tr>
<tr><td>114</td><td>908</td><td>999</td><td>121</td></tr>
<tr><td>133</td><td>909</td><td>999</td><td>121</td></tr>
<tr><td>19</td><td>1303</td><td>999</td><td>121</td></tr>
<tr><td>38</td><td>1304</td><td>999</td><td>121</td></tr>
<tr><td>57</td><td>1305</td><td>999</td><td>121</td></tr>
<tr><td>76</td><td>1306</td><td>999</td><td>121</td></tr>
<tr><td>95</td><td>1307</td><td>999</td><td>121</td></tr>
<tr><td>114</td><td>1308</td><td>999</td><td>121</td></tr>
<tr><td>133</td><td>1309</td><td>999</td><td>121</td></tr>
<tr><td>152</td><td>1310</td><td>999</td><td>121</td></tr>
<tr><td>19</td><td>1403</td><td>999</td><td>121</td></tr>
<tr><td>38</td><td>1404</td><td>999</td><td>121</td></tr>
<tr><td>57</td><td>1405</td><td>999</td><td>121</td></tr>
<tr><td>76</td><td>1406</td><td>999</td><td>121</td></tr>
<tr><td>19</td><td>1803</td><td>999</td><td>121</td></tr>
<tr><td>38</td><td>1804</td><td>999</td><td>121</td></tr>
<tr><td>57</td><td>1805</td><td>999</td><td>121</td></tr>
<tr><td>76</td><td>1806</td><td>999</td><td>121</td></tr>
<tr><td>95</td><td>1807</td><td>999</td><td>121</td></tr>
<tr><td>114</td><td>1808</td><td>999</td><td>121</td></tr>
<tr><td>133</td><td>1809</td><td>999</td><td>121</td></tr>
<tr><td>152</td><td>1810</td><td>999</td><td>121</td></tr>
<tr><td>171</td><td>1811</td><td>999</td><td>121</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/CardItemProduceConfig.json">完整原记录</a></p>
</details>

<details><summary>CardItemProduceConfig_more：177条相关记录（原表177条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Chance</th><th>ItemType</th><th>LevelMax</th><th>LevelMin</th></tr></thead><tbody>
<tr><td>65</td><td>203</td><td>60</td><td>1</td></tr>
<tr><td>130</td><td>204</td><td>60</td><td>1</td></tr>
<tr><td>195</td><td>205</td><td>60</td><td>1</td></tr>
<tr><td>260</td><td>206</td><td>60</td><td>1</td></tr>
<tr><td>325</td><td>207</td><td>60</td><td>1</td></tr>
<tr><td>390</td><td>208</td><td>60</td><td>1</td></tr>
<tr><td>455</td><td>209</td><td>60</td><td>1</td></tr>
<tr><td>520</td><td>210</td><td>60</td><td>1</td></tr>
<tr><td>585</td><td>211</td><td>60</td><td>1</td></tr>
<tr><td>650</td><td>212</td><td>60</td><td>1</td></tr>
<tr><td>714</td><td>213</td><td>60</td><td>1</td></tr>
<tr><td>780</td><td>214</td><td>60</td><td>1</td></tr>
<tr><td>65</td><td>303</td><td>60</td><td>1</td></tr>
<tr><td>130</td><td>304</td><td>60</td><td>1</td></tr>
<tr><td>195</td><td>305</td><td>60</td><td>1</td></tr>
<tr><td>260</td><td>306</td><td>60</td><td>1</td></tr>
<tr><td>65</td><td>503</td><td>60</td><td>1</td></tr>
<tr><td>130</td><td>504</td><td>60</td><td>1</td></tr>
<tr><td>195</td><td>505</td><td>60</td><td>1</td></tr>
<tr><td>260</td><td>506</td><td>60</td><td>1</td></tr>
<tr><td>325</td><td>507</td><td>60</td><td>1</td></tr>
<tr><td>390</td><td>508</td><td>60</td><td>1</td></tr>
<tr><td>455</td><td>509</td><td>60</td><td>1</td></tr>
<tr><td>520</td><td>510</td><td>60</td><td>1</td></tr>
<tr><td>585</td><td>511</td><td>60</td><td>1</td></tr>
<tr><td>650</td><td>512</td><td>60</td><td>1</td></tr>
<tr><td>714</td><td>513</td><td>60</td><td>1</td></tr>
<tr><td>65</td><td>603</td><td>60</td><td>1</td></tr>
<tr><td>130</td><td>604</td><td>60</td><td>1</td></tr>
<tr><td>195</td><td>605</td><td>60</td><td>1</td></tr>
<tr><td>260</td><td>606</td><td>60</td><td>1</td></tr>
<tr><td>65</td><td>903</td><td>60</td><td>1</td></tr>
<tr><td>130</td><td>904</td><td>60</td><td>1</td></tr>
<tr><td>195</td><td>905</td><td>60</td><td>1</td></tr>
<tr><td>260</td><td>906</td><td>60</td><td>1</td></tr>
<tr><td>325</td><td>907</td><td>60</td><td>1</td></tr>
<tr><td>390</td><td>908</td><td>60</td><td>1</td></tr>
<tr><td>455</td><td>909</td><td>60</td><td>1</td></tr>
<tr><td>65</td><td>1303</td><td>60</td><td>1</td></tr>
<tr><td>130</td><td>1304</td><td>60</td><td>1</td></tr>
<tr><td>195</td><td>1305</td><td>60</td><td>1</td></tr>
<tr><td>260</td><td>1306</td><td>60</td><td>1</td></tr>
<tr><td>325</td><td>1307</td><td>60</td><td>1</td></tr>
<tr><td>390</td><td>1308</td><td>60</td><td>1</td></tr>
<tr><td>455</td><td>1309</td><td>60</td><td>1</td></tr>
<tr><td>520</td><td>1310</td><td>60</td><td>1</td></tr>
<tr><td>65</td><td>1403</td><td>60</td><td>1</td></tr>
<tr><td>130</td><td>1404</td><td>60</td><td>1</td></tr>
<tr><td>195</td><td>1405</td><td>60</td><td>1</td></tr>
<tr><td>260</td><td>1406</td><td>60</td><td>1</td></tr>
<tr><td>65</td><td>1803</td><td>60</td><td>1</td></tr>
<tr><td>130</td><td>1804</td><td>60</td><td>1</td></tr>
<tr><td>195</td><td>1805</td><td>60</td><td>1</td></tr>
<tr><td>260</td><td>1806</td><td>60</td><td>1</td></tr>
<tr><td>325</td><td>1807</td><td>60</td><td>1</td></tr>
<tr><td>390</td><td>1808</td><td>60</td><td>1</td></tr>
<tr><td>455</td><td>1809</td><td>60</td><td>1</td></tr>
<tr><td>520</td><td>1810</td><td>60</td><td>1</td></tr>
<tr><td>585</td><td>1811</td><td>60</td><td>1</td></tr>
<tr><td>53</td><td>203</td><td>120</td><td>61</td></tr>
<tr><td>106</td><td>204</td><td>120</td><td>61</td></tr>
<tr><td>159</td><td>205</td><td>120</td><td>61</td></tr>
<tr><td>212</td><td>206</td><td>120</td><td>61</td></tr>
<tr><td>265</td><td>207</td><td>120</td><td>61</td></tr>
<tr><td>318</td><td>208</td><td>120</td><td>61</td></tr>
<tr><td>371</td><td>209</td><td>120</td><td>61</td></tr>
<tr><td>424</td><td>210</td><td>120</td><td>61</td></tr>
<tr><td>477</td><td>211</td><td>120</td><td>61</td></tr>
<tr><td>530</td><td>212</td><td>120</td><td>61</td></tr>
<tr><td>583</td><td>213</td><td>120</td><td>61</td></tr>
<tr><td>636</td><td>214</td><td>120</td><td>61</td></tr>
<tr><td>53</td><td>303</td><td>120</td><td>61</td></tr>
<tr><td>106</td><td>304</td><td>120</td><td>61</td></tr>
<tr><td>159</td><td>305</td><td>120</td><td>61</td></tr>
<tr><td>212</td><td>306</td><td>120</td><td>61</td></tr>
<tr><td>53</td><td>503</td><td>120</td><td>61</td></tr>
<tr><td>106</td><td>504</td><td>120</td><td>61</td></tr>
<tr><td>159</td><td>505</td><td>120</td><td>61</td></tr>
<tr><td>212</td><td>506</td><td>120</td><td>61</td></tr>
<tr><td>265</td><td>507</td><td>120</td><td>61</td></tr>
<tr><td>318</td><td>508</td><td>120</td><td>61</td></tr>
<tr><td>371</td><td>509</td><td>120</td><td>61</td></tr>
<tr><td>424</td><td>510</td><td>120</td><td>61</td></tr>
<tr><td>477</td><td>511</td><td>120</td><td>61</td></tr>
<tr><td>530</td><td>512</td><td>120</td><td>61</td></tr>
<tr><td>583</td><td>513</td><td>120</td><td>61</td></tr>
<tr><td>53</td><td>603</td><td>120</td><td>61</td></tr>
<tr><td>106</td><td>604</td><td>120</td><td>61</td></tr>
<tr><td>159</td><td>605</td><td>120</td><td>61</td></tr>
<tr><td>212</td><td>606</td><td>120</td><td>61</td></tr>
<tr><td>53</td><td>903</td><td>120</td><td>61</td></tr>
<tr><td>106</td><td>904</td><td>120</td><td>61</td></tr>
<tr><td>159</td><td>905</td><td>120</td><td>61</td></tr>
<tr><td>212</td><td>906</td><td>120</td><td>61</td></tr>
<tr><td>265</td><td>907</td><td>120</td><td>61</td></tr>
<tr><td>318</td><td>908</td><td>120</td><td>61</td></tr>
<tr><td>371</td><td>909</td><td>120</td><td>61</td></tr>
<tr><td>53</td><td>1303</td><td>120</td><td>61</td></tr>
<tr><td>106</td><td>1304</td><td>120</td><td>61</td></tr>
<tr><td>159</td><td>1305</td><td>120</td><td>61</td></tr>
<tr><td>212</td><td>1306</td><td>120</td><td>61</td></tr>
<tr><td>265</td><td>1307</td><td>120</td><td>61</td></tr>
<tr><td>318</td><td>1308</td><td>120</td><td>61</td></tr>
<tr><td>371</td><td>1309</td><td>120</td><td>61</td></tr>
<tr><td>424</td><td>1310</td><td>120</td><td>61</td></tr>
<tr><td>53</td><td>1403</td><td>120</td><td>61</td></tr>
<tr><td>106</td><td>1404</td><td>120</td><td>61</td></tr>
<tr><td>159</td><td>1405</td><td>120</td><td>61</td></tr>
<tr><td>212</td><td>1406</td><td>120</td><td>61</td></tr>
<tr><td>53</td><td>1803</td><td>120</td><td>61</td></tr>
<tr><td>106</td><td>1804</td><td>120</td><td>61</td></tr>
<tr><td>159</td><td>1805</td><td>120</td><td>61</td></tr>
<tr><td>212</td><td>1806</td><td>120</td><td>61</td></tr>
<tr><td>265</td><td>1807</td><td>120</td><td>61</td></tr>
<tr><td>318</td><td>1808</td><td>120</td><td>61</td></tr>
<tr><td>371</td><td>1809</td><td>120</td><td>61</td></tr>
<tr><td>424</td><td>1810</td><td>120</td><td>61</td></tr>
<tr><td>477</td><td>1811</td><td>120</td><td>61</td></tr>
<tr><td>35</td><td>203</td><td>999</td><td>121</td></tr>
<tr><td>70</td><td>204</td><td>999</td><td>121</td></tr>
<tr><td>105</td><td>205</td><td>999</td><td>121</td></tr>
<tr><td>140</td><td>206</td><td>999</td><td>121</td></tr>
<tr><td>175</td><td>207</td><td>999</td><td>121</td></tr>
<tr><td>210</td><td>208</td><td>999</td><td>121</td></tr>
<tr><td>245</td><td>209</td><td>999</td><td>121</td></tr>
<tr><td>280</td><td>210</td><td>999</td><td>121</td></tr>
<tr><td>315</td><td>211</td><td>999</td><td>121</td></tr>
<tr><td>350</td><td>212</td><td>999</td><td>121</td></tr>
<tr><td>385</td><td>213</td><td>999</td><td>121</td></tr>
<tr><td>420</td><td>214</td><td>999</td><td>121</td></tr>
<tr><td>35</td><td>303</td><td>999</td><td>121</td></tr>
<tr><td>70</td><td>304</td><td>999</td><td>121</td></tr>
<tr><td>105</td><td>305</td><td>999</td><td>121</td></tr>
<tr><td>140</td><td>306</td><td>999</td><td>121</td></tr>
<tr><td>35</td><td>503</td><td>999</td><td>121</td></tr>
<tr><td>70</td><td>504</td><td>999</td><td>121</td></tr>
<tr><td>105</td><td>505</td><td>999</td><td>121</td></tr>
<tr><td>140</td><td>506</td><td>999</td><td>121</td></tr>
<tr><td>175</td><td>507</td><td>999</td><td>121</td></tr>
<tr><td>210</td><td>508</td><td>999</td><td>121</td></tr>
<tr><td>245</td><td>509</td><td>999</td><td>121</td></tr>
<tr><td>280</td><td>510</td><td>999</td><td>121</td></tr>
<tr><td>315</td><td>511</td><td>999</td><td>121</td></tr>
<tr><td>350</td><td>512</td><td>999</td><td>121</td></tr>
<tr><td>385</td><td>513</td><td>999</td><td>121</td></tr>
<tr><td>35</td><td>603</td><td>999</td><td>121</td></tr>
<tr><td>70</td><td>604</td><td>999</td><td>121</td></tr>
<tr><td>105</td><td>605</td><td>999</td><td>121</td></tr>
<tr><td>140</td><td>606</td><td>999</td><td>121</td></tr>
<tr><td>35</td><td>903</td><td>999</td><td>121</td></tr>
<tr><td>70</td><td>904</td><td>999</td><td>121</td></tr>
<tr><td>105</td><td>905</td><td>999</td><td>121</td></tr>
<tr><td>140</td><td>906</td><td>999</td><td>121</td></tr>
<tr><td>175</td><td>907</td><td>999</td><td>121</td></tr>
<tr><td>210</td><td>908</td><td>999</td><td>121</td></tr>
<tr><td>245</td><td>909</td><td>999</td><td>121</td></tr>
<tr><td>35</td><td>1303</td><td>999</td><td>121</td></tr>
<tr><td>70</td><td>1304</td><td>999</td><td>121</td></tr>
<tr><td>105</td><td>1305</td><td>999</td><td>121</td></tr>
<tr><td>140</td><td>1306</td><td>999</td><td>121</td></tr>
<tr><td>175</td><td>1307</td><td>999</td><td>121</td></tr>
<tr><td>210</td><td>1308</td><td>999</td><td>121</td></tr>
<tr><td>245</td><td>1309</td><td>999</td><td>121</td></tr>
<tr><td>280</td><td>1310</td><td>999</td><td>121</td></tr>
<tr><td>35</td><td>1403</td><td>999</td><td>121</td></tr>
<tr><td>70</td><td>1404</td><td>999</td><td>121</td></tr>
<tr><td>105</td><td>1405</td><td>999</td><td>121</td></tr>
<tr><td>140</td><td>1406</td><td>999</td><td>121</td></tr>
<tr><td>35</td><td>1803</td><td>999</td><td>121</td></tr>
<tr><td>70</td><td>1804</td><td>999</td><td>121</td></tr>
<tr><td>105</td><td>1805</td><td>999</td><td>121</td></tr>
<tr><td>140</td><td>1806</td><td>999</td><td>121</td></tr>
<tr><td>175</td><td>1807</td><td>999</td><td>121</td></tr>
<tr><td>210</td><td>1808</td><td>999</td><td>121</td></tr>
<tr><td>245</td><td>1809</td><td>999</td><td>121</td></tr>
<tr><td>280</td><td>1810</td><td>999</td><td>121</td></tr>
<tr><td>315</td><td>1811</td><td>999</td><td>121</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/CardItemProduceConfig_more.json">完整原记录</a></p>
</details>

<details><summary>CardItemProduceConfig_zero：1条相关记录（原表1条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Chance</th><th>ItemType</th><th>LevelMax</th><th>LevelMin</th></tr></thead><tbody>
<tr><td>0</td><td>203</td><td>999</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/CardItemProduceConfig_zero.json">完整原记录</a></p>
</details>

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- CardItem.CardItemModel：[恢复源码](../../../../assets/merge-evidence/CardItem.CardItemModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/CardItem.CardItemModel.disassembly.txt)
- Board.Model.Board.BaseItemLayerModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseItemLayerModel.disassembly.txt)
- Board.Model.Base.BoardPosition：[恢复源码](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.disassembly.txt)
- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)

---

## 贯穿案例：两个201合成202



本例卡片活动未开启，不调用卡片随机，继续能量气泡。对照改为备用入口资格通过且随机命中，生成一张卡片，普通气泡不再检查。

### 代入本页的值

演示Chance=250，R=250命中、R=251失败（阈值为假设）。真实本地字符串ItemChain映射不会被ipairs遍历；对照改成连续数字键数组且UnlockLevel≤等级，才在随机前return nil，强制测试也无法绕过。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
