"""Replace only local example tails. Keep user-edited specifications and navigation intact."""
from pathlib import Path
import hashlib, json, re, shutil, html

ROOT=Path('C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis')
SITE=ROOT/'analysis_output/logic_recovery/stage3/mkdocs_site'
DOCS=SITE/'docs'
AUDIT=ROOT/'analysis_output/logic_recovery/stage3/example_revision_audit'
CASES={}
def add(key,title,conditions,logic,calculation,result):
    CASES.setdefault(key,[]).append(dict(title=title,conditions=conditions,logic=logic,calculation=calculation,result=result))

# Inputs here deliberately belong to independent explanatory scenarios.
M='merge/'
add(M+'release/movable','可以拖动的普通食物','棋盘源格(3,3)放普通201，无纸箱、网、锁或吞噬组件，首次按住后拖动。','逐项检查限制，没有限制便让图像跟随手指。','PaperBox=nil→Cobweb=nil→Locked=nil→Swallow=nil，CanItemMove=true；首次拖动派StartDraggingItem，m_dragging=false→true。格层仍是S→原对象。','201跟随手指，源格的实际棋子尚未移动；没有扣能量。')
add(M+'release/position','短时间高亮吸附','源在(3,3)，高亮目标在(4,4)，松手换算为(3,3)，距高亮0.10秒，无强制教程目标。','高亮仍在吸附有效时间内，松手格也足够近，改用高亮格。','0.10<0.15；(3−4)²=1≤1，两轴均通过；传给模型的位置由(3,3)改为(4,4)。','本来松手在原格的201被送到右上方高亮棋子所在格，后续按该格判断合成。')
add(M+'release/position','教程指定落点','教程指定(4,3)，松手为(5,3)，没有近期高亮。','松手格与教程要求不一致，送入无效落点以便复位。','(5,3)≠(4,3)→位置改(0,0)；PositionIsValid=false→SetPosition(原位置)并返回。','201回到原格，目标不改变，没有合成或扣能量。')
add(M+'release/inventory','成功存入仓库','仓库功能已开启，普通201可移动，无气泡、临时物、计时变换、开启中母体或工厂限制；仓库占2格、容量3，松手命中Inventory。','先核可存资格，再核容量；成功存入便结束棋盘分派。','资格=true，2<3；_SetItem(S,nil,false)→AddItem→Count/Update；stored=true，DragItem不执行。','棋盘少一件201，仓库从2件变3件；仍持有这件物品，本次不合成。')
add(M+'release/identity','拒绝过期拖动对象','松手格(4,3)合法，但源格原201对象A已被另一201对象B替换。','格子内的物品身份与拖动对象不同，拒绝继续。','1≤4≤7且1≤3≤9；GetItem(S)=B≠A，即使两者Type=201，仍SetPosition(A原坐标)→return。','旧拖动被撤回，棋盘上的新201和目标棋子都保留，不消耗物品。')
add(M+'move/write','把201移入空格','S=(3,3)是普通201对象A，T=(4,3)为空，释放资格通过，能量10。','空格采用移动路径，沿用原物品，不进行合成。','清S(false)→写T=A(false)→LogMove→SetPosition(T)；空位先+1再−1，净变化0。','201从左格移到右格，原格空出；能量仍10，没有新产物。')
add(M+'move/accelerate','移动正在计时的母体','源为可移动计时母体，Spread.CanAccelerate=true，T为空；假设两次计时刷新都尚未达到完成时间。','母体移动可能改变加速覆盖，因此马上刷新计时组件，再结束移动。','source检查=true→UpdatePerSecond()两次；派ItemMoveEnd{item=source}一次→return；本例计时刷新未完成，类型不变。','母体到达新格，计时显示按新位置重新核对；本次不合成，也不额外生成物品。')
add(M+'special/eligibility','剪刀获准拆分202','剪刀拖向202，目标LevelDownPiece=1；除S和T外另有一个空格，棋盘非满。','目标允许拆分且有空间，特殊作用先接管拖拽。','映射LevelDown=true；not IsBoardFull=true→CanItemAffect=true；打开拆分确认窗，源回位并return true。','出现拆分确认窗，202暂未改变；确认后才能得到两件201。')
add(M+'special/upgrade','升级202到203','level_up_piece_1在S，202在T且LevelUpPiece=1、MergedType=203；确认时资格仍有效。','玩家确认后消耗升级道具，把目标提升一级。','RemoveItem(source)→ReplaceItem(T,203)→MergeItem/ItemMerged→四邻震动；日志ext.levelup=1；不调用普通_DoMergeItem。','升级道具消失，202变成203；不执行普通合成直接计分和副产物抽取，能量不变。')
add(M+'special/scissors','两把剪刀合并次数','源剪刀剩2次，目标剪刀剩3次，目标同为LevelDown；棋盘可以满。','同类剪刀不拆分棋子，直接合并剩余使用次数。','CanSpecialTypeAffect(LevelDown)=true，不受满盘阻挡；目标次数3+2=5并保存，删除源剪刀。','两把剪刀变成一把可使用5次的剪刀，源格空出。')
add(M+'special/split','最后一次剪刀拆分','剪刀在S=(3,3)且剩1次，目标202在T=(4,3)；另有空格(7,9)，其余格占满，玩家确认。','扣剪刀次数，再把目标拆成两件前一级食物；第二件按固定空位顺序放下。','次数1−1=0→删剪刀；删202→T生成201；以T为中心第1圈第7项S为空→S生成201。','剪刀消失，原202变成两件201，分别在原目标格和原剪刀格；能量不变。')
add(M+'special/failure','升级被拒后交换','升级道具在S，目标为可移动、不可升级的普通物，类型不同且无吞噬组件；目标LevelUpPiece缺省。','显示不能升级的提示，但继续判断后续分派，最终走交换。','CanItemAffect=false→hint_not_upgrade；CanItemMerge=false；Swallow=nil；CanItemMove(target)=true→交换两格。','没有消耗升级道具，两件物品互换位置；玩家先看到不可升级提示。')
add(M+'normal/eligibility','网中201参与合成','源为普通201，目标为蜘蛛网包装的201；源未用过一次性宝箱，工厂未阻挡，普通侧MergedType=202。','目标比较的是网里的食物类型，与源相同且能升级，允许合成。','sourceType=201、targetInner=201，mergedType=202；201==201且202非nil→true。','拖入的201与网中201合成202；不需要先把网中物作为拖动源。')
add(M+'normal/replacement','两件201替换成202','S=(3,3)、T=(4,3)各普通201，合法合成，能量10。','先删除两个输入，再在目标格保存并生成下一等级。','删除source及target；GenerateItem(T,202)保存属性并写格；S=nil、T=新对象202，201数量2→0、202数量0→1。','两件201变成目标格的一件202，源格空出，能量仍10。')
add(M+'normal/notify','邻格接收合成震动','201合成202，T=(4,3)，四邻均有可接收Shock的对象；假设各邻格本次Shock不变换物品。','先通知合成，再只震动上下左右邻格。','局部MergeItem→全局ItemMerged；Shock邻格(4,2),(5,3),(4,4),(3,3)，空格不调用对象Shock；此例S已空，实际对象Shock为3次；再ItemShocked。','目标出现202，三个仍有物品的正交邻格收到震动，斜角格没有震动；本例没有额外掉落。')
add(M+'normal/score','合成推动竞速','竞速配置已加载、活动开放且玩家入组；假设201计2分，当前5分、目标10分；201合成202。','合成先清旧气泡购买记忆，再按被拖入物计竞速分。','m_lastBreakBubbleType→nil；读201.merge_score_race=2；5<10→_AddScore(2)→5+2=7，派ScoreRaceScoreChanged。','得到202，竞速从5分升至7分，还差3分达标；没有扣能量。')
add(M+'normal/score','本次合成达到竞速目标','沿用上一场景，改为当前8分，目标10分，当前没有竞速ViewController。','被拖入物仍计同样分数，本次达到目标并进入达标表现。','8+2=10；新分不再小于目标；派分数通知，无ViewController则创建并设State=0。','202正常生成，竞速达到10分目标，启动达标界面流程；这里不额外假设已经领取终点奖励。')
add(M+'normal/temp','旧规则帮助订单缺口','假设活动Started、OldMode，盘上无临时物、无无限能量；能量10≤门槛20，非免费购买价格20≥门槛10；now=1000、lastEnd=600、interval=5分钟。201合成202后本链仅202一件；订单缺205一件，Rule[205]=[203,204]，Advanced关闭，203/204库存均无。','资源和间隔都满足，订单仍缺高阶食物，按规则选第一个高于本次结果的临时食物。','1000−600=400>5×60；205前1/2级204/203均无；mergedLevel=2，Rule首203等级3>2→203，未到列表末项；保存Target=205、StartTimer=1000、LastChain=2；S空，生成Temp包装203。','202保留，旁边额外出现临时203，帮助继续合成订单所缺的205；本次卡片和两类气泡不再尝试。')
add(M+'normal/temp','新规则按等价库存补缺','活动与资源、时间同上，改NewMode/MoreBetter；订单缺204一件，Rule[204]存在；合成后本链只有202一件，假设203和204的触发阈值均1，其它候选阈值1。','把低阶库存折算成合成份额，确认高阶需求仍不足，再从可用区间选临时帮助物。','diff[1]=1，diff[2]=2−2=0，diff[3]=4−2=2，diff[4]=8−2=6；需求204的6>1→maxLevel=4；检查mergedLevel+1=3到max−1=3，diff203=2>1→选203；保存Target203、StartTimer1000、LastChain2并检查上传。','在202旁生成临时203；帮助填补204订单，本次不再抽卡片或气泡。')
add(M+'normal/card','合成备用入口生成卡片','假设卡片活动Started、CheckFinish完成后活动仍有效，现有未结束链main_card_item_energy_s最高4级、库存仅1件一级，未凑满最高级；201产出档LevelMin=1/Max=40、Chance=2500，玩家30级；类型配置以字符串链名为键，临时物未生成，棋盘有空位。','备用入口资格通过后做一次独立概率判定，命中便生成当前链一级卡片物。','等价库存1，最高级需2^(4−1)=8，1%8≠0→不暂停；字符串键map用ipairs不访问任何条目→isLevelLock保留true；R=2000≤2500→GenerateCardItem，沿用未完成链返回一级物；落S，hasCreateItem=true。','额外得到一件当前卡片链的一级物，202保留；这次不再尝试两类气泡，能量不变。')
add(M+'normal/energy','低能量时生成购买气泡','临时物和卡片都未生成；假设能量气泡Started，now1000>旧Trigger999；能量10、非免费购买价格20；唯一档trigger_energy10、trigger_gem20、energy100、gem30、interval5、groupId2，S为空。','能量和购买价格同时过门槛，选该档并开始下次触发等待，再落下能量气泡。','10≤10且20≥20→选档；TriggerTime=1000+5×60=1300，GroupId=2保存；Code按PropertyBubble前缀、Energy、100、30拼接，SpreadItem到S；hasCreateItem=true。','202旁出现内含100能量、购买价30宝石的气泡；当前能量仍10，没有自动扣30宝石，等待5分钟后才可能再次触发该机制。')
add(M+'normal/bubble','订单加成使气泡必出','假设203×2合成204，前三类副产物未生成，Bubble开启、基础概率40，无同类204气泡；204下一等级205在订单中缺1件，204的WeightMultiple=1，Bonus模式1，有空位。','新物正好帮助继续制作订单目标，命中订单加成，跳过普通衰减再判定产出。','204.MergedType=205、lack205=1>0、WeightMultiple=1→p=100；不乘r1/r2/r3；R=73≤100，生成204气泡到S。','得到204，旁边还必定出现一枚204气泡；气泡尚未购买，不自动变为第二件可用204。')
add(M+'normal/bubble','三种衰减都参与后命中','假设203×2合成204，Bubble开启、基础40；无订单/购买加成，无同类气泡，本链订单均已够用；订单倍率0.5。棋盘另有本链第6、7级气泡各1枚，固定衰减等级5、每枚倍率0.5。未购买登录3天，唯一档day2/ratio80；有空位。','订单已够用、高阶气泡存量和登录档依次降低概率，本次独立随机仍命中。','p=40×0.5×(0.5^2)×(80/100)=4，下限max(4,1)=4；day2<login3成立；R=3≤4→204气泡落S；没有改动高阶气泡数量。','204旁额外出现204气泡；这次在被多项因素压低的机会下仍然命中，已有高阶气泡保留。')
add(M+'normal/coin','高阶合成额外生成金币棋子','207×2合成208，结果在链第8级，默认金币门槛8；假设前述副产物没有占掉S，能量10、金币余额100。','主副产物判断之后另看等级与空间，达到门槛直接发金币棋子。','newLevel8≥threshold8且非满盘→SpreadItem(Coin01)到首空S；没有随机调用，没有金币资源Acquire。','208旁多一枚一级金币棋子；余额仍100，能量仍10，需要玩家再收取金币棋子。')
add(M+'normal/finish','正常合成结束并返回','201×2合成202，Source/Target无Temp/Cobweb，假设本次无副产物；最近触碰配对未命中。','完成追加判断后检查同步并记合成日志，返回后不会再吞噬或交换。','Coin检查→CheckMoreUpload(202)→LogMerge(201,202,ext)；ext副产物字段nil，logType201；DragItem return。','棋盘剩目标格202，源格空出，能量不变；同步已提出检查，本例不假设服务器已确认。')
add(M+'swallow/target','有限池确定吞噬需求','假设吞噬目标类型X的槽1权重201:2、202:1，需求数量2，AllowTap=0；共享池之前空，无教程强制类型；源是普通201。','创建目标时打乱有限份额并消费一份；拖入时只比需求，不重新抽奖。','展开索引[1,2,3]，Fisher–Yates取j3=3、j2=2、j1=1→序列不变；消费首索引1→Code201，余[2,3]保存；Count2/Swallowed0；CanSwallow(201)=true。','这个目标需要吞入两件201；拖入201会被接受。下一目标继续使用剩余份额，本次拖入没有重抽需求。')
add(M+'swallow/progress','吞入第一件但尚未完成','目标需求201×2、已吞0，源201在S；两者不能普通合成，目标有Swallow组件。','接受尚缺的一件，保存进度并删拖入物，再检查是否完成。','首匹配Code201：Swallowed0+1=1<Count2；保存Swallowed=1，删除源，派吞噬进度通知；完成检查false。','201消失，目标从0/2变1/2，还需一件201；本次没有奖励变换，也不交换。')
add(M+'swallow/transform','最后一件触发奖励变换','目标需求201×2、已吞1，拖入另一201；假设Transform_Weight=[203:3,204:1]，CostEnergy=false、AllowTap=false，能量10。','补齐需求后独立按权重选奖励，目标原位变换。','1+1=2=Count；完整权重总4，记录候选顺序203/204，R=2→203；删除源和吞噬目标，在T生成203；能量不扣，邻格震动。','拖入201和吞噬目标都消失，目标格出现203，能量仍10；这次不走普通气泡或金币奖励。')
add(M+'swap/blocked','锁定目标拒绝交换','源201可移动，目标为锁定204；特殊作用、普通合成、吞噬都未接受。','最后检查目标能否移动，锁定物不能互换。','CanItemMove(target)=false→source.SetPosition(S)→return；格层写次数0，交换加速刷新0。','201回原格，锁定204保持原位，没有扣能量或合成。')
add(M+'swap/exchange','不同类型棋子互换','S普通201、T普通204，双方可移动，无特殊或吞噬关系，普通合成不成立，能量10。','前面各作用未接管，沿用两件原对象交换格子，再刷新计时影响。','清S(false)→T写source(false)→S写target(默认刷新)；分别SetPosition(T/S)并记移动日志2次；双方无加速组件→计时刷新0。','201和204互换位置，物品总数不变、能量仍10；不生成新物，不派空格移动专用ItemMoveEnd。')
add(M+'pointer/selection','合成后的选中收尾','201×2已生成T处202；原源对象被删除，m_dragging仍true。','优先看原对象还在不在，不在则选择落点的结果物，然后释放拖动状态。','源对象已不在格层→取T处新202并选中；BoardPointerUp消息携dragging=true；随后m_dragging=false并清指针缓存。','202成为当前选中棋子，拖动结束，信息栏显示结果物而非已删除的201。')

O='orders/'
BASE='普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。'
add(O+'entry/button','按钮允许提交',BASE+'按钮开启，非特殊入口。','允许点击后播放服务音效，再检查棋盘需求。','m_bGoButtonEnabled=true→不return；播放sfxOrderServe；GetCodeCountMap(true,false,false)得到203:2，需求检查204不足→打开确认窗。','听到服务音效，出现使用仓库204补交的确认窗；金币仍100，物品未扣。')
add(O+'entry/counts','区别棋盘与总持有',BASE+'另外缓存有204×3。','首次检查只统计棋盘上的精确代码，仓库和缓存都不参与。','参数(true,false,false)→map={203:2}，204=0；不是仓库加缓存后的204=4；CanDeliver需求第3项失败。','虽然仓库和缓存都有204，仍会出现仓库补交提示；缓存不能替代此次材料扣除。')
add(O+'entry/requirements','重复需求缺口',BASE+'改为棋盘只有203×1，仓库再有203×1。','每个重复需求都累加需要数量，逐项查出全部缺口。','i1需203×1、持有1通过；i2累计需2、持有1→缺203=1；i3需204×1、持有0→缺204=1；返回false及{203:1,204:1}。','窗口要求从仓库补一件203和一件204，不能用一件203满足两个需求；此时未扣物。')
add(O+'entry/inventory','确认仓库补交',BASE+'确认窗已重算缺204=1；关闭期间订单和物品不变，无专用关闭回调。','记录确认意愿，关闭动画结束后核订单仍在，再提交。','OnGreen置确认标记并Close；OnCloseFinish确认真、ContainsOrder=true→FinishOrder；Gold100+8=108；扣棋盘203×2和仓库204×1。','确认后获得8金币，三件需求都被消耗，订单完成；能量仍10。')
add(O+'entry/special_window','特殊订单二次点击','假设特殊任务需求1610一件，棋盘上有该物且可用于展示；按钮开启，初始化和聚拢已完成。','先展示需求，再由玩家再次点击确认提交，不沿用普通订单仓库窗。','首次打开SpecialOrderItemWindow；等待完成标记；再次点击→还原展示对象→FinishOrder→特殊完成路径，随后关闭窗口。','首次点击只看到任务物聚拢；第二次点击才交付并进入特殊任务奖励流程，展示不会提前扣物。')
add(O+'dispatch/type','分流决定执行链',BASE+'对照另两场景：内部类型Special与Branch，各采用下面对应任务的完整输入。','先识别特殊任务，再识别分支任务；其余才进入普通结算。','Normal→非Special/Branch→普通链：价格8、难度9；Special→_FinishSpecialOrder后return；Branch→_FinishBranchOrder后return。','普通单领8金币并扣三件需求；特殊与分支单各走专用清链和奖励，不再叠加普通单8金币。')
add(O+'dispatch/special','特殊任务完成清链','本地特殊Id1：需求1610、GeneratorChain15、奖励宝石15/能量100；假设任务有效，棋盘1610/1501、仓库1601、缓存1502各1，初始宝石20、能量10，无其它16/15链物。','完成任务后清理需求链和母体链，再发专用奖励、写任务完成标记。','清链16及15：移除上述4件；Rewards=[Gem15,Energy100]→20+15=35、10+100=110；special_order_1=1；普通价格/扣需求链不执行。','两条任务相关链从棋盘、仓库和缓存清除；宝石变35、能量变110，任务1完成。')
add(O+'dispatch/branch','分支奖励有限池全部发完','本地槽7奖励2402×2、2405×1、2502×2、2503×1；假设分支资格有效、相关清链已完成，奖励时仅2个合法空格。','按剩余份额随机一件就减一份，直到所有奖励发完；空间不足的进入缓存。','按此序2402/2405/2502/2503，权重6→5→4→3→2→1，示例抽签1/2/2/3/1/1依次得到2402,2405,2502,2503,2402,2502；各Count−1，最终全0。','棋盘收到2402和2405各一件；缓存收到2402一件、2502两件、2503一件；顺序随机，总共六件不会少发。')
add(O+'rewards/price','金币Buff翻倍',BASE+'非基准单、BuffGold激活、BakeOut不能领奖，亲密度订单抑制条件不成立。','逐件算价和难度，再把最终金币价翻倍。','Price=2+2+4=8；Diff=2+2+5=9；multiple2，ceil(8×2)=16；PropertyType=Gold。','本单发16金币，余额100变116，难度累计本次贡献9；不是三件物品各只算一次。')
add(O+'rewards/price','基准单采用推荐价',BASE+'改为基准标记true；假设203推荐价3、204推荐价6，金币Buff关闭。','基准单优先采用推荐价格，普通难度值保持各物配置。','price=3+3+6=12；diff=2+2+5=9；ceil(12×1)=12。','本单发12金币，余额变112，难度贡献仍9。')
add(O+'rewards/activity','活动奖励与相册修正',BASE+'假设主装饰Started且可计分返回代币3；FloatRace返回2代币；TimedRewards不含相册包；Album开放返回相册包1且AlbumBuff可支持并激活；Avenue返回4，其它活动无奖励，非宝箱槽。','按调用顺序收活动奖励，相册Buff加倍该包，末尾追加金币。','追加DecorToken3→FloatRaceToken2→AlbumPack1×2=2→AvenueToken4→Gold8；假设初余额Decor5/Race7/Avenue6，逻辑落账后分别8/9/10；Gold108，相册处理器收到2包。','得到3个装饰代币、2个竞速代币、4个街道代币和8金币；相册获两包，体现相册加倍而非全部奖励加倍。')
add(O+'rewards/activity','限时标记避免重复相册','普通单价格8、难度9；假设TimedRewards含相册缓存标记、Album开放，其它直接活动奖励为空。','发现限时相册标记后跳过普通相册追加。','skipAlbumReward=true；此GetRewards未把TimedRewards整体追加；输出此函数rewards=[Gold8]。','本函数只追加8金币，避免再加一份普通相册包；限时奖励的实际发放由限时订单自己的流程负责。')
add(O+'rewards/snapshot','即时奖励和宝箱标记分离','假设有效奖励顺序为Gold8、合法宝箱顾客标记K×1，K按RewardKey+innerType+"_"+slot构造；本页只演示分组，提交时余额100。','前缀识别把标记留给稍后处理，分别复制两份快照。','即时=[Gold8]；delay={RewardKey:[K×1]}；对两者DeepCopy；修改原奖励数组不改变两份副本。','先领取8金币；宝箱标记暂留在延迟结算中，不被当成金币或直接一件棋子。')
add(O+'rewards/acquire','货币入账与棋子入缓存','假设逻辑奖励[Gold8,Item204×2]，Gold100，缓存原来空，目标主棋盘、Type2。','按类别处理，金币变资源，棋子按数量展开入缓存。','Property处理Gold8→108；Item204 count2展开[204,204]→CacheItems；不同类别pairs先后不保证，最终状态相同。','金币余额108，缓存增加两件204；棋盘不会凭这一步直接多两件204。')
add(O+'rewards/gift_buff','礼物和Buff分别发放',BASE+'假设亲密度已开放、giftRewards=[Gold3]，GetBuffRewards返回[Energy5]；基础Gold8已发完。','先单独发礼物，再单独发Buff，不重复发基础金币。','初Gold100/Energy10；基础后108/10；gift非nil且IsOpen=true→Gold111；BuffRewards非nil→Energy15。','总共收到11金币和5能量，余额111、能量15；其中礼物3金币与Buff5能量是额外两次结算。')
add(O+'rewards/smile','首个普通微笑订单','主游戏普通槽1；假设OrderBoost Started/curInfo有效，档order_slot1/order_num5/reward_num1，槽完成数0，score0、Max10、logicType Normal。','读取本槽微笑奖励，更新活动分数和完成次数，首轮提示留到末尾。','smileNum1；OnOrderFinished加1→score=min(0+1,10)=1、slotCount0→1；保存并派SmileAdd；1==smileNum且score1且Normal→triggerButterfly=true。','微笑进度变1分，本槽记一次完成；正常交付结算完才出现首个微笑相关提示。')
add(O+'consume/mark','完成后固定奖励读取',BASE+'基础奖励已发，活动读取结果稳定为Gold8，缓存尚空。','缓存奖励并标完成，让后面的数量刷新不再把旧单改回可交付。','cache空→GetRewards=[Gold8]存入；state→Finished4；后续Slot.SetFinished复用非空缓存；读取返回DeepCopy。','订单显示完成，之后读到的仍是本次8金币奖励；此步不再发8金币，余额保持108。')
add(O+'consume/board','按格序消耗两件食物',BASE+'订单已标完成，奖励已发。','每项需求都从棋盘第一格重新找，删掉首件精确匹配物。','第1项扫描首命中(1,1)203→删；第2项重从(1,1)起首命中(2,1)203→删；第3项204棋盘无→交仓库；RemovedBoard键1=A、2=B。','棋盘两件203都消失，两个格空出；重复需求不会误用同一件棋子，Gold仍108。')
add(O+'consume/store','缺物才动仓库',BASE+'前两项203已在棋盘扣到，第三项204棋盘无。','只为尚未扣到的需求扫描仓库，删除首个匹配项。','第三项扫描store j1=204→RemoveItem(1)及属性删除；RemovedInventory[3]=204；storeCount1→0；缓存不扫描。','仓库的204被消耗，前两项不会再额外扣仓库203；三件需求合计只扣三件。')
add(O+'consume/refresh_failure','确认后第三件丢失',BASE+'玩家确认后、实际扣除前，仓库204已经不在；代码仍进入普通提交，金币已发。','每项刷新一次，缺物记录错误但继续，不撤回已发奖励。','第1/2项删203成功；第3项棋盘/仓库均无→LogError(FinishOrderRemoveItemError,204)；Count/Update各3次；RemovedInventory[3]缺省。','两件203消耗、订单仍完成、金币仍108；204缺失被记录，没有自动补物或退回奖励。')
add(O+'after/cooking','烹饪奖励优先帮助微笑缺口','假设Started且当前Buff有效，订单难度9命中[0,10]档、win_all=0；配置动态棋子槽Weight1、Diff范围[2,5]，另金币Weight1/Min2/Max2。扣本订单后其它微笑单缺203、普通单缺204，玩家10级、链母体均解锁；完整合法候选203/204分别Diff2/5；棋盘仅(4,9)可用。','先为棋子槽挑帮助对象，再抽奖类别；命中棋子类别后按缺口优先级选内部奖。','候选分组：微笑组[203]、普通组[204]、备用[203,204]；等权组内唯一→缓存code203/state微笑；类别权重棋子1/金币1，R1=1选棋子；内部权重1×10000=10000，R2=1选203；落点(4,9)，缓存本次结果。','扣物后额外在棋盘生成一件203，优先帮助剩余微笑订单；本次没有领取那份2金币候选奖励。')
add(O+'after/cooking','全奖模式含棋子与货币','同一有效Buff改win_all=1；假设仅固定棋子204 Min=Max=2、金币Min=Max=3；扣物后有两个合法空格(4,9)/(5,9)，Gold108。','全奖模式不抽类别，逐份生成固定棋子并发货币。','固定棋子ceil(Random(2,2))=2，占两格；金币ceil(Random(3,3))=3；Gold108+3=111；结果深拷贝保存。','棋盘多两件204，金币余额111；全奖模式同时得到配置中的两种奖励。')
add(O+'after/chest_delay','预算允许最后一件超支','假设宝箱活动Started，旧槽1仍有难度9的订单且被认作宝箱槽；延迟标记合法；预算档覆盖难度9、固定预算5，无重叠档；orderPool匹配的唯一方案weight1、rewards=[203-cost3]；奖励时只有1个空格。','通知宝箱完成，再把标记换成预算，重复抽物直到预算耗尽，不能把标记当一件奖励。','预算5→唯一方案；等权抽203一次成本3，余2>0→再抽203余−1≤0停；展开[203,203]；首件落盘、第二件交缓存，保存innerType_slot展开数组。','共获得两件203，一件在棋盘、一件在缓存；预算虽是5，最后一件允许跨过预算边界。')
add(O+'refill/owner_history','普通单取得下一次Lucky资格',BASE+'假设所属模型ContainsOrder=true，该类型LuckyTriggerChance=0.25，无重复链衰减字段。','完成历史先更新难度，再独立判定下一次Lucky订单资格。','u=0.2≤0.25→m_canTriggerLucky=true；TotalDiff100+9=109；低阶需求无RepeatWeightDecrease，不reset。','累计难度变109，本次拿到下一次Lucky订单尝试资格；不等于下一单必定创建成功，还要满足槽位和冷却。')
add(O+'refill/loop','补位成功再扫描一轮','假设19槽中只有槽1为Finished、槽2为空，其它槽有有效订单；本次槽1创建失败且无永久可创建分支，槽2创建成功为需求503单。','扫描空槽，保存成功新单；本轮有成功就再扫描一次。','轮1移除槽1旧单，槽1nil；槽2成功→DBAdd一次；轮2槽1仍失败、其余已占→hasFilled=false停止；更新状态并派OrderFinished。','槽2出现需求503的新顾客，槽1暂时空着；本次没有无限尝试，也没有重复保存槽2订单。')
add(O+'refill/priority','固定单先于随机单','假设槽1空，固定进度0，下一条Id1允许槽1、UnlockLevel1，玩家10；配置需求203、头像6。其它创建器即使有资格也不再调用。','按优先级固定单第一个成功，停止后续创建器。','Fixed.Create：10≥1且槽1匹配→进度写1，构造需求[203]；Return/Tutorial/Conti/Extra/Lucky/Random Create次数均0。','槽1出现固定需求203的新顾客；不消耗普通随机创建次数，也没有额外Lucky需求。')
add(O+'refill/fixed_return','预设需求创建固定单','假设固定进度0、玩家10、空槽1；下一记录Id1、Slots[1]、UnlockLevel1、Requirement1=203，后两项nil。','固定单看下一进度和资格，需求照表保留。','next=0+1=1；slot1∈[1]、10≥1→写CurrentFixedOrderId1；需求数组[203]，创建Fixed。','新顾客只要一件203，固定进度推进到1；没有随机挑需求。')
add(O+'refill/fixed_return','回归八小时后免费单','固定未创建；槽1空，回归开放且在奖励期，旧timer1000、now29800；棋盘最高不超过7级的物品为同级207/507各1，另有8级208，记录候选序207/507。','计时达到八小时后，从允许等级的最高现存物中等权选需求。','29800−1000=28800≥28800→timer写0允许；跳过8级，取7级list[207,507]；R=2→507；假设随机槽timer0，则置29800；创建单需求[507]。','出现只要一件507的回归免费订单；507仍在棋盘，本步只是创建需求，尚未扣物。')
add(O+'refill/tutorial','预设教程需求触发','固定/回归未创建；假设教程记录id1、Slot1、UnlockItem201已解锁、SkipItem202未解锁、需求203、头像6；当前存档1_1。','教程仍需要做且母体已解锁，先写进行中再创建。','Ready1且槽匹配→CanCreate=true；Create写1_2，创建innerType11/Id1/需求[203]；完成后同槽OrderFinished消息→2_1。','槽1出现要求203的教程订单；交付完成后进入下一教程待创建状态，不使用普通随机点数。')
add(O+'refill/continuous','三项连续订单','槽18空，假设活动Started、GetStarted=true、index1/Total3、主窗关闭、flag=true；本轮三项range分别[3,3]、[3,3]、[3,3]；玩家10，母体已解锁，逐轮主池分别仅203/503/903，权重100，无重复链减权。','前一项成功才挑下一项，按本轮档位逐个抽，不另抽项数。','每项唯一候选，R1=R2=R3=1→203/503/903；alreadyRequired逐次追加；UpdateMapInfo；创建槽18、Id1、innerType20、avatar2001、Luckyfalse。','连续顾客要求203、503、903三件；三项来自活动档位，没有普通随机订单的一二三项轮盘。')
add(O+'refill/extra','创建额外顾客入口','槽19空，活动Started，now1001、eTime5000、coolDown1000，HasActiveOrder=false；其它创建器在本槽未创建。','剩余活动时间和冷却都允许，保存入口标记后创建空需求顾客。','5000−1001=3999≥3600、1001>1000；Active/Banner/AutoPop/FirstAppear均设true，删冷却和LimitTime；EmptyReqOrder19/inner21/avatar3001；Dormant且CanDeliver=false。','出现额外顾客入口和提示，当前没有可交付需求；不会因需求为空而立即发奖。')
add(O+'refill/extra','入口刷新无候选的兜底','沿用上个入口，假设TryRefreshMyRequirements调用普通构造返回nil，调用者未传defaultReq。','普通需求构造失败后使用入口专用兜底物，再更新原入口。','newOrder=nil→defaultReq or Flour12=212；UpdateRequirements([212])并记refresh日志和错误；保留原入口对象。','该顾客改为要求一件212；当前只刷新需求，没有凭刷新发奖励。')
add(O+'refill/lucky','库存支持两次同物需求','槽17空且触发资格true；假设Lucky配置等级门槛1、当前points3、玩家10、首匹配档三个等级范围均[3,3]，ItemAmounts=(0,100,0)，库存棋盘+仓库203共2件、缓存另5件不计，无其它订单占203，203 Weight100。','消耗触发资格，通过次数门槛后从库存池抽两项，同一代码按实际件数扣后续可用份数。','CloseTriggerLucky；points3>1；三个池均203 CurNum2，项数池Count2权重100，R=1→2项；首抽203→池2/3 CurNum1；第二抽203→池3 CurNum0移除；成功points3−1=2。','新Lucky订单需要两件203，现有两件足够；连续次数剩2，缓存中的五件不让需求超量。')
add(O+'refill/lucky','最后一点先进入冷却','触发资格true、槽17空、配置与等级有效，points1、now1000、RefreshTime3600。','最后一点不是再生成一单，而是写入冷却并拒绝本次Lucky创建。','入口资格先消耗；points==1→points0、timer1000、returnfalse；now4600时0点且1000+3600≤4600恢复创建资格；假设后续唯一203库存1、项数1、Point3→成功后points3。','这一次不会出现Lucky顾客；一小时后再次取得触发资格并满足库存条件时，可创建203单需求Lucky订单，新批次3点。')
add(O+'refill/random_gate','随机次数耗尽与恢复','空槽4使用Random3；假设等级10≥门槛3、Point5、Refresh3600，timer0、points1，无强制补单资格。','资格通过立即扣一次；下一次耗尽启动冷却，到期恢复本批次数。','首次1→0保存、CanCreate=true；下一次timer0/points0→timer1000并false；now4600到期→points5、timer0，再扣1→4并true。','本次允许尝试创建随机单；额度耗尽后等待一小时，到期第一次尝试后还剩4次，不保证构造一定成功。')
add(O+'refill/candidates','库存和需求决定倍率','假设槽4、玩家30、所有候选母体/前一级解锁，未被槽位禁止、无上单或其它单代码冲突；候选均原Weight100、WeightMultiple1、无重复链衰减。链A有需求且库存足够；链B无需求也无库存；链C无需求但第3/4级各有一件库存，候选第5级；动态权重开。','先判断链是否缺订单物，再根据已有低阶库存提高适合继续合成的候选权重。','A倍率100→100×100=10000；B倍率1000→100000；C有两种低阶等级，code倍率10000×10²=1000000→Weight100000000；记录候选顺序A/B/C及总100110000；R=100110000→C。','本次抽到链C第5级需求，鼓励利用现有第3、4级库存继续合成；这些是权重差异，并非直接百分比。')
add(O+'refill/dynamic','富余高阶库存抬高难度','假设槽4、玩家30、累计难度109、月付费0，唯一Filter覆盖等级[1,40]/Diff[0,200]/付费[0,100]；普通上限6、动态9；链A第7级库存2/其它需求1，链B无富余；候选A第8级基础权重100，进度、解锁及其它检查均通过。','先选过滤档，有严格富余的高阶物才抬高对应链上限并增强下一等级权重。','Filter首条命中；A surplus2−1=1>0且6<7<9→maxA8，A8 Weight100×50=5000；B max6；A8通过范围，B8被排除。','新单可以要求链A第8级，帮助使用剩余高阶库存；链B仍只出常规上限内需求。')
add(O+'refill/draw','先抽三项再保留两项','假设随机槽4前三轮完整合法池分别仅203/503/903，各Weight100；无重复链减权和已有需求冲突；ItemAmounts=(50,50,0)，玩家等级档有效，记录抽样顺序。','先预选三个物品，之后再决定保留几项。','R1/R2/R3均1→203/503/903；项数总100、R4=75→Count2；需求取前2=[203,503]；第三次选链记录仍交UpdateMapInfo保存。','顾客最终只要203和503；903虽然未显示为需求，第三次预选仍实际发生并可影响选择历史。')
add(O+'refill/save','保存与重载保持同一需求','旧槽4类型3/avatar6/Id42/需求203;203;204；假设新单类型3/avatar7/Id43/需求203;503、Lucky=false、baseline=false、无DiffRange或礼物。','移除旧记录并存历史，新单保存字段；重载按字段恢复，不重抽。','历史lastfinishorder_4=3@6@42@203;203;204；DBAdd记录槽4/type3/avatar7/id43/requirementStr203;503，清旧特殊标记；DBGet恢复同需求数组。','重开后槽4仍是要求203和503的同一订单，旧单两个203的重复记录也保留；不会重开变成另一份需求。')
add(O+'finish/sync','首轮提示与完成消息',BASE+'已完成发奖和扣物，补位返回；本例首个普通微笑资格true，奖励快照Gold8，扣物来自棋盘索引1/2和仓库索引3。','先处理所属模型全局完成通知，再刷新、发首轮提示、检查同步，最后交视图。','OrderFinished→UpdateOrderState→SmileOrderDeliver_1→CheckMoreUpload(nil,nil,[203,203,204])→局部FinishOrder；payload Gold8/RemovedBoard1,2/Inventory3。','金币108、三件物品已扣；玩家看到首轮微笑提示，随后进入交付表现，同步检查不会再发8金币。')
add(O+'finish/animation','材料飞入后顾客离开',BASE+'结算完成，Gold108；假设无额外表现奖励、无烹饪或宝箱，顾客离开自定义时长缺省。','先播放三件材料飞入，再展示已到账金币，最后移除顾客并恢复滚动。','棋盘键1/2和仓库键3各飞向对应需求；等待0.5→金币View8→等待0.5→Leave→缺省等待1→RemoveCell/开滚动；实际飞行辅助时长独立。','看到两件203和仓库204依次完成需求，8金币飞入后顾客离开；余额保持108，不会变116。')

def digest(data): return hashlib.sha256(data).hexdigest()
def prefix(text):
    match=re.search(r'(?m)^## 贯穿案例[^\n]*|^## 演示案例[^\n]*',text)
    if not match: raise ValueError('Missing example anchor')
    return text[:match.start()]

def render_scenario(c,detail,number):
    text=f"\n### 场景{number}：{c['title']}\n\n"
    if detail:
        text+='**完整输入（演示设定）：** '+c['conditions']+'\n\n'
        text+='**按执行顺序代入：** '+c['calculation']+'\n\n'
    else:
        # Conditions with variables, formulas and config identifiers live in layer four.
        text+='**本例情境：** '+c['context']+'\n\n'
        text+='**判断与目的：** '+c['logic']+'\n\n'
    text+='**玩家看到的结果：** '+c['result']+'\n'
    return text

def main():
    AUDIT.mkdir(parents=True,exist_ok=True)
    paths=[p for op in ('merge','orders') for p in sorted((DOCS/'operations'/op).rglob('*.md'))]
    leafs={str(p.parent.relative_to(DOCS/'operations')).replace('\\','/') for p in paths if p.name=='detail.md'}
    missing=leafs-set(CASES)
    if missing:raise RuntimeError('Uncovered mechanisms: '+str(missing))
    unused=set(CASES)-leafs
    if unused:raise RuntimeError('Unknown mechanisms: '+str(unused))
    # Capture whole-site hashes before the first mutation; never replace this original snapshot.
    snapshot=AUDIT/'before'
    snapshot.mkdir(exist_ok=True)
    all_before={str(p.relative_to(SITE)):digest(p.read_bytes()) for p in SITE.rglob('*') if p.is_file() and ('docs' in p.relative_to(SITE).parts or p.name=='mkdocs.yml')}
    records=[]
    for p in paths:
        old=p.read_text(encoding='utf-8');start=prefix(old)
        rel=p.relative_to(DOCS/'operations')
        node=str(p.parent.relative_to(DOCS/'operations')).replace('\\','/')
        relevant=[(k,v) for k,v in CASES.items() if k==node or k.startswith(node+'/')]
        assert relevant,(p,node)
        detail=p.name=='detail.md'
        body='## 演示案例\n\n'
        if len(relevant)>1 or sum(len(v) for _,v in relevant)>1:
            body+='下面分别改变前提，让各条分支实际发生；互斥结果属于不同场景。\n'
        else:
            body+='本例设定本机制所需条件，演示它实际触发后的结果。\n'
        # Retain only existing small images that match the local examples, never multiply parent-page montages.
        if len(relevant)==1:
            art=re.search(r'<div class="case-assets">.*?</div>',old,re.S)
            if art:body+='\n'+art.group(0)+'\n'
        counter=0; ids=[]
        root_page=node in ('merge','orders')
        if root_page:
            body+='\n### 主流程代表场景\n\n'
            if node=='merge':
                body+='玩家把普通201拖到另一件201：落点与源对象有效，特殊道具没有接管，两件食物可以升级，于是在目标格生成202，源格空出。随后按顺序检查竞速和各类副产物，最后检查金币并结束拖动。普通移动、存仓、剪刀、吞噬和交换分别属于改变前提后的独立路径。\n\n'
            else:
                body+='订单需要两件203和一件204：棋盘已有两件203，缺的204在仓库。玩家确认补交后先领取8金币，再消耗三件材料；完成历史更新，尝试补新顾客，最后播放交付动画。金币从100变108，能量仍10。活动、特殊任务和各类补位在对应条件下分别触发。\n\n'
            body+='<details><summary>展开各分支的触发场景与具体结果</summary>\n'
        for key,scenarios in relevant:
            for c in scenarios:
                counter+=1;ids.append(key+'::'+c['title'])
                if root_page:
                    body+=f'<h3>场景{counter}：{html.escape(c["title"])}</h3><p><strong>本例情境：</strong>{html.escape(c["context"])}</p><p><strong>判断与目的：</strong>{html.escape(c["logic"])}</p><p><strong>玩家看到的结果：</strong>{html.escape(c["result"])}</p>\n'
                else:body+=render_scenario(c,detail,counter)
        if root_page:body+='\n</details>\n'
        dest=snapshot/rel;dest.parent.mkdir(parents=True,exist_ok=True)
        if dest.exists():assert prefix(dest.read_text(encoding='utf-8'))==start,(p,'Spec changed since snapshot')
        else:shutil.copy2(p,dest)
        p.write_text(start+body,encoding='utf-8')
        assert prefix(p.read_text(encoding='utf-8'))==start
        records.append(dict(page=str(p.relative_to(SITE)),level=4 if detail else len(rel.parts),mechanisms=[k for k,_ in relevant],scenarios=ids,prefix_sha256=digest(start.encode())))
    allowed={r['page'] for r in records}
    all_after={str(p.relative_to(SITE)):digest(p.read_bytes()) for p in SITE.rglob('*') if p.is_file() and ('docs' in p.relative_to(SITE).parts or p.name=='mkdocs.yml')}
    changed={p for p,h in all_before.items() if all_after.get(p)!=h}
    assert set(all_before)==set(all_after)
    assert changed<=allowed,changed-allowed
    data=dict(mechanisms=len(leafs),scenarios=sum(map(len,CASES.values())),pages=len(records),scope='Example sections only; no source or configuration changes',checks={'every_mechanism_has_active_scenario':True,'every_page_has_example':True,'body_prefixes_unchanged':True,'navigation_and_configuration_unchanged':True,'cross_layer_scenario_results_identical_by_shared_data':True},cases=CASES,pages_index=records,changed=sorted(changed),limits='Checks establish documentary scenario coverage, not execution equivalence. G1–G7 retain existing status.')
    (AUDIT/'scenario_ledger.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({k:data[k] for k in ('mechanisms','scenarios','pages','checks')},ensure_ascii=False))

# Correct control-flow specifics; demonstration inputs do not change these original rules.
CASES[M+'special/scissors'][0]['calculation']='RemoveItem(source)→RemoveItem(target)→在T生成target.Type新剪刀；初始化默认次数1，SetSplitUseCount(3+2=5)覆盖并保存；局部MergeItem/全局ItemMerged，scissor日志5。没有保留原目标对象。'
CASES[O+'rewards/activity'][1]['conditions']='限时订单内部类型TimedOrder，价格8、难度9；假设GetTimedOrderRewards存在且含相册缓存标记，Album开放，其它直接活动奖励为空。'
CASES[O+'rewards/activity'][1]['logic']='限时订单发现相册标记后跳过普通相册追加，避免重复。'
CASES[O+'entry/special_window'][0]['conditions']+=' 本例采用特殊任务Id1配置，宝石20、能量10，清链与奖励输入同特殊任务场景。'
CASES[O+'entry/special_window'][0]['result']='首次点击只看到任务物聚拢；第二次点击完成任务1，按任务表领15宝石和100能量，余额变35宝石、110能量。'

add(M+'normal/temp','旧模式高级库存阈值触发','沿用旧规则场景，但Advanced开启；订单缺205，Rule[205]=[203,204]，本链合成后仅202一件。','高级模式把现有库存折算后确认不足，仍为订单生成帮助物。','205等级5→阈值floor(2^(5−3))=4；仅202一件折算2<4通过；Rule首203等级3>合成等级2→选203；保存目标与开始时间，S落Temp203。','202旁出现临时203，帮助继续制作205；高级库存规则通过后仍沿用旧模式的规则列表选物。')
add(M+'normal/bubble','概率衰减后的最低机会','沿用三种衰减场景，只把演示基础概率改3。','各项衰减压低机会后保留最低机会，本次抽中最低档。','3×0.5×0.25×0.8=0.3；max(0.3,1)=1；R=1≤1→204气泡落S。','得到204和一枚204气泡；机会很低但没有降为完全不可能，不改变已有高阶气泡。')
add(M+'normal/bubble','测试开关强制出气泡','假设测试模式TestBubbleMustSpread=1，201合成202；基础BubbleChance0，功能关闭，但有空格S。','测试开关在普通规则之后强制命中；仍受最早的满盘返回约束。','最早非满盘通过；普通功能关不读概率；测试覆盖p100；R=99≤100→生成202气泡；若满盘则测试覆盖前return。','测试场景额外出现202气泡；这是调试强制效果，普通玩家基础概率为零的合成不会因此出气泡。')
add(O+'rewards/price','烘焙代币替代金币',BASE+'金币Buff关闭；假设BakeOut.CanAcquireToken=true，烘焙代币初始5。','基础奖励类型改为烘焙代币，数量仍按订单价格结算。','GetFirstRewardPropertyType=BakeOutToken；ceil(8×1)=8；BakeOut5+8=13，Gold不Acquire仍100。','获得8个烘焙代币，代币变13；这份基础奖励不会同时再发8金币。')
add(O+'rewards/price','亲密度随机单不发基础金币',BASE+'改CharacterIntimacyRandom且亲密度开放；假设独立giftRewards=[Energy5]，活动其它奖励为空。','该类订单关闭基础金币奖励，仍可按独立礼物流程发奖励。','_HasGoldReward=false→不追加Gold；gift非nil且IsOpen=true→Energy10+5=15；Gold保持100。','本单不发基础金币；礼物提供5能量，能量变15，避免误认为没有金币就没有任何收益。')
for label,call,count in [('向上活动','Upward',3),('道路活动','Road',4),('敲砖活动','HitBricks',2),('环活动','Ring',1),('连击活动','Combo',2),('通用活动模块','ActivityModule',3)]:
    add(O+'rewards/activity',label+'实际追加奖励',BASE+f'本例独立开启{label}并满足其活动资格；假设对应接口给出合法活动奖励{count}份，其类型由活动实际返回，旧计数5；其它活动奖励为空。',f'执行到{label}的收集位置，该活动有奖便追加，末尾继续加入基础金币。',f'{call}有效返回{count}；'+('HitBricks先资格调用为真，再取奖调用，假设两次结果稳定；' if call=='HitBricks' else '')+f'奖励列表=[该活动奖励{count},Gold8]；对应处理器计数5+{count}={5+count}，Gold100+8=108。',f'收到{count}份{label}奖励，原来5份变{5+count}份；另得8金币，金币余额108。')
add(O+'rewards/activity','宝箱标记也实际追加',BASE+'假设宝箱活动识别槽1，延迟奖励预算与唯一203成本3方案同宝箱场景；本例奖励时只有一个空格，其它活动奖励为空。','收集时追加宝箱标记，金币即时发，标记在扣物后再展开。','rewards=[RewardKey+innerType+"_1" count1,Gold8]；分离并发Gold8→108；之后标记预算5，以cost3两次203使预算−1；一件落盘，一件缓存。','得到8金币；宝箱另外给两件203，一件落盘、一件缓存，标记本身不是一件棋子。')
add(O+'refill/candidates','冲突候选只在允许时进入备用','假设槽18连续订单，玩家30、所有母体解锁且等级/进度/槽位/正权重检查通过；仅候选203原权重100，与上一单需求冲突，无其它需求冲突；本项等级范围允许203。','主池排除与上一单冲突的代码；连续订单允许把仅因重复而失败的物品作为备用。','失败位仅LastOrder→主池[]、备用[203]；Conti允许保留备用；主空改用备用，sum100/R1→203。','连续顾客仍得到203需求，避免仅因上一单重复而没有订单；解锁或等级失败的物品不会获得同样兜底。')
add(O+'refill/draw','重复链减权及保存','假设本次前三项逐次唯一合法候选203/503/903；每轮基础权重100，三个链均有历史计数2且该候选RepeatWeightDecrease=10，项数池只有Count2权重100，候选顺序已记录。','历史重复链先减权，实际选中的链更新历史；最终只保留两项仍不撤销第三次预选。','每轮Weight=100/10=10，R1=1各选对应code；MarkSelectedLine对各已选链置false；CountR=1→2，需求203/503；UpdateMapInfo对三条被选中链均重置3并保存。','顾客只要203和503，但预选过的903链也记为最近选中；三条链的重复权重历史都更新。')

CONTEXT={
 'merge/release/movable':'玩家开始拖动一件未锁定的普通201。',
 'merge/release/position':'玩家松手时，本例的高亮吸附或教程限制正在参与落点判断。',
 'merge/release/inventory':'玩家把201拖到已开启且有空容量的仓库按钮。',
 'merge/release/identity':'拖动期间原201被同类型新对象替换，玩家仍在释放旧对象。',
 'merge/move/write':'玩家把201从原格拖到相邻空格。',
 'merge/move/accelerate':'玩家移动可受加速影响、仍在计时的母体到空格。',
 'merge/special/eligibility':'玩家用剪刀作用于允许拆分的202，棋盘有空格。',
 'merge/special/upgrade':'玩家把升级道具拖到202，并确认使用。',
 'merge/special/scissors':'玩家把一把剩两次的剪刀拖到另一把剩三次的剪刀上。',
 'merge/special/split':'玩家确认用只剩一次的剪刀拆分202。',
 'merge/special/failure':'升级道具遇到不可升级、但可移动且没有其它作用关系的目标。',
 'merge/normal/eligibility':'普通201被拖到网中201上，两者都有可用的下一等级关系。',
 'merge/normal/replacement':'两件普通201通过资格检查，准备合成。',
 'merge/normal/notify':'201合成202，目标周围还有三个有物品的正交邻格。',
 'merge/normal/score':'竞速已开放且玩家已入组，这次201合成202可计竞速分。',
 'merge/normal/temp':'临时物活动有效，资源与间隔满足，本次201合成202后，同链订单仍缺高阶食物。',
 'merge/normal/card':'卡片活动有效、备用入口符合资格，临时物未生成；这次201合成202有空位。',
 'merge/normal/energy':'能量偏低、购买价格符合活动档，触发等待已过；临时物和卡片未生成，棋盘有空位。',
 'merge/normal/bubble':'棋盘有空位，前三种副产物未生成；分别设定订单加成、普通衰减或测试强制条件。',
 'merge/normal/coin':'本次合成到第八级208，仍留有空格。',
 'merge/normal/finish':'201已合成202，本次没有额外副产物，进入结束处理。',
 'merge/swallow/target':'创建一个需要吞入食物的目标，并把201拖向它。',
 'merge/swallow/progress':'目标需要两件201，尚未吞入任何一件，玩家拖入第一件。',
 'merge/swallow/transform':'目标需要两件201，已吞一件；玩家拖入最后一件，变换奖励配置有效。',
 'merge/swap/blocked':'201拖到锁定的204，前面的特殊作用、合成和吞噬都不能接管。',
 'merge/swap/exchange':'可移动的201拖到可移动的204，两者没有合成或其它作用关系。',
 'merge/pointer/selection':'201合成202后，原拖动对象已被删除，界面准备结束拖动。',
 'orders/entry/button':'普通订单按钮已开启，棋盘缺的一件204可以从仓库补交。',
 'orders/entry/counts':'棋盘有两件203，仓库和缓存都有204，订单需要两件203和一件204。',
 'orders/entry/requirements':'棋盘只有一件203，订单却需要两件203和一件204。',
 'orders/entry/inventory':'玩家确认使用仓库的204补交，关闭期间订单和材料均未变化。',
 'orders/entry/special_window':'任务1的需求物展示已准备完成，玩家再次点击窗口。',
 'orders/dispatch/type':'分别把本次订单设为普通订单、特殊任务或分支任务。',
 'orders/dispatch/special':'玩家交付任务1，任务要求清理的物品分布在棋盘、仓库和缓存。',
 'orders/dispatch/branch':'玩家完成槽7的分支任务，六件奖励要发完，但棋盘只有两个空格。',
 'orders/rewards/price':'订单物为203两件和204一件，分别改变金币Buff、基准单或奖励类型条件。',
 'orders/rewards/activity':'本场景专门满足所述活动的领奖条件，并提供它本次返回的奖励。',
 'orders/rewards/snapshot':'本次奖励同时包含8金币和一个合法宝箱顾客标记。',
 'orders/rewards/acquire':'本次奖励包含8金币和两件204，缓存原为空。',
 'orders/rewards/gift_buff':'亲密度已开放，本单礼物给3金币，另有Buff给5能量。',
 'orders/rewards/smile':'普通槽1进入微笑活动首轮，本次可加一份微笑进度。',
 'orders/consume/mark':'8金币已发，订单尚未开始扣物，准备写完成状态。',
 'orders/consume/board':'订单已完成，按两件203和一件204的顺序开始扣物。',
 'orders/consume/store':'两件203已从棋盘扣到，最后一件204只在仓库。',
 'orders/consume/refresh_failure':'玩家确认后仓库204消失，但结算仍已发8金币。',
 'orders/after/cooking':'烹饪Buff有效且命中订单难度档，扣物后有可用空格；分别演示抽奖与全奖。',
 'orders/after/chest_delay':'宝箱活动有效，旧订单仍可取到；预算五份、每件203成本三份，棋盘一个空格。',
 'orders/refill/owner_history':'普通订单属于本模型，本例配置给下一单Lucky触发机会。',
 'orders/refill/loop':'槽1旧单已完成，槽2为空；本轮只有槽2能成功建单。',
 'orders/refill/priority':'槽1符合下一条固定订单资格，其它随机建单不能抢先。',
 'orders/refill/fixed_return':'分别演示固定进度达标，以及回归奖励期等待八小时后的免费单。',
 'orders/refill/tutorial':'当前教程待创建，要求母体已解锁、教程尚不能跳过，预设需求为203。',
 'orders/refill/continuous':'连续订单活动有效、窗口已关闭，本轮配置三个需求范围且每项都有合法候选。',
 'orders/refill/extra':'额外顾客活动还有足够时间、冷却已过，槽19没有顾客。',
 'orders/refill/lucky':'分别演示有资格且库存够用的Lucky建单，以及次数耗尽进入冷却。',
 'orders/refill/random_gate':'槽4的随机创建额度只剩一次，本例没有活动强制补单。',
 'orders/refill/candidates':'候选的解锁、等级和槽位有效；分别设定库存/需求修正及连续订单备用条件。',
 'orders/refill/dynamic':'玩家档位有效；一条链已有严格富余的第七级库存，另一条链没有。',
 'orders/refill/draw':'前三轮分别有203、503、903候选；演示最终只保留两项及重复链历史更新。',
 'orders/refill/save':'槽4旧单移除，新顾客要求203和503，随后重开恢复。',
 'orders/finish/sync':'三件材料已扣、8金币已发，本单符合首次微笑提示条件。',
 'orders/finish/animation':'结算已完成，两件棋盘203和一件仓库204准备播放飞入表现。',
}
add(O+'after/chest_delay','缺口整单容差补齐','假设宝箱有效、定向方案已选，预算5；唯一未完成订单需求203、204，棋盘和仓库均没有这两种物，Diff203=2/204=5，缓存不计；至少两个空格(1,1)/(2,1)。','预算接近整张订单所缺难度时，允许小幅超预算，直接给齐缺口。','缺口=[203,204]、总分2+5=7；5+10≥7→全发203/204；余预算5−7=−2停止，不进入降阶或五级补余；扩散扫描两件分别放(1,1)/(2,1)。','棋盘多一件203和一件204，把这张订单的缺口全部补齐；预算允许超出两份。')
add(O+'after/chest_delay','高难度缺口用旧降阶算法','宝箱有效、定向方案预算30；唯一未完成订单缺209一件，棋盘/仓库本链库存空。按默认表209难度146，208=78、207=39、206=19；applyOptimization=false，有两个空格(1,1)/(2,1)。','整件目标远超预算，沿同链降到较便宜等级，按预算向上取整发帮助物。','30+10<146，30<146；依次降209/208/207仍>21，首206=19≤21；ceil(30/19)=2→206×2；预算30−19−19=−8，不进入补余；两件落两个空格。','棋盘获得两件206，帮助继续合成209；没有直接发出209，末件仍允许超预算。')
add(O+'after/chest_delay','库存优化停止定向后用余款补奖','宝箱有效、定向方案预算30；唯一未完成订单缺209一件；本链库存208/207/206/205各一，等价为128+64+32+16=240，209需256。优化与RewardStockCount开启；仅链2母体解锁、玩家10，五级合法候选仅205、难度10；有三个空格(1,1)/(2,1)/(3,1)。','考虑现有低阶合成库存，只补尚缺的等价份额，再把余款转为普通五级奖励。','30+10<146，降到206成本19；等价缺口256−240=16>0→发206一件、扣32份额→−16，预算30−19=11；定向停止；余款从唯一205等权抽两次，11−10=1、1−10=−9；结果[206,205,205]依次落三个空格。','棋盘额外获得一件206和两件205；定向补缺没有继续重复发206，剩余预算仍作为普通奖励用完。')
CASES[M+'normal/score'][1]['result']='202正常生成，竞速达到10分目标，启动达标界面流程。'
CASES[M+'swap/exchange'][0]['result']='201和204互换位置，物品总数不变、能量仍10；不生成新物，也不发空格移动专用的结束通知。'
for key,scenes in CASES.items():
    if key.startswith('merge/'):
        for c in scenes:c['conditions']='未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。'+c['conditions']
for c in CASES[M+'normal/temp']:
    c['conditions']+=' 本轮旧TargetType=nil，无教程强制计时；假设Duration[203]=60秒，落点仅S为空。'
    c['calculation']+=' StartTimer1000，本例当前时刻1000，elapsed=0，计时0/60；临时203开始60秒存在期。'
    c['result']+=' 本例临时物开始一分钟倒计时。'
CASES[O+'after/chest_delay'][0]['conditions']+=' 本例唯一空位为(1,1)，缓存原为空；方案随机签与两次物品随机签均取1。'
CASES[O+'after/chest_delay'][0]['calculation']+=' 首件位置(1,1)，缓存从空变[203]。'
CASES[O+'refill/lucky'][1]['calculation']='入口资格先消耗；points==1→points0、timer1000、returnfalse；now4600重新取得触发资格后，0点且1000+3600≤4600允许；假设后三池只有203且库存1、ItemAmounts=(100,0,0)、每次签1、Point3→建一项203，成功后points3。'
for key,scenes in CASES.items():
    for c in scenes:c['context']=CONTEXT[key]
for c in CASES[M+'normal/temp']:c['calculation']+=' 本例临时实体代码t#203。'
CASES[M+'normal/card'][0]['calculation']+=' 一级实体代码main_card_item_energy_s_1。'
CASES[M+'normal/energy'][0]['calculation']+=' 代入原前缀prb#和energy，实体Code=prb#energy-100-30。'
for c in CASES[M+'normal/bubble']:
    c['calculation']+=' '+('202气泡实体代码3000202。' if '测试' in c['title'] else '204气泡实体代码3000204。')

if __name__=='__main__':main()

