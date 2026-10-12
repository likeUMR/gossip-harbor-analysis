"""Scoped downstream supplements; preserve existing examples and config blocks."""
from pathlib import Path
import hashlib
import json
from html import escape
from lupa.lua53 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]

def config_tables(docs):
    modules=json.loads((ROOT/'analysis_data/logic_index/lua_modules.json').read_text(encoding='utf-8'))
    families={m['name']:m for m in modules if m['name'].startswith('Data.Config.CardItem')}
    tables=[]
    receipt=[]
    runtime=LuaRuntime()
    target=docs/'assets/recovered-source'
    target.mkdir(exist_ok=True)
    for name,row in sorted(families.items()):
        source=ROOT/'analysis_data/logic_index/lua/decoded'/row['sha256']/'decompiled.lua'
        table=runtime.execute(source.read_text(encoding='utf-8'))
        records=[dict(table[i].items()) for i in range(1,len(table)+1)]
        leaf=name.split('.')[-1]
        (target/(leaf+'.lua')).write_bytes(source.read_bytes())
        (target/(leaf+'.json')).write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
        fields=['ItemChain','UnlockLevel','Weight','Rarity'] if 'Produce' not in name else ['ItemType','LevelMin','LevelMax','Chance']
        lines=[f'<details><summary>{leaf}：{len(records)}条完整记录</summary>',
          '<div style="overflow-x:auto;"><table><thead><tr>'+''.join('<th>'+escape(f)+'</th>' for f in fields)+'</tr></thead><tbody>']
        lines += ['<tr>'+''.join('<td>'+escape(str(record.get(f,'—')))+'</td>' for f in fields)+'</tr>' for record in records]
        lines += ['</tbody></table></div>',f'<p><a href="../../../../../assets/recovered-source/{leaf}.json">完整数据</a> · <a href="../../../../../assets/recovered-source/{leaf}.lua">恢复配置</a></p>', '</details>','']
        tables.append('\n'.join(lines))
        receipt.append({'module':name,'source':source.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'records':len(records),'fields':fields,'runtime_selection':'Lua require wrapper -> first exact FileReplace.file match -> append suffix -> replacement failure falls back default; account suffix unavailable'})
    out=ROOT/'analysis_output/logic_recovery/stage3/generator_gate_audit/card_config_records.json'
    out.write_text(json.dumps(receipt,ensure_ascii=False,indent=2),encoding='utf-8')
    return '\n## 卡片相关完整本地配表\n\n'+ '\n'.join(tables)

CARD = '''
## 7. 卡片：先检查库存，再决定续用旧链还是抽新链 {#card-flow}

这条监听把符合条件的产出视为卡片生成进度。它读取消息的CostEnergy标志和指数，不读取本次实际扣能量的返回数量；OnItemSpread也没有另加Source必须是主棋盘的条件。实际落卡、库存检查仍使用主棋盘。因此不能将前述其它活动的主棋盘过滤条件复制过来。

### 7.1 库存达到什么程度会暂停

CanGenerateCardItem先要求活动Started，再CheckFinish，然后CheckCanMergeMaxCardItem。当前链没有isFinish、或isFinish=true时，库存检查直接返回false；否则取主棋盘、缓存、仓库三处代码数量，排除GetCodePrefixTargetType非nil的包装代码，只统计当前链。

每件L级卡片折成`2^(L−1)`个一级卡片，求总数C；最高等级M所需一级数为`N=2^(M−1)`。条件是 **C非0且C%N=0**。这是精确的整数倍判断，源码没有写C≥N：C=N暂停，C=N+1却不因本条件暂停。复刻时不能把它改成通常理解的“够合成就停”。card_item_stack等于1时，CheckFinish还会将满足该条件的当前链标为isFinish=true并保存；后续检查因已完成返回false，能量进度反而可以继续推进，下一次发卡会换链。

### 7.2 新链的候选、权重与避免连续重复

有chain且isFinish严格为false，直接返回旧链一级卡片，不抽链。否则按玩家等级≥UnlockLevel收集解锁链，先排除旧链；排除后为空才用旧链候选兜底，再用Table.ListWeightSelectOne按Weight抽一条。没有递减Weight或持久机会池，是本次重建候选的加权选择；正常有其它解锁链时相邻换链不会选回旧链。没有任何解锁候选时源码未写默认链；该配置组合不能凭空补一个默认卡片。

选中后保存chain、isFinish=false，再返回一级代码。Rarity不参与此抽样；它用于卡片表现与最高级首次弹窗。最高级使用后，非stack模式直接完成旧链；stack模式只在同链库存返回数量为0时完成。完成状态还会受活动清理、配置删除旧链影响，不能只在本次点击后内存里保存。

### 7.3 阈值、落子、保存与教程通知的顺序

阈值取本轮已有累计+1到周期长度的均匀整数。满盘时保存累积并返回；有位置且越过阈值、该轮未发卡时，先设本轮已发→选择/保存链→从母体扩散找空位→SpreadItem落一级卡片→派发CardItemGenerate→获得日志。周期边界随后清阈值与本轮标志，累计取模并保存。

CardItemGenerate还有本模型的OnCardItemGenerate监听：教程键已为字符串“2”时忽略，否则写“1”并发TutorialStartPop。CanPopCardItemTutorial要求活动Started且键为“1”；真正弹过后写“2”。这里是提示状态推进，不能解释成额外发一张卡。

### 7.4 对应配置如何读

| 配置/字段 | 读取及用途 |
|---|---|
| CardItemConfig.ItemChain | 作为链字典键；同键后记录覆盖前记录 |
| UnlockLevel、Weight | 新链候选等级门槛、候选间抽样权重 |
| Rarity | 表现/首次最高级弹窗；不再次抽资格 |
| 服务器misc_conf_new中confType=card_item_energy的首条param_int | 周期长度；未取得则m_energyGenerateNum=nil，点击能量监听不生成 |
| general配置card_item_stack | 严格等于1开启完成链堆叠分支 |
| CardItemProduceConfig.ItemType、LevelMin/LevelMax、Chance | TryGenerateItem另一入口按物品代码取记录，第一条适配等级优先；概率是1..10000比较Chance。本次OnItemSpread能量路径不读取这张概率表 |

本地默认链表26条，more变体26条；下方全量列出。实际require已被启动脚本改写：ConfigModel从模块路径末段取文件名，在服务器FileReplace列表顺序查找第一条file精确匹配记录，将suffix原样追加到路径；没有匹配则用原路径。替换路径加载成功就用该表；加载抛错才记录错误并回退原路径。默认回退也失败时不另造空表。普通Lua模块缓存按最终路径工作，替换服务器值并不等于既有卡片字典自动重建。

例如file=CardItemConfig、suffix=_more会选more链表；CardItemProduceConfig可独立配_zero，不能假设两张表总是同后缀。尚未取得账号FileReplace记录，不能确定当前账号是哪一份，但选用规则本身可从源码确认。产物概率表也提供全部恢复记录，供核对另一入口，不能把其中204的Chance=70写成“母体点击有0.7%额外落卡”。

### 7.5 数值对照：同样多于一张最高卡片，为何结果不同

食品袋105基础档产出且CostEnergy=true，给卡片进度1；以下为独立活动状态演示，替换主例中活动未启用的前提。假设当前卡片链最高三级，则N=4：库存一级等价C=4、stack关闭时暂停，计数不变；C=5时不暂停。再假设周期10、已有累计2、阈值3、未发卡且有空位，本次累计到3，只发一件当前链一级卡片，累计保存3；到10才清本轮标志。stack开启、C=4时先把旧链标完成，本次可继续计数并在发卡时抽新链。周期、库存、阈值和开关是演示输入。

默认表等级25首次无旧链时13条候选总权重24047，energy_b权重600，概率600/24047≈2.50%；假设上条已完成链是energy_b，则剩候选总权重23447，本次不再选energy_b。不是600/10000，亦不使用Rarity=4作权重。
'''

ROOM = '''
## 8. 密室：同一次落子按当前锁定状态分流 {#room-flow}

入口先筛Source主棋盘且CostEnergy为真；活动Started且m_curInfo存在后，roomState=0走钥匙进度，=1走解锁期工具奖励。它们互斥，本次从锁定状态达到解锁门槛后，不回头再执行解锁期的能量奖励。

### 8.1 锁定：机会命中推进钥匙，满额立即解锁

剩余点击数≤0才重装chance[总数,命中配额]；抽整数1..剩余点击数。失败只减总数、保存并返回；命中只减命中配额，给ceil(2^指数)钥匙，源码没有在命中分支也减总数。AddLockScore累加钥匙，到maxNum就截满并调用SetUnLockState。AddLockScore先保存，之后AcquireKey记获得日志，TryLockStartAddScore再发局部AddlockStateScore（包含是否已解锁、母体、指数），最后再保存。

SetUnLockState的顺序是：标记刚解锁→roomState设1→解锁分数归0→重装工具第一轮（累计能量0）→截止时间设服务器时间+time×3600→写未展示解锁标记→给2个Token→GameStateChanged(isLock=false)→解锁日志→BundleDataRefreshed→保存→设待弹窗标记1。已有其它密室物品/秘密宝物状态并不在此处全部清空。

### 8.2 解锁：累计能量只结算当前一轮

本次加ceil(2^指数)到acuqireTokenInfo（源码字段拼作acuqireTokenInfo）的curEnergy。若累计≥当前energy门槛：只减一次当前门槛→调用RewardApi.AcquireRewardsLogic发当前tools，来源Give、模式Main、缓存Type2→轮数+1→读取新轮energy/tools。随后局部AddUnlockStateScore消息附本次分值、奖励（未达门槛时nil）、母体和指数，再保存。没有while循环；剩余累计即使够下一轮，也留到下一次符合条件的通知。

TryUnlockActivityToken并不调用AcquireToken；奖励是什么取决于tools配置，不能把每次消耗能量固定解释成Token+1。SetTokenNum本身先发TokenNumberChangedEvent差量，再写activityToken，监听收到通知时存档仍可能是旧值。

### 8.3 配表选轮、时限与重锁

roomActivate先按round升序，选择最后一条round≤当前轮的记录，读取token、chance、time。roomGetTool按round建字典；有精确轮就直接取，无精确轮时在isCyclic=1记录中循环：newRound=当前轮−#工具表，序号=(newRound−1)%循环数量+1，再按ipairs的循环记录次序选择。它依赖连续数组索引与至少一个循环记录，源码未为稀疏表/0循环数补默认。

UpdatePerSecond先调用活动父类更新，再检查解锁截止≤服务器时间。到期SetLockState：roomState设0、round+1、钥匙归0、读取该轮token/chance并重装机会数、清解锁展示标记；发GameStateChanged(isLock=true)、下一轮及锁定日志，保存，再发BundleDataRefreshed，待弹窗标记设0。活动状态计算在解锁期用max(活动eTime,解锁截止)决定Started结束点：已解锁时间可能延续到原活动结束之后。

以上roomActivate/roomGetTool来自_LoadOtherServerConfig，当前快照没有本次账号远端活动记录，因此这里只给出字段和算法，不能填成原版固定门槛。roomLevel、roomReward、roomScoreReward在同函数装载，但本次上述落子分支不直接读取；它们的密室内玩法不能与母体点击直接获得的钥匙混为一谈。

### 8.4 数值对照：解锁点击与跨轮奖励

独立演示食品袋105指数2、CostEnergy=true。锁定状态总数3、配额1、钥匙8/10、随机点1：配额1→0，总数仍3；加4钥匙后截为10并解锁，给2个Token，工具累计重置0，本次不再加工具进度4。假设time=2、服务器时间1000，截止8200。门槛/状态/随机点是演示输入，2 Token与小时换秒为源码常量。

另设已经解锁、工具累计2、当前门槛3、下一轮门槛2，指数2本次加4：累计6，发当前轮tools一次，减3余3，轮数+1；尽管余3≥新门槛2，本次不补发下一轮。下一次基础档加1后累计4，才再减2并发新轮奖励，余2。不能用while结算替代源码。
'''

TOKEN = '''
## 9. 动态注册：点击还会给连锁礼包代币 {#token-flow}

ItemClickAcquireModule不是活动的最终消费者。ActivityModuleManager把ClickAcquireProperty分派给该模块；TokenChainActivityModel进入Started时注册一个实际回调，机会参数来自服务器tokenChainGiftConfig[1].chance。注册附带的条件同时要求Started且未完成全部礼包，覆盖模块默认的“只检查Started”。不能只清点直接ItemSpread监听就漏掉这个活动。

### 9.1 有限机会池与状态隔离

每个注册model用自己的DB和键。本活动显式提供TotalClickTimes、ValidClickTimes，分别存剩余总机会与命中配额；缺值按0处理，总机会等于0才重装chance[1]/chance[2]。抽1..总机会，先总机会减1保存；随机点大于配额则返回nil，否则配额减1保存，返回能量指数对应的数量。正指数用循环每步乘2；nil/0/负指数返回1，源码未为小数指数另作规范化。资格按点击机会抽，命中件数按指数增益，两者不是把总机会一次扣2^指数。

AddRegister再次针对同一model调用会替换回调与参数，不直接清已有DB机会数。移除注册也只删内存映射，不清计数。多个model通过pairs遍历，源码没有保证它们的回调次序。

### 9.2 真正增加代币的顺序

模块每次把结果（包括nil）和母体交给回调。TokenChain的回调对nil或≤0立即返回，所以这个具体消费者确实忽略未命中；命中时先SetTokenNum（写DB，再发TokenNumChangedEvent），再记cost_energy日志，然后寻找主棋盘视图和母体视图，最后播放代币飞行动画。视图不存在时返回，但代币已入账；动画结束不能再加一遍。此保存/通知顺序与密室Token的先通知后保存相反。

进入Started时如CanGiveStartToken成立，还会标记已领取并先给10个开始代币，日志来源free；这是活动启动奖励，不是母体本次命中奖励。后续离开Started不在本函数显式移除注册，条件回调负责阻止非Started/已完成时继续抽取。

### 9.3 数值对照

独立假设chance=[3,1]、活动Started且未完成、代币余额10。食品袋105指数2的一次有效产出，随机点1命中：总机会3→2、配额1→0，代币10→14；若主棋盘视图为空，只省略动画，余额仍14。接着基础档随机点2未命中：总机会2→1、配额仍0，回调收到nil且余额仍14。若活动已完成，注册条件不成立，总机会也不会扣减。chance、库存与活动状态是演示输入；没有取得账号远端chance时不能将3/1当原版默认值。
'''

def supplement(docs: Path):
    from stage3_generator_deep_repairs import BODIES
    rel='events/side_effects/detail.md'
    body=BODIES[rel].replace('# 落子通知后的 GeneratorBoost 追加产出','# 落子后：追加产出、活动进度与奖励',1)
    body=body.replace('先CheckFinish；能合成最高卡片时停止生成。', '先CheckFinish，再按当前链库存的精确整数倍条件决定是否暂停；stack开启会先将该链标完成，详见第7节。')
    body += CARD + ROOM + TOKEN + config_tables(docs)
    page=docs/'operations/generator'/rel
    text=page.read_text(encoding='utf-8')
    idx=text.index('\n---\n')
    page.write_text(body.strip()+'\n'+text[idx:],encoding='utf-8')
    parent=docs/'operations/generator/events/side_effects/index.md'
    text=parent.read_text(encoding='utf-8')
    marker='<!-- downstream-flow:start -->'
    if marker not in text:
        before='''\n<!-- downstream-flow:start -->
## 同一通知还可能推进什么

监听不是所有账号必经的一串步骤。各自先判断活动和事件资格，再进入自己的状态分支：卡片先检查库存与完成状态，再累计能量、判断阈值，最后决定续用旧链或抽新链；密室先按锁定/解锁状态分流，分别推进钥匙或工具奖励。一项活动不满足条件，不阻止其它监听响应。

卡片停止条件、换链和数值对照见[卡片具体流程](detail.md#card-flow)；密室解锁、跨轮奖励和到期重置见[密室具体流程](detail.md#room-flow)。这些分支也会发出后续通知，因此只看到主物品落下还不能视为点击链结束。
<!-- downstream-flow:end -->
'''
        text=text.replace('\n---\n',before+'\n---\n',1)
        parent.write_text(text,encoding='utf-8')

if __name__=='__main__':
    supplement(Path(__file__).resolve().parents[1]/'analysis_output/logic_recovery/stage3/mkdocs_site/docs')
