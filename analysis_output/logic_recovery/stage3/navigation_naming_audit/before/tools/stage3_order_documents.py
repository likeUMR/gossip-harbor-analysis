"""Scoped order delivery documentation. Never regenerates generator/merge pages."""
from pathlib import Path
import json, re, shutil, html, os
import yaml
from lupa.lua53 import LuaRuntime, lua_type
from stage3_merge_documents import ROOT, SITE, DOCS, BY_NAME, source, sha, link, html_link

BASE=DOCS/'operations/orders'
AUDIT=ROOT/'analysis_output/logic_recovery/stage3/order_gate_audit'
ASSETS=DOCS/'assets/order-evidence'
STEPS=[]
B='Board.Model.Board.MainBoardModel'
O='Board.Model.Order.MainOrder'
M='Board.Model.Order.MainOrderModel'
R='Board.Model.Order.MainOrderCreatorRandom'
C='Board.Model.Order.MainOrderCreator'
S='Board.Model.Order.SlotOrderModel'
BO='Board.Model.Order.BaseOrder'
V='Board.View.MainBoardView'
PREMISE='本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。'

def stage(key,title,overview,case):
    s=dict(key=key,title=title,overview=overview,case=case,nodes=[]);STEPS.append(s);return s

def node(s,key,title,overview,detail,case,calc,modules,configs=(),methods=(),icons=()):
    s['nodes'].append(dict(key=key,title=title,overview=overview,detail=detail,case=case,calc=calc,
                           modules=list(dict.fromkeys(modules)),configs=configs,methods=methods,icons=icons))

def define():
    s=stage('entry','点击交付：检查按钮、需求与确认分流',
      '先检查按钮是否禁用。普通订单读取棋盘中的可用代码数量，逐项核对需求；全部够用才直接提交，缺少时先询问是否使用仓库。特殊订单按钮另走展示窗口，玩家再次点击后才提交。这里的确认尚未发奖、扣物或补位。',
      '棋盘有两件203，却没有204，所以直接交付检查失败；窗口展示缺少一件204，玩家确认使用仓库后才进入提交。')
    node(s,'button','按钮门控与入口差异','按钮禁用便结束；普通订单进入数量检查，特殊订单先展示需求。音效在门控之后播放，不能把音效当作交付成功。',
      'BaseOrderCell.OnGoButtonClicked只在m_bGoButtonEnabled恰为false时return；nil不等同false。随后播放sfxOrderServe，取得所在BoardView模型，检查CanDeliver。SpecialOrderCell覆盖入口，门控和音效相同，却直接打开SpecialOrderItemWindow，不做普通入口的数量判断。订单状态控制按钮显示属于点击之前的资格来源，不是模型内部第二次校验。',
      '本例按钮开启，播放服务音效，进入普通需求检查。','m_bGoButtonEnabled=true；对照false：无音效、无计数、无窗口、无FinishOrder。',
      ['Board.View.Order.BaseOrderCell','Board.View.Order.MainOrderCell'],methods=['OnGoButtonClicked'])
    node(s,'counts','首次计数只看棋盘','首次判断不含仓库和缓存。它回答“能否直接从棋盘交付”，不是判断所有持有物是否足够。包装物要按实际代码计数，不能把内含类型当裸物品。',
      '入口GetCodeCountMap(true,false,false)：BaseBoardModel复制棋盘m_itemCodeCount；BaseActionBoardModel仅includeCache~=false才加入缓存；MainBoardModel仅includeStore~=false才加入仓库。这三个布尔值分别是棋盘、缓存、仓库。需求以GetCode精确匹配；气泡/网/临时包装代码不自动等于内含203。用于日常UpdateOrderState的计数路径与此次按钮传参应分别追踪，不能用UI状态替代入口真实计数。',
      '读到203有2件、204不存在；仓库那件204此时不计。','入口map={203:2}；合并仓库才是{203:2,204:1}；缓存即使有204也不进入后续扣除兜底。',
      [B,'Board.Model.Board.BaseBoardModel','Board.Model.Board.BaseActionBoardModel'],methods=['GetCodeCountMap'],icons=('203','204'))
    node(s,'requirements','重复需求按件数检查','逐项核对，同一种物品出现两次就需要两件。失败返回每种代码的缺口，窗口据此展示需要动用哪些仓库物。空需求会通过本方法，不能只依靠方法名假设它必定拒绝。',
      'BaseOrder.Init跳过空字符串并保留需求顺序。CanDeliver对第i项从i−1向1数同code项，count从1开始；map不存在或count>map[code]就把canDeliver置false，缺口写count−(map[code] or 0)。同code后面的失败项覆盖前值，最终得到总缺口；不中途return。空数组返回true,{}。UpdateState使用同一逐项计数更新fillStates；0需求Dormant=0，0项满足Init=1，部分PartiallyFinished=2，全部CanDeliver=3，Finished=4则不再更新。_SetState仅状态变化才写升降方向与服务器时间；SetFinished直接写Finished。',
      '两个203逐项通过，204缺1件；不是把重复203去重后判断。','需求[203,203,204]，各count=1,2,1；map[203]=2均通过，204为nil失败；lacked={204:1}。对照203只有1件，缺口还包含203:1。',
      [BO],methods=['Init','CanDeliver','UpdateState','_SetState'])
    node(s,'inventory','仓库确认与关闭后的提交','窗口重新算棋盘缺口并展示，确认只设置提交标记；真正提交在窗口关闭完成后。普通入口只检查订单还在不在槽位，没有再次核对库存，也不会先把仓库物移到棋盘。',
      'Init再次CanDeliver(GetCodeCountMap(true,false,false))，以pairs遍历缺口，每个count拆成count条{type=code,count=1}给rewardContent；不同code展示顺序不保证固定。可选listListeners逐个AddActiveListener到Close。红按钮仅Close；绿按钮m_bFinishOrder=true再Close。OnCloseFinish先BaseWindow.OnCloseFinish；标记非真不做提交，有callback则优先执行callback，否则GetOrderModel(Slot).ContainsOrder(order)才FinishOrder。普通按钮未传callback/listListeners。此处不再CanDeliver、不验证仓库数量；“订单仍在”也不等于“材料足够”。取消不扣物。窗口期间数量变化可能导致后续部分扣除失败，不能凭空增加原版事务保证。',
      '窗口显示204×1，确认后订单仍在槽1，于关闭完成回调提交；仓库204直到扣除阶段才删除。','缺口1→展示一条{type=204,count=1}；绿按钮finish=true；callback=nil、ContainsOrder=true→FinishOrder。对照订单已移出槽：不提交。',
      ['UI.Window.Board.UseInventoryItemConfirmWindow','Board.View.Order.BaseOrderCell'],methods=['Init','OnGreenClick','OnRedClick','OnCloseFinish'],icons=('204',))
    node(s,'special_window','特殊订单展示后的再次点击','特殊窗口先把最多三个需求图像聚到中央，动画初始化之后点击遮罩才提交。它先选独立棋盘对象，没有对象时用仓库图像表现；这一选择不是普通需求扣除算法。',
      'Init插入1秒回调置m_initialized=true并开效果；i=1..3按requirements[i]显隐。FilterItems过滤GetType==requirement且mapSelectedItem未选中，取第一件并隐藏原视图，1秒移动和缩放，多件放大2倍、单件3倍；1秒后循环上下摆动。没选到棋盘物时inventoryItemMap[i]=code并从仓库HUD位置显示图像，未实际校验仓库。遮罩点击在initialized未真时return；初始化后恢复仍存在的原视图位置/缩放，调用MainBoardModel.FinishOrder，随后按inventoryItemMap播放飞入订单表现并Close。没有再次CanDeliver，最多3个槽的展示不能泛化成任意需求数量。',
      '主例是普通订单，不打开特殊展示窗。对照改为特殊订单时，首次按钮点击仅展示，1秒初始化之后再次点遮罩才提交。','对照t<初始化回调：OnWindowMaskClicked直接return；回调后true→FinishOrder；展示对象集合避免同一实例重复被选择。',
      ['UI.Window.Order.SpecialOrderItemWindow'],methods=['Init','OnWindowMaskClicked'])

    s=stage('dispatch','进入模型：先分流特殊与分支订单',
      '进入FinishOrder后先按订单内部类型分流。特殊任务清理相关整条链并发配置奖励；分支任务清理链并把有限奖励池全部发完。这两条路径立即返回，普通订单才继续后面的价格、奖励、逐件扣除和补位顺序。',
      '本例为Random1，跳过特殊与分支分流，进入普通交付。')
    node(s,'type','内部类型决定执行路径','特殊与分支在普通奖励之前接管。订单对象的内部类型与用于显示/日志的Fixed、Random、Special大类不同，判断必须使用内部类型。',
      'MainBoardModel.FinishOrder：innerType==MainOrderType.Special(5)则_FinishSpecialOrder并return；elseif Branch(7)则_FinishBranchOrder并return；其余继续普通链。MainOrder.GetType把Fixed内部0映为OrderType.Fixed1，把5/7映为OrderType.Special3，其余映Random2。普通FinishOrder本身没有ContainsOrder或CanDeliver的前置保护；不能把后面槽位ContainsOrder当成发奖前的校验。',
      'Random1内部值1，走普通链。','innerType=1，≠5且≠7；对照5/7即返回，不执行普通奖励和逐项扣除。',
      [B,O,'Board.Model.Order.MainOrderDefinition'],methods=['FinishOrder','GetType'])
    node(s,'special','特殊任务：完成模型、清整链、发奖','先完成所属订单模型，再取当前特殊配置清理需求链和母体链。清理覆盖棋盘、仓库、缓存；气泡按内含物判断。然后发配置奖励、标记时间线并通知特殊完成。',
      '先Slot模型FinishOrder，再GetSpecialOrderConfig：Special取GetSpecialOrderConfigWithOffset(0)，并非用任意传入Id直接索引。Requirement1..3的链加入集合；GeneratorChain可为字符串或数组，IsInGeneratorChain按相等/逐项判断。itemFilter对Bubble用innerCode，其余GetType；缓存用typeFilter直接查code链。_BatchRemoveItems按有效格序RemoveItem(默认刷新)，仓库while索引删除后不自增以防跳过，删除持久化属性；缓存同样删后不自增；最后ChangeCachedItems→InventoryItemUpdate。返回Removed只有棋盘对象，不能据此以为仓库/缓存没有删除。之后UpdateOrderState→AcquireRewardsLogic(Rewards,Give,SpecialTaskComplete,Main,Type2)→MapData.SetSlot(EndTimeline,"1")→局部FinishSpecialOrder。默认特殊Id1需求1610，GeneratorChain15，奖励gem15/energy100。',
      '主例不走本分支。对照本地特殊Id1：提交后需求链和母体链被批量清理，获得15钻石、100能量。','对照Rewards=[gem-15,energy-100]，解析后两条货币记录；时间线special_order_1="1"。不调用普通GetPrice/GetOrderRewardByFinishOrder。',
      [B,M,C],configs=('OrderSpecialConfig',),methods=['_FinishSpecialOrder','_BatchRemoveItems','IsInGeneratorChain','GetSpecialOrderConfig'])
    node(s,'branch','分支任务：抽一份减一份直到耗尽','分支奖励的权重表示必须发出的份数，同时影响下一件出现概率。每次抽取减1，全部份数耗尽才结束；棋盘没有空位就进缓存。因此随机改变发放顺序，不改变最终配置总件数。',
      '先Slot.FinishOrder→按order.Slot查BranchConfig→按Requirement链/GeneratorChain批量清理（规则同特殊任务，棋盘/仓库/缓存都处理）。GetCodeAndWeightPairs把Rewards的code-count字符串转Code/Weight。while #pool~=0：ListWeightSelectOne取code→FindEmptyPositionInValidOrder→无位CacheItems({code},Type2)，有位GenerateItem并加入New→从前向后找首个相同code，Weight−1，恰为0才删除并break。没有全局持久池；本次临时池单位份额无放回，code可重复出现。结束写EndTimeline="1"，局部FinishBranchOrder携Order/Removed/New；New不含缓存件。默认Slot7池2402×2、2405×1、2502×2、2503×1，共6件；初次概率2/6、1/6、2/6、1/6。重复code配置、零/负权重不应假设自动归并或修复。',
      '主例不走分支。对照默认槽7，即使没有空位，6件奖励也会通过缓存全部发完。','假设首抽2402：份数2→1，总6→5，下次2402概率1/5；最终四类件数恒2、1、2、1。新建池下一次重新读取配置。',
      [B,'Board.Model.ItemModelFactory','Board.Model.Board.BaseBoardModel','Board.Model.Board.BaseItemLayerModel','Common.Utility.Table','Common.Utility.MathUtil'],configs=('OrderBranchConfig',),methods=['_FinishBranchOrder','GetCodeAndWeightPairs','ListWeightSelectOne','FindEmptyPositionInValidOrder'])

    s=stage('rewards','普通交付：算奖励并先发即时奖励',
      '普通链先按需求算价格与难度，再按活动资格收集奖励，分出延迟奖励并保存快照。随后发即时奖励、亲密度礼物与Buff奖励，处理订单微笑分数。此时材料尚未扣除，不能把发奖与扣物理解成一个不可分割的事务。',
      '价格为2+2+4=8，难度2+2+5=9；活动均不生效，只发8金币，余额100→108，棋子仍在原处。')
    node(s,'price','价格、难度与金币类型','价格和难度都逐项累加，重复需求重复计入。基准订单可使用推荐价格；金币Buff在最终价格上翻倍。BakeOut可把最后的基础奖励改成代币，亲密度随机订单可能没有这份基础奖励。',
      'GetPrice按requirements查OrderItem.Code；任一缺配置LogErrorInfo(cfg_err)并return0，之前累加不保留。baseline且RecommendedPrice非nil用推荐值，否则Price。GetDiffScore：Special直接0，其他逐项加非nil DiffScore；任一缺配置也返回0。GetRewards尾部_HasGoldReward：innerType≠CharacterIntimacyRandom或亲密度未开放才有基础奖励；BuffGold激活multiple2，否则1；count=ceil(price×multiple)，CryptCurrency(count)。GetFirstRewardPropertyType：非Special且BakeOut.CanAcquireToken→BakeOutToken，否则Gold。缺配置返回0不阻断普通链，也可能追加0数量基础奖励，不应自造拒绝条件。',
      '本例203×2和204×1给8金币、9难度分。','price=2+2+4=8，diff=2+2+5=9，multiple=1，ceil8=8；对照金币Buff→16。',
      [O],configs=('OrderItemConfig',),methods=['GetPrice','GetDiffScore','GetRewards','_HasGoldReward','GetFirstRewardPropertyType'],icons=('203','204','2401'))
    node(s,'activity','按顺序收集活动奖励','活动资格在本次读取时判断，按原调用顺序追加。限时订单提供的相册信息会影响普通相册奖励；宝箱顾客追加的是延迟领取标记。奖励列表顺序不等于分类处理器之间的执行顺序。',
      'GetRewards若Finished返回缓存DeepCopy，若Special返回空表。正常追加顺序：主装饰代币(Started对象且CanAddScore，数量>0)→FloatRace(CanAddScore且非nil)→TimedOrder检查GetTimedOrderRewards中是否含相册缓存奖励并设skipAlbumReward（这里没有把整份TimedRewards追加！）→未跳过时Album(IsActivityOpen)按diff/slot或orderType+innerType取包并复制，CanSupportAlbumBuff再×2；相册Buff还要求buff激活、非Timed/非Special且预览false调用结果非空→Avenue正分→Upward非nil→Road正分→HitBricks资格调用为真再调用一次取奖→Ring真→Combo真→ActivityModuleManager各模块GetRewardsByOrder返回非空数组追加→ChestCustomer槽追加RewardKey..innerType.."_"..slot,count1→基础金币/BakeOut。\n\nActivityModuleManager以pairs遍历注册模块，不保证跨模块固定顺序；各GetAddScoreByOrder内部资格/公式与远端档位属于具体活动，不能把“活动开启”当成必定有奖。这里完整给出订单直接收集顺序，各活动完整奖励闭包仍须依其代码和账号配置核销。',
      '本例所有活动资格关闭，所以不追加活动代币、相册包或宝箱标记；只留下末尾金币。','rewards=[{type=Gold,count=8}]；不是每项活动都获得1份。对照TimedRewards含相册包，仅导致skipAlbumReward=true，不自动证明此函数追加了限时奖励。',
      [O,'Model.Activity.ActivityModuleManager'],methods=['GetRewards','CanSupportAlbumBuff','GetRewardsByOrder'])
    node(s,'snapshot','即时与延迟奖励分离、冻结快照','根据宝箱顾客前缀拆分奖励，普通部分马上发，标记部分稍后发。两份都复制，确保完成消息展示的是提交时的结果。',
      'GetOrderRewardByFinishOrder遍历GetRewards，StringUtil.StartWith(type,ChestCustomerModel.RewardKey)为false进targetRewards，为true进otherMapReward[RewardKey]数组；按各组保留原顺序。MainBoardModel随后对rewards与mapDelayRewards分别DeepCopy。完成消息携这两份快照；gift/buff/cooking不是自动写进这份即时快照，而在各自调用位置处理。延迟映射后续以pairs逐组遍历，不能给不同组虚构固定顺序。',
      '8金币属于即时数组，延迟映射为空。','rewards=[Gold8]，mapDelayRewards={}；对照chest前缀标记从即时中移出，挂到RewardKey组。',
      [O,B],methods=['GetOrderRewardByFinishOrder','FinishOrder'])
    node(s,'acquire','奖励落账与棋子进入缓存','奖励逻辑先转换动态奖励，再按类别交给处理器。货币更新资源，普通棋子奖励进入缓存；这不是统一把所有奖励直接放到棋盘。逻辑落账与飞行动画分别执行。',
      'AcquireRewardsLogic空表return；单记录无[1]则包装数组，逐项ConvertDynamicReward，再SplitRewards按GetRewardCategoryType分组。_AcquireRewardsLogic取RewardHandlerManager.GetAllHandlers，以pairs遍历存在的handler，组非空才LogicHandle，参数source/scene/targetGameMode/cacheItemType/boardType。不同类别处理次序无保证，同组ipairs保留顺序。PropertyRewardCategoryHandler交PropertyDataManager.Acquire；ItemRewardCategoryHandler把每条count展开code数组，BoardModelHelper.GetModelByGameMode→CacheItems，逐条日志。普通FinishOrder首次调用Give/FinishOrder/gameMode/Type2。这里只有Logic，不调用AcquireRewardsInView；视图尾部才演出，不能再落账一次。各奖励子类别和PropertyDataManager真实持久化仍有独立实现边界，不能据此假设网络事务。',
      '本例Gold8交资源处理器，余额增至108；不生成棋盘金币棋子。','category=Property；count8；棋盘203/204此时仍未删除。对照Item code204×2→缓存数组[204,204]，并非调用GenerateItem两次。',
      ['Model.UserData.RewardApi','Model.RewardHandler.RewardCategoryHandler.ItemRewardCategoryHandler','Model.RewardHandler.RewardCategoryHandler.PropertyRewardCategoryHandler'],methods=['AcquireRewardsLogic','SplitRewards','_AcquireRewardsLogic','LogicHandle'])
    node(s,'gift_buff','亲密度礼物与Buff奖励','即时奖励之后才处理礼物，再处理Buff。礼物须亲密度开放；Buff由订单提供的接口决定。它们与最后的金币翻倍是不同调用，不能简单把全部奖励再乘2。',
      'giftRewards~=nil且CharacterIntimacy.IsOpen才AcquireRewardsLogic(Give,FinishOrder)，未显式传gameMode/Type2。order.GetBuffRewards存在才调用，结果非nil发同类Logic。GetGiftRewards读m_giftRewards；_AddGiftRewardInfo在新订单创建后已有gift时复用，无则CharacterIntimacy.AddGiftRewardInfo，数据库另存/还原。MainOrder.GetBuffRewards交BuffManager.GetBuffRewards(self)，不同Buff的候选与档位不能凭订单Price推导。SetFinished稍后重新读GetRewards的缓存路径，与这两组独立发奖位置区分。',
      '本例礼物为空且无Buff额外奖励，两段跳过。','gift=nil，BuffRewards=nil；Gold8不被这两段重复发放。',
      [B,O,M],methods=['FinishOrder','GetGiftRewards','GetBuffRewards','_AddGiftRewardInfo'])
    node(s,'smile','订单微笑分数与首轮提示','材料扣除前处理订单微笑进度，更新该槽已完成次数并保存。首个普通微笑的提示要等普通链末尾才派发。它不是普通金币奖励，也不等于每张订单固定加1。',
      '主游戏模式且GetAddSmileScoreBySlot>0，主盘读取两次该数→BI→OrderBoost.OnOrderFinished→order.SetOrderBoostFinish(smileNum)。smileNum==1、活动当前score==1且logicType Normal才triggerButterfly=true；提示在尾部才发。GetAddSmileScoreBySlot：非Started/curInfo=nil返0；TimedSlot返2，ExtraSlot返0，ContiSlot读Conti模型GetSmileCount；其他槽查order_slot/order_num/reward_num，finishSlot>=上限返0。OnOrderFinished再次要求Started/Main且GetAddOrderBoostScoreByOrder>0；curScore=min(old+add,MaxScore)，slot完成数+1，达上限触发ReviewRace.FinishRace和相关日志；可用cell播放微笑飞行；SaveMetaData→OrderBoostSmileAddScore。活动配置档位来自远端，不能填默认1。',
      '本例微笑活动不生效，不改变分数，也不触发首轮提示。','slot1、活动非Started→smile0；对照TimedSlot且Started/curInfo有效→槽分2，仍不满足smileNum==1首轮提示条件。',
      [B,'OrderBoost.Model.OrderBoostModel'],methods=['FinishOrder','GetAddSmileScoreBySlot','OnOrderFinished'])

    s=stage('consume','标记完成，再逐项扣需求物品',
      '先缓存奖励并标完成，再按原需求顺序一件一件扣物。每项先找棋盘，再找仓库；每次都重新统计并刷新订单。两处没有就记错误并继续，源码没有撤销已经发放的奖励。',
      '订单标Finished；扣棋盘两件203，再扣仓库204，每项刷新状态。Gold保持108，能量保持10。')
    node(s,'mark','缓存奖励与完成状态','完成状态写在扣除之前。完成后的奖励读取走缓存，但缓存首次填充可能重新调用奖励计算，不能认为即时快照就是唯一一次计算。',
      'BaseOrder.SetFinished：Table.IsEmpty(m_cacheRewards)时m_cacheRewards=GetRewards，然后m_state=Finished。不会用_SetState，不改变stateChange/time。首次尚未Finished时再次GetRewards可能重新读活动状态；MainBoardModel此前即时发奖快照与这次缓存不是同一个赋值。槽位模型之后还会SetFinished一次，非空缓存则复用；空缓存会继续调用GetRewards，而Finished订单读取空缓存复制。GetRewards Finished返回DeepCopy，防止外部直接改缓存。',
      '无活动状态变化，奖励缓存仍为Gold8，状态改4，再开始扣物。','m_cacheRewards=[Gold8]，m_state=4；不更新stateChangeTime；后续Slot.SetFinished不再重新计算非空缓存。',
      [BO,O,B,S],methods=['SetFinished','GetRewards'])
    node(s,'board','按棋盘遍历序扣第一件匹配物','逐项找裸代码相同的第一件棋盘物，不按最近距离或等级挑选。同code重复需求会在后一次扫描找到另一实例。',
      'RemoveOrderRequirementItems以ipairs需求原序遍历，每项itemRemoved=false，GetValidPositionIterator从头扫描，item非nil且GetCode==requirement→RemoveItem(item,false)，removedItemsFromBoard[i]=对象并break。RemoveItem先清格，再ItemManager.RemoveItem/_RemoveItemProperty删除保存属性；false禁当次_SetItem自动刷新，外层随后Count/Update。BaseBoardModel._ValidPositionIterator从(1,1)开始，x每次加1；到HorizontalTiles后x重置1、y加1，超过VerticalTiles结束。主盘7×9依次(1,1)…(7,1)、(1,2)…(7,9)，因此本例先扣(1,1)再扣(2,1)。每件需求都重新从(1,1)开始，不沿用上次扫描游标。',
      '第一项203删除第一匹配对象，第二项扫描剩余棋盘删除另一203。','RemovedFromBoard[1]=203对象A，[2]=203对象B，[3]=nil；对象身份不同，需求顺序未去重。',
      [B,'Board.Model.Board.BaseBoardModel','Board.Model.Board.BaseItemLayerModel'],methods=['RemoveOrderRequirementItems','GetValidPositionIterator','RemoveItem'],icons=('203',))
    node(s,'store','棋盘未找到才扣仓库','同一需求只要棋盘已扣到，就不再扣仓库。棋盘找不到时扫描仓库索引，删除第一件匹配物并删除保存属性；缓存不在兜底范围。',
      'if not itemRemoved：j=1..store.GetItemCount，GetItem(j)非nil且GetCode==requirement→store.RemoveItem(j)→_RemoveItemProperty(item)→itemRemoved=true→RemovedFromInventory[i]=requirement→break。移除造成索引移动，下一需求重新读取数量并从1扫描；结果数组按原需求索引可能有空洞，消费者用pairs。仓库数组保存code而不是对象；棋盘数组保存对象，便于各自动画。不会RetrieveStoredItem先落棋盘，不查Cache。',
      '第三项204棋盘没有，删除仓库索引1那件；前两项没有动仓库。','RemovedFromInventory[3]="204"，索引1/2为空；storeCount1→0。缓存204不会代替仓库204被扣。',
      [B,'Board.Model.Board.BaseBoardModel'],methods=['RemoveOrderRequirementItems'],icons=('204',))
    node(s,'refresh_failure','逐件刷新与部分失败边界','每件尝试之后刷新真实数量和其它订单状态。某项没找到也继续处理后面的需求；先发奖再扣物的顺序必须保留，不能用“交付成功”概括所有异常。',
      '每项扫描结束无论itemRemoved真假都CountItemsCode→UpdateOrderState；失败额外LogErrorInfo(FinishOrderRemoveItemError,requirement)，不抛显式异常、不终止循环、不还奖、不恢复已删物。返回RemovedFromBoard/Inventory稀疏映射。MainBoardModel普通入口未再次CanDeliver；窗口只ContainsOrder。这些事实可产生缺物时部分完成的代码路径，但原版用户是否能通过并发输入到达还需运行观察。UpdateOrderState调用刷新各订单填充与代码需求；Finished订单UpdateState直接跳过，其它订单可能从可交付降级。',
      '本例三项都扣到，刷新3次，删除清单完整。对照确认后仓库204消失，会记录第三项错误但Gold8不会自动撤回。','Count/Update各3次；对照第三项失败：Finished仍4，Gold108，RemovedFromInventory[3]缺省。',
      [B,BO,'Board.Model.Order.BaseOrderModel'],methods=['RemoveOrderRequirementItems','UpdateOrderState','UpdateState'])

    s=stage('after','扣物之后：烹饪奖励、宝箱通知与延迟发奖',
      '扣除完成后才尝试烹饪狂热奖励，因此刚腾出的格可能成为奖励落点。之后通知宝箱顾客完成，再发之前分离出的延迟奖励，最后才进入所属订单模型的完成与补位。',
      '本例三项扣除后烹饪资格不生效，宝箱槽判定为假，延迟映射为空，进入补位。')
    node(s,'cooking','烹饪狂热：选奖、选物与落点','先按订单难度匹配当前Buff。单奖模式先决定奖励类别，再在棋子奖内部优先帮助订单缺口；全奖模式遍历全部奖励。可放棋盘的直接生成，其余交奖励API；它有自己的候选与去重，不能套普通母体随机池。',
      'GetCurBuffConifgByOrder要求curData与当前doingBuff存在；按buff_id且diff_score_min≤订单难度≤diff_score_max取首条。AcquireRandomRewards先GetCookingFrenzyItemCode。win_all≠1：把CookingFrenzyItem各份Weight合成类别权重，其它奖励原权重，先ListWeightSelectOne；若选棋子类别再次读取棋子缓存，对内部奖励按state给Weight×10000(微笑订单缺口)、×100(普通缺口)、否则原Weight，再抽一项；win_all==1用全部配置。所有抽奖只读候选，不扣全局份额。\n\nGetOptionalChessPieces：复制普通缺口，逐项扣掉当前订单需求，到0删除；逐链记录最大缺口等级，微笑缺口也扣当前需求且仅num>0参与。候选须OrderItem.DiffScore在reward.MinNum..MaxNum含端点、UnlockLevel≤玩家等级且至少一个该链母体已解锁；分组1微笑缺口链1..目标等级、2普通缺口链、3全部合法候选。没有ProgressUnlock等其它随机订单过滤不能自行添加。\n\nGetCookingFrenzyItemCode按order对象缓存；配置棋子奖数量变化或缓存代码不再适用则重建。重建时将奖励槽候选分组复制，按前置非空组和候选数更少的槽优先处理，取该槽第一个非空组，ListRandomSelectOne等权抽；从其它槽各组删除选中code，尽量不重复；全组为空时回退原全候选，state为repeat，所以不是绝对禁止重复。重用缓存仍保留先前state；当前源码排序比较器存在返回true/非严格边界，不能自造稳定优先顺序。\n\n统计固定棋子MaxNum，为(#动态棋子+fixedMaxNum)从(4,9)找可用格。动态棋子每项count1，固定棋子数量ceil(Random(MinNum,MaxNum))逐个生成，货币也这样选数量；两整数Random为含端点整数，ceil通常不变。无格标isCookingFrenzyItem交API；有格填itemPos。结果DeepCopy并m_mapCacheAcquireReward[order]保存。主盘按itemPos分两组，有位逐份GenerateItems，其他AcquireRewardsLogic(Give,FinishOrder,gameMode,Type2)。远端Buff/奖励值尚未取得，不用演示倍率替代。',
      '本例没有当前烹饪Buff，直接跳过。对照一份棋子奖励会优先使用扣物后释放的格；没有落点才通过奖励API。','本例cfg=nil。演示同内部原权重1，state微笑缺口→10000，普通缺口→100，备用→1；类别抽样与内部抽样是两轮，不是一次归一化。',
      [B,O,'CookingFrenzy.Model.CookingFrenzyModel','Common.Utility.Table','Common.Utility.MathUtil'],configs=('OrderItemConfig',),methods=['TryAcquireCookingFrenzyReward','AcquireRandomRewards','GetCookingFrenzyItemCode','GetOptionalChessPieces','GetCurBuffConifgByOrder'])
    node(s,'chest_delay','宝箱顾客通知，再发延迟奖励','先派宝箱顾客完成通知，然后发快照中各组延迟奖励。通知本身与奖励标记落账不同；两者都发生在槽位补位之前。',
      'ChestCustomer.IsChestCustomerOrder(order.Slot)为真DispatchEvent(ChestCustomerOrderFinish)，这里没有payload。随后pairs(mapDelayRewards)，每组AcquireRewardsLogic(Give,FinishOrder,gameMode,Type2)。Chest处理器按ipairs逐条交AcquireChestCustomOrderReward；活动非Started立即结束。标记解析innerType与slot，再取该槽旧订单，无订单记录错误并返回。预算按DiffScore匹配eventOrderScore区间，百分比非nil时diff×percentage/10000，否则固定数；匹配不break，重叠档后者覆盖。Random2槽3预算最多18。按orderPool含类型筛方案，按weight抽一个。普通方案逐轮等权从rewards抽一项，把该项count当预算成本，发该code一件并减预算，直到预算≤0；可重复抽，允许最后超预算，不是发配置count件。成本≤0可能无法终止，源码没有修复。含chestcustomeritem标记则走缺口定向算法。展开后从(1,1)按扩散序找足量格，已有格逐件GenerateItems并记日志，剩余交奖励API入缓存。保存完整展开结果到innerType_slot映射并SaveCacheData，供视图领取显示。不能把标记数量1当必定只给一件，也不能因为delay就断言等待动画才落账。视图会稍后展示同一组，Logic与View分离。',
      '槽1不属于宝箱顾客，延迟为空，所以不派宝箱通知也不发这组奖励。','IsChestCustomerOrder=false，pairs({})0次。',
      [B,'Model.RewardHandler.RewardCategoryHandler.ChestCustomOrderRewardCategoryHandler','ChestCustomer.Model.ChestCustomerModel','Board.Model.RandomGenerateCodeHelper'],configs=('OrderItemConfig',),methods=['FinishOrder','LogicHandle','AcquireChestCustomOrderReward','FindNormalRewardConfig','GenerateChestCustomCodeRule'])

    s=stage('refill','所属模型完成：更新历史，再补订单',
      '普通交付寻找仍包含该订单的模型。主订单先更新亲密度、下一次Lucky资格、累计难度与重复链权重；槽位模型再写完成、日志，移除旧槽并按优先级补新订单。补位是多轮且含固定、教程、活动和随机分支，最后才派全局订单完成通知。',
      '本例累计难度100→109；默认Random1没有LuckyTriggerChance，下一次Lucky资格关闭；旧槽移除，是否补出新单取决于该槽固定进度、创建次数和冷却等输入。')
    node(s,'owner_history','所属校验与下一单使用的状态','寻找包含该对象的模型之后，更新影响下一单的状态。Lucky订单保持下一次触发资格，普通订单仅在配置提供机会时抽一次；该Lucky与母体产出Lucky是两个系统。',
      'MainBoardModel遍历m_orderModels以pairs ContainsOrder，首个命中FinishOrder并break；没有命中也继续尾部Update/Sync/局部消息，不撤即时奖励。MainOrderModel.FinishOrder在父类ContainsOrder校验前就执行副作用：Branch标finished；CharacterIntimacy.OnMainOrderFinished；m_canTriggerLucky=false，IsLuckyOrder真设true，否则GetRandomOrderConfigBySlot(slot)[innerType]有LuckyTriggerChance才MathUtil.Random()≤chance设true。无参Random正常返回math.random()浮点，测试可缩窄区间，不保存机会池；没有参数时nil分支不抽。NormalOrderSlot真则TotalDiffScore+=GetDiffScore；每个需求配置RepeatWeightDecrease>0将所属链计数reset为3并保存。重复code可多次reset并保存。最终SlotOrderModel.FinishOrder再次ContainsOrder失败返false，但主订单前述副作用已发生。',
      '模型包含本例；难度加9，默认Random1配置没有机会字段，不抽Lucky；低级203/204没有RepeatWeightDecrease，不重置链计数。','TotalDiffScore=100+9=109；m_canTriggerLucky=false；对照chance=0.25、u=0.25成立，0.2501失败（机会字段为演示假设）。',
      [B,M,S,'Common.Utility.MathUtil'],configs=('OrderRandomConfig','OrderRandomRecallConfig','ChestOrderRandomConfig','ChestOrderRandomRecallConfig'),methods=['FinishOrder','ResetRepeatWeightDecreaseByChainId','Random'])
    node(s,'loop','完成日志与多轮补位','槽位模型先完成旧单并记日志，再扫描全部槽位。某个空槽本轮没补上，若其它槽成功创建，下一轮会再次尝试；一轮完全没有新订单才停止。全局完成通知在补位之后。',
      'Slot.FinishOrder：ContainsOrder假returnfalse；SetFinished→_LogOrderAction(finish)→_TryFillOrders→OrderFinished{order}→returntrue。_TryFillOrders repeat：slot=1..m_slotCount(主盘19)，nil/Finished才处理，有旧单_RemoveOrder并置nil，_TryCreateOrder成功则DBAdd→m_orders[slot]=new→加入arrNewOrders，hasFilledOrderOnce=true；until not。至少一次成功才UpdateOrderState并按创建顺序逐条unlock日志；无成功不做这次内部刷新，但主盘尾部仍刷新。MainOrderCreated在_tryCreate返回之前派发，此时新单尚未写入m_orders；不能把它的消费者看到的集合当作DBAdd之后状态。',
      '旧槽1移除；演示补位若槽2先成功、槽1暂失败，下一轮槽1还会尝试。','两轮示例：轮1槽1=nil、槽2=新单；轮2槽1=新单；轮3无新单停止。每成功新单仅DBAdd一次。',
      [S,M],methods=['FinishOrder','_TryFillOrders','_TryCreateOrder'])
    node(s,'priority','新订单创建的优先级','每个槽先试固定、回归免费、教程、连续活动、额外顾客、Lucky，最后才普通随机。前者成功就跳过后者。选择头像和保存礼物也发生在创建链里，不能理解为只随机几个需求。',
      'MainOrderModel._TryCreateOrder先Fixed.Create；new=nil且ReturnFree.CanCreate才Create；再教程CanCreate/Create；读取contiModel并在nil/CanCreate时创建；再ExtraCustomer；再Lucky.CanCreate/Create；最后require随机creator。新单无Id且GetType==Random才DBIdGenerator.Generate并tonumber；_AddGiftRewardInfo→MainOrderCreated(new)→return。固定订单写当前Id进度发生在构造之前。回归/活动/教程资格可能改元数据，即使最终构造nil也不能假设无副作用。\n\n头像：FirstOrder元数据空首次置1返固定6。BakeOut可领奖优先收集未被其它订单占用的BakeOut头像；没候选再按NormalAvatars等级门槛收集未占用。全部占用则从已解锁普通头像等权回退；连普通解锁集合都空才返6。多个集合来自pairs时排列不固定；头像不构成需求权重。教程/连续/额外顾客的完整专用构造和远端配置另有依赖，不能在此把它们默认为普通随机。',
      '本例提交后的新单先受固定进度影响；只有前六类未创建才到Random1。','显式对照：Fixed成功→Return/教程/活动/Lucky/随机的创建函数均不执行；无Id的Random新单才生成DBId。',
      [M,C,R],configs=('OrderFixedConfig','OrderAvatarConfig'),methods=['_TryCreateOrder','GetAvatarId','_AddGiftRewardInfo'])
    node(s,'fixed_return','固定与回归免费订单','固定单按进度的下一Id和槽/等级门槛创建，不随机需求。回归免费单在指定槽与回归时间内取现有较高等级物；计时资格与选物是两个步骤，构造失败也可能已经改计时。',
      'Fixed：CurrentFixedOrderId默认0，next=id+1；nextConfig存在、Slots包含当前槽、level≥UnlockLevel才meta设nextId，再按Requirement1..3构造。ReturnFree仅槽1/2/3，ReturnUser.IsOpen且IsInReturnRewardTime；timer==0先写serverTime返false，timer=nil或now−timer≥28800写0返true，其他false。Create从GetItemsOnBoard(true).levelList倒序，首个level≤7的itemList内Random(1,#list)等权选一件code，无code返nil；若该槽随机timer==0还将其改now，再单需求ReturnUserFree创建。每次重建候选，未从全局无放回池扣物；这里只创建需求，不删除现有棋子。',
      '主例讲解交付，不假定固定/回归进度。对照固定首条采用原配表需求；回归候选只决定新单需求。','回归timer0、now1000→写1000,false；timer1000、now29799→false，now29800→true并写0；28800秒=8小时。',
      [C,M,B],configs=('OrderFixedConfig',),methods=['MainOrderCreatorFixed.Create','MainOrderCreatorReturnFreeOrder.CanCreate','MainOrderCreatorReturnFreeOrder.Create','GetItemsOnBoard'])
    node(s,'lucky','Lucky订单：资格、现有库存与有限连续次数','完成订单只提供一次触发资格，Lucky创建还要检查等级、次数与冷却。需求只从现有且不被其它订单占用的代码中选，重复需求不能超出现有件数；连续次数保存在元数据，不能把它当母体Lucky机会池。',
      'CanCreate仅槽17且CanTriggerLucky；通过入口即CloseTriggerLucky，之后配置缺失或等级失败也已消耗本次资格。points>1允许；points==1写timer=now、points0并拒绝；points0则lastTime+RefreshTime≤now才允许。Create按Lucky配置第一个匹配Filter和三个等级区间生成候选；TryLuckyRandom取board+store计数，剔除其它订单已有需求code（测试模式可跳本槽），Weight>0且count映射非nil才候选并存CurNum。首候选空时失败，原points非0则清点并启动CD。\n\nItemAmounts缺字段补0，三键全缺则回退等级档，按非空第一/第二/第三池构Count1/2/3权重后先选需求数。抽第一code后在第二与第三池同code的CurNum−1，到0移除；第二同样影响第三。这是按当前可用库存份额防超额，原Weight不按数量成比例扣减；同code有2件时可以出现2次。后池为空则少于抽中的目标项数也能建单。成功points非0→points−1，否则→配置Point；不是先设Point再减1。下次候选按实时库存重建，交付才实际扣物。\n\nGetSelectedFilter依PlayerMin/Max、DiffSumMin/Max、sMonthPay/eMonthPay含端点且按数组第一条匹配；无匹配后续解引用失败没有通用默认。配置变体的IsLucky行才被LoadFileConfig单独保存；默认OrderRandom未出现不意味着机制无代码。',
      '本例默认Random1没有触发机会且Lucky资格关闭，不创建Lucky。对照已有两件203时，需求可选两次203，第三次会被CurNum约束。','演示CurNum203=2；第一次抽203后其它池2→1，第二次203后第三池1→0移除；下一张单重新统计。points1→0并开始CD，不会再直接创建最后一张。',
      [C,M,R,'Common.Utility.Table','Common.Utility.MathUtil'],configs=('OrderRandomConfig',),methods=['MainOrderCreatorLuckyOrder.CanCreate','MainOrderCreatorLuckyOrder.Create','TryLuckyRandom','LuckRandomRemoveCode'])
    node(s,'random_gate','普通随机：槽位、次数与冷却','随机创建首先选适用于槽位的创建器，再检查等级、批次次数和冷却。次数不足有活动强制补单例外；次数在资格通过时就扣，不能等创建成功后才扣。回归与宝箱顾客可选择不同配置。',
      'GetRandomOrderConfig在回归开放且回归奖励期用Recall，否则常规；GetRandomOrderConfigBySlot若Chest槽用Chest/ChestRecall。随机入口按Random1→2→3→4→5New→Intimacy→Timed→Baseline首个CanCreate真，选中后Create返回nil也不再试别的creator。\n\n通用CanCreate读取startTimer和Point or1。timer0读存points，缺/空用配置Point；points0则写now开始CD。timer=nil或now−timer≥RefreshTime恢复points=Point并写timer0。points0仅ForceCreateOrder(该槽微笑>0、Puzzle代币>0、Butterfly强制槽、CustomerUpgrade可填、测试指定)可绕过并写timer0/points0返true，否则false；points非0先−1保存再true。资格函数不是纯查询。\n\nRandom1槽1/2共享Random1StartTimer与points：CD恢复时Point减两槽未Finished且Random1数量，旧points读数无通用nil补救；Random2仅槽3，无其它有效订单（排Conti、Special、Extra）则timer0直接允许，否则通用；Random3槽4、Random4槽5、Random5New槽8按模板；Intimacy槽10要求亲密度及随机订单开放；Timed槽13交Timed模型资格/Create。Baseline槽15：GenerateTime−1先写now拒绝；now−time<60拒绝；候选为库存数量−其它需求数量≥RecommendedNumber的代码，Create先写−1，均匀选code，重复RecommendedNumber次，并置baseline=true。',
      '默认Random1为UnlockLevel3、Point5、RefreshTime3600；本例等级10通过等级，但是否能补单还需当前points/timer和其它槽状态。','演示timer0、points1→保存0并true；再次资格timer0/points0→写now并false（无强制）；now−timer==3600可恢复。',
      [R,M,'Board.Model.Order.MainOrderDefinition'],configs=('OrderRandomConfig','OrderRandomRecallConfig','OrderItemConfig'),methods=['CanCreate','GetRandomOrderConfig','GetRandomOrderConfigBySlot','GetBaselineAvailableItems'])
    node(s,'candidates','重建候选：解锁、现有需求与权重修正','每个需求位置重新构建候选，排除尚不可用物和已被需求占用的代码，按库存情况修正权重。第一项可在特定活动条件下使用备用候选；不是每次都从完整物品表直接抽。',
      'GetAvailableItems默认getter配置控制checkProgressUnlock/excludedByLastOrder/excludedByOtherOrder。取orderModel.GetCodeCountMap=board+store、不含cache，再CalculateOrderCodeCountData加alreadyRequiredItems。为WeightMultiple==1的链统计已有需求/缺口与现存最小链等级：链有需求且无缺口→RequiredAndEnoughToFinish；链无需求→NotRequiredBase；code等级≥现存最小等级→NotRequiredAndHasHigherLevel，OrderDiffDynamic开时再×10^ratio，ratio是从最小等级到当前等级−1存在库存的不同等级数，非物品总数量；code倍率优先链倍率。\n\n逐条_CheckItemCode累积失败位，不遇首错立即返回：ProgressUnlock==1要求该链前一级已解锁且level>1；上一同槽订单包含同code、当前其它需求已有同code、玩家等级不足、ForbiddenSlot包含槽、所有母体未解锁、Weight≤0分别置失败位。chainAvailability按链缓存任一母体已解锁。最终Weight=原Weight×code倍率或链倍率或1。Pass才进主池；备用池只允许“仅上一单冲突/仅其它需求冲突”的失败位组合，不允许解锁/等级等额外失败。备用仅该槽微笑加分>0或Conti槽保留；普通选择仅第一项isBack=true可回退。默认getter三项检查均为true。ItemMultiple原始常量：RequiredAndEnoughToFinish=100，NotRequiredBase=1000，NotRequiredAndHasHigherLevel=10000，Bonus=10；这些是权重倍率，不是百分比。动态代码倍率为10000×10^ratio。\n\n遍历itemCodeConfigMap用pairs，候选序号不具跨环境稳定性；复刻可复现随机轨迹必须记录实际候选顺序，单看权重不够。',
      '本例消耗完203/204后才重建下一单候选，不能用交付前库存构造。','演示原Weight100，满足无需求链且有较低库存、ratio2时，代码倍率10000×10²=1000000，最终Weight100×1000000=100000000；库存等级分布为演示输入，10000与10为源码常量。',
      [R,M,B,'Board.Model.Order.MainOrderDefinition'],configs=('OrderItemConfig',),methods=['GetAvailableItems','_CheckItemCode','CheckItemCodeProgressUnlock','CalculateOrderCodeCountData'])
    node(s,'dynamic','选过滤档，再调整难度上限','先按等级、累计难度和付费区间选第一条过滤档。常规等级上限可因库存有富余高阶物而提高，但只作用于符合条件的链；动态候选会被乘50增加机会。',
      'Filter第一匹配含端点，三项各取First/Second/Third Min/Max与DynamicMax。GetDynamicMaxLevel初Level=max，Items/Chains空；仅dynamicMax和max均存在且max<dynamicMax启动。取board+store计数与全部需求(含已选)。对现有code，difficulty=配置DifficultyLevel或链等级，要求max≤difficulty<dynamicMax，并在所有同链、链等级≥此现有物的需求中严格满足库存数>需求数；恰等不够。保留可用现有物中的最高difficulty，平级多件保留。对每件取同链下一等级（已链顶用自己），该code在available中则Weight×50，加入Items/Chains；有项才Level=最高difficulty+1，否则仍max。FilterByLevel用DifficultyLevel优先，动态Chains用动态Level上限，其它链普通max；min同样含端点。函数末尾即使正常模式也DispatchEvent(TestOutputTableInfo,testInfo)。第一项回退时源码再次用已过滤空主池计算动态结果，随后过滤备用池，不能凭名称修正成用备用池计算。',
      '本例交付提高累计难度到109，下一单匹配过滤档使用该新值；等级10默认Random1匹配第一档。','默认第一档FirstMax6、SecondMax5、ThirdMax3；演示max6、dynamic9、富余现有等级7→下一等级8权重×50，适用链上限8。库存=需求时不扩展。',
      [R],configs=('OrderRandomConfig','OrderItemConfig'),methods=['GetSelectedFilterConfig','GetDynamicMaxLevel','FilterByLevel'])
    node(s,'draw','先选三个候选，再抽需求项数','普通随机先顺序选第一、第二、第三候选，之后才按权重决定保留几项。因此最终只有一项的单，也可能已经消耗了第二、第三候选选择的随机数与权重状态。',
      'CreateNormalRandomOrder：测试指定需求可直接返回；Chest创建资格可把randomConfig换ChestRandom，缺配置才回退普通并清chestModel。初始化重复链状态与ItemsUsingDynamicLevel[slot]，选Filter。selectItem每次重建候选，动态修正→等级过滤→第一项允许备用→空返nil→重复链衰减→ListWeightSelectOne.Code→加入alreadyRequiredItems→超普通max记动态项→MarkSelectedLine。第二依赖first存在，第三依赖second存在。最后RandomOrderHelper.Create再ItemAmounts或按Level升序表逆扫最大≤当前等级档，缺键补0；Count1须first，Count2须second，Count3须third；空Count池返nil。加权选Count后只保留前Count件，再头像/礼物。\n\n重复链：支持Random1/2/3/4/5New/Conti；mapChainRepeatWeight[chain]非nil且配置RepeatWeightDecrease非nil才Weight除该配置值（不是除剩余次数，也非指数）。处理过链先SelectedLine=true，若真正选中此链且有衰减字段/计数则false。最终UpdateMapInfo：true链计数减1，到0删除，false重置3，再保存。候选步骤中已选但最后Count未保留的第二/第三项也已参与MarkSelectedLine，不能按最终需求重算历史。\n\nListWeightSelectOne按ipairs求sumWeight，用MathUtil.Random(sumWeight)得到floor(u×sum)+1，依次比较≤Weight否则减Weight。只读列表，不统一移除已选项；防重复来自重建候选时alreadyRequiredItems和过滤规则。权重经除法可能为小数，而该工具要求sum为整数的断言仍存在，不能擅自改成浮点轮盘；sum≤0也有断言及非空回退首项边界。正常每单重建池，有放回/排除规则须按具体code候选条件判断，不是全局有限订单池。',
      '下一单的需求数在候选预选之后决定。演示三候选都有但Count抽到1，最终只保留第一件。','默认ItemAmounts=50/50/0；整数R≤50→1项，51..100→2项；第三项权重0不会选。假设仅first有候选，Count池只1项，权重50→必选1项。',
      [R,M,'Common.Utility.Table','Common.Utility.MathUtil'],configs=('OrderRandomConfig','OrderItemNumberWeightConfig','OrderItemConfig','ChestOrderRandomConfig'),methods=['CreateNormalRandomOrder','RandomOrderHelper.Create','DecreaseItemWeight','MarkSelectedLine','UpdateMapInfo','ListWeightSelectOne'])
    node(s,'save','移除旧单、保存新单与重载','旧单删除时保存上一单需求，供下一次过滤；新单保存需求、类型、头像和独立的Lucky/基准/难度标记。重载从这些值重新构造对象，不应重新随机一份需求。',
      '_RemoveOrder先清Album槽奖励（无模型缓存待清槽），再_DBRemoveOrder。DBRemove删槽行、礼物信息，写lastfinishorder_slot=innerType@avatarId@id@code1;code2;code3，并保留内存旧订单引用；清luckorder_/baselineorder_/UnLockedDiffRange_；ChestOrderFinish清宝箱槽状态。DBAdd BatchSet该槽type、最多3条requirementStr、avatarId、id，保存礼物；Lucky/基准真分别写标记"1"，DiffRange真写字符串。DBGetOrders读取所有槽和标记、空DiffRange→nil；_CreateOrder对Timed类用TimedOrderOrder、Extra用EmptyReqOrder，其他MainOrder；恢复礼物后回集合。_DBGetLastFinishOrder按@和;拆分，但源码未将innerType/avatarId/id统一tonumber，类型一致性不能擅自假设。重复链状态json逗号换@保存、恢复逆换json.decode，空集合删除记录。原生DB存档一致性和同步回滚需外部运行验证。',
      '本例旧需求203;203;204被记为上一单。新单若创建成功，保存其真实需求，之后重载复用已保存需求。','历史字符串示意1@头像@Id@203;203;204；不删除重复203；新单标记仅真才写1。',
      [M],methods=['_DBRemoveOrder','_DBAddOrder','_DBGetOrders','_DBGetLastFinishOrder','SaveRepeatWeightDecreaseInfo'])

    s=stage('finish','模型收尾，再播放交付表现',
      '所属模型补位与全局完成通知返回后，主棋盘再刷新状态、按资格发首轮微笑提示，检查同步并派局部完成消息。视图收到消息播放棋子飞入、奖励表现和顾客离开；表现不能再次发放已经落账的奖励。',
      '本例物品已扣、Gold108、能量10，才进入交付动画和同步检查；新单资格与需求取补位实际结果。')
    node(s,'sync','再次刷新、提示与同步消息','全局OrderFinished先于棋盘局部FinishOrder；同步上传检查夹在局部消息之前。首轮微笑提示只在先前资格满足时派发。',
      '普通FinishOrder尾部UpdateOrderState→triggerButterfly真派SmileOrderDeliver_1→SyncModel.CheckMoreUpload(nil,nil,requirements)→self.event.Call(FinishOrder,{Order,RemoveItemInfo,Rewards,mapDelayRewards})。OrderFinished{order}已在Slot.FinishOrder补位后派发。两者不同事件与payload不能合并；Sync检查不是服务器确认交付响应。本地主流程没有等待网络成功才发局部消息，网络队列/合并与存档协议另属同步模型。事件所有监听的奖励/任务/延迟回调仍需逐个闭合，不能因直接顺序明确就批准全量消费者。',
      '本例没有首轮微笑提示，完成全局事件、尾部刷新、同步检查后才发棋盘完成消息。','局部payload Rewards=Gold8，RemovedFromBoard键1/2，RemovedFromInventory键3，delay={}；Sync参数需求仍[203,203,204]。',
      [B,S],methods=['FinishOrder'])
    node(s,'animation','扣物飞行、奖励表现与顾客离开','材料先在模型中删除，视图再播放飞行动画。普通奖励先表现，相册和礼物稍后表现，顾客最后离开并移除格子。特殊与分支则用各自完成动画。',
      'MainBoardView._OnFinishOrder先重建layout并禁滚动，取旧订单cell；用message.Rewards或订单缓存copy，处理Buff/微笑表现，AddContiorderExtraReward修改表现数组；棋盘Removed映射pairs逐个_PlayRemoveOrderItemAnimation(index,0.5,2)。将相册奖励放delay，其它放other。DOTween等待0.5→插入Cooking动画→金币效果及AcquireRewardsInView(other,noDelay=true)；亲密度礼物加入delay并显HUD，delay非空再等0.3并View；再等0.5→宝箱表现→PlayLeaveAnimation→等待cell自定义时间或1秒→RemoveCell→开滚动→ButterflyDelayScroll→_StartPrompt。仓库稀疏映射pairs单独_PlayInventory2OrderItemAnimation(index,code,0.5,2)。这是调度顺序，动画辅助函数可能追加时长，不把0.5+0.3+0.5+1当统一真实总时长。\n\n特殊完成_PlaySpecialOrderFinishAnimation参数1.4/2.6，回调打开SpecialOrderCompleteWindow；分支参数1.8/3，回调StartSpTimeline(EndTimeline)。模型SetSlot时间线标记先前已经写入。动画/展示不调用普通AcquireRewardsLogic重发金币，但辅助函数中额外活动领取和锁定回调仍须按源码逐一核销。',
      '模型已扣两件203与仓库204，视图按需求索引播放三件飞入，并展示8金币，顾客离开后恢复滚动。','模型余额108不会因View再变116；RemovedFromInventory[3]正确飞向第3需求，不因稀疏数组而遗漏。',
      [V,'Board.View.Order.BaseOrderAnimation'],methods=['_OnFinishOrder','_OnFinishSpecialOrder','_OnFinishBranchOrder'])

def case(page,entry=None,detail=False):
    body='\n\n---\n\n## 贯穿案例：203×2与204×1，使用仓库补交\n\n'
    if entry and entry.get('icons'):
        body+='<div class="case-assets">'+''.join(f'<img src="{html_link(page,DOCS/"assets/cases"/("item-"+c+".png"))}" alt="棋子{c}" width="72" height="72">' for c in entry['icons'] if c!='2401')+'</div>\n\n'
    body+=(entry['case'] if entry else '先确认使用仓库204，再领取8金币，扣除棋盘203两件和仓库204一件；更新完成历史并尝试补位，最后播放交付表现。')+'\n'
    if detail:body+='\n### 代入本页的值\n\n'+entry['calc']+'\n'
    return body+'\n<details><summary>案例共同前提</summary>\n\n'+PREMISE+'\n\n分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。\n\n</details>\n'

CONFIG_MEANINGS={
 'OrderItemConfig':'Code是精确需求代码；Price/RecommendedPrice用于普通/基准单价格；DiffScore为难度累计与活动输入；UnlockLevel含端点门槛；ProgressUnlock=1要求前一级已解锁；ForbiddenSlot排槽；Weight为原始份额；WeightMultiple参与库存链倍率；RepeatWeightDecrease为除数；DifficultyLevel覆盖链等级筛选；RecommendedNumber控制基准单重复数。',
 'OrderRandomConfig':'Type索引内部类型，IsLucky=1行独立选为Lucky配置；UnlockLevel等级门槛，RefreshTime秒，Point批次可创建次数，LuckyTriggerChance为浮点阈值（缺省不抽）；Filters按数组首匹配，Player/DiffSum/MonthPay上下界含端点，First/Second/Third及Dynamic上限控制逐项难度；ItemAmounts是一/二/三项权重，不是产物code权重。',
 'OrderFixedConfig':'Id是进度顺序，Slots是允许槽位集合，UnlockLevel含端点门槛，Requirement1..3保留重复与顺序；缺需求不凭空补0。',
 'OrderSpecialConfig':'Id按CurrentSpecialOrderId索引，Requirement1..3决定清除链，GeneratorChain为额外清除母体链；Rewards解析货币字符串；EndTimeline为完成标记；Trigger任务进度用于创建前资格；StartReward/StartTimeline/Avatar/图像/颜色属于创建与显示。',
 'OrderBranchConfig':'Slot索引实际分支配置，Requirement与GeneratorChain决定清链；Rewards的code-count既为抽样份额又为必须发完的件数；BranchType为进度类型，EndTimeline完成标记，Id/AvatarId构造对象。',
 'OrderItemNumberWeightConfig':'Level升序装载后从末尾选最大≤玩家等级一条；OneItemWeight/TwoItemsWeight/ThreeItemsWeight仅在对应候选已存在时进需求项数池。',
 'OrderAvatarConfig':'NormalAvatars的Id/UnlockLevel用于解锁候选；其它分类按订单类型与活动资格读取，已占用头像尽量排除；仅表现头像，不参与需求价格与难度。'
}

def prepare_configs():
    ASSETS.mkdir(parents=True,exist_ok=True)
    wanted=('OrderItemConfig','OrderRandomConfig','OrderRandomRecallConfig','OrderFixedConfig','OrderSpecialConfig','OrderBranchConfig','OrderItemNumberWeightConfig','OrderAvatarConfig','ChestOrderRandomConfig','ChestOrderRandomRecallConfig','NewItemOrderConfig')
    runtime=LuaRuntime();runtime.execute('function CSColor(r,g,b,a) return {r=r,g=g,b=b,a=a} end')
    def convert(v):
        if lua_type(v)=='table':
            keys=list(v.keys())
            if keys and set(keys)==set(range(1,len(keys)+1)):return [convert(v[i]) for i in range(1,len(keys)+1)]
            return {str(k):convert(v[k]) for k in keys}
        return v
    out={};receipts=[]
    for name,m in sorted(BY_NAME.items()):
        leaf=name.split('.')[-1]
        if not name.startswith('Data.Config.') or not any(leaf==w or leaf.startswith(w+'_') for w in wanted):continue
        try:
            data=convert(runtime.execute((ROOT/m['standard_path']).read_bytes()))
            path=ASSETS/(leaf+'.json');path.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
            out[leaf]=data;receipts.append(dict(module=name,records=len(data),sha256=m['sha256'],status='parsed-original-bytecode'))
        except Exception as exc:receipts.append(dict(module=name,status='failed',error=str(exc)))
    (AUDIT/'config_inventory.json').write_text(json.dumps(receipts,ensure_ascii=False,indent=2),encoding='utf-8')
    if any(r['status']=='failed' for r in receipts):raise RuntimeError(receipts)
    return out

def table_text(page,entry,all_configs):
    if not entry['configs']:return ''
    output=['\n## 对应本地配表\n','各后缀为可选变体，不是同时叠加。require受FileReplace精确文件名首匹配替换，失败才回退默认；实际账号选择及远端档位未取得。缺字段记“—”，不能当0。下方保留全记录与全部字段；嵌套Filters/Rewards可横向滚动查看。\n']
    for prefix in entry['configs']:
        meaning=CONFIG_MEANINGS.get(prefix,CONFIG_MEANINGS['OrderRandomConfig'] if 'Random' in prefix else '')
        output.append('**'+prefix+'字段含义：** '+meaning+'\n')
        for leaf,data in all_configs.items():
            if leaf!=prefix and not leaf.startswith(prefix+'_'):continue
            rows=data if isinstance(data,list) else [{'分类':k,'记录':v} for k,v in data.items()]
            fields=sorted(set().union(*(r.keys() for r in rows))) if rows else []
            output.append(f'<details><summary>{leaf}：{len(rows)}条记录</summary>\n<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr>'+''.join('<th>'+html.escape(k)+'</th>' for k in fields)+'</tr></thead><tbody>')
            for row in rows:output.append('<tr>'+''.join('<td>'+html.escape(json.dumps(row[k],ensure_ascii=False) if isinstance(row.get(k),(dict,list)) else str(row.get(k,'—')))+'</td>' for k in fields)+'</tr>')
            output.append('</tbody></table></div></div>\n<p><a href="'+html_link(page,ASSETS/(leaf+'.json'))+'">完整原记录</a></p></details>\n')
    return '\n'.join(output)

def evidence(page,n):
    output=['\n## 源码依据\n']
    for name in n['modules']:
        m=BY_NAME[name];src=source(name);dest=ASSETS/(name+'.lua');shutil.copy2(src,dest)
        dis=ROOT/m['disassembly_path'];dd=ASSETS/(name+'.disassembly.txt');shutil.copy2(dis,dd)
        text=src.read_text(encoding='utf-8');methods=[]
        for i,l in enumerate(text.splitlines()):
            if not l.startswith('function '):continue
            sig=l.removeprefix('function ').split('(')[0]
            if sig in n['methods'] or re.split(r'[.:]',sig)[-1] in n['methods']:methods.append((i+1,l.removeprefix('function ')))
        locations='；'.join(f'{f.split("(")[0]}（恢复文本行{line}）' for line,f in methods)
        output.append(f'- {name}：[恢复源码]({link(page,dest)}) · [原始指令]({link(page,dd)})'+('。对应：'+locations if locations else '')+'\n')
    return '\n'.join(output)

def inventory(nodes):
    names=set(n for x in nodes for n in x['modules'])
    records=[]
    for name in sorted(names):
        lines=source(name).read_text(encoding='utf-8').splitlines();functions=[]
        starts=[i for i,l in enumerate(lines) if re.match(r'^\s*(local )?function\s',l)]
        for k,i in enumerate(starts):
            end=starts[k+1] if k+1<len(starts) else len(lines)
            signature=lines[i].strip(); fid=name+'::'+signature.split('(')[0]
            units=[dict(id=fid+'::L'+str(j+1),line=j+1,text=lines[j].strip(),review='pending') for j in range(i,end) if re.search(r'\b(if|elseif|for|while|return)\b|DispatchEvent|:Set\(|:Call\(',lines[j])]
            functions.append(dict(id=fid,line=i+1,end_line=end,signature=signature,units=units,review='pending-membership-and-full-semantics'))
        records.append(dict(module=name,source=BY_NAME[name]['source_path'],source_sha256=sha(source(name)),bytecode_sha256=BY_NAME[name]['sha256'],functions=functions))
    listeners=[];seen=set()
    for name,m in BY_NAME.items():
        if m['sha256'] in seen:continue
        seen.add(m['sha256']);p=ROOT/m['source_path']
        if not p.exists():continue
        for i,l in enumerate(p.read_text(encoding='utf-8').splitlines(),1):
            if any(v in l for v in ('AddListener','AddActiveListener','REGISTER_BOARD_EVENT','AddHandler')) and any(v in l for v in ('OrderFinished','FinishOrder','MainOrderCreated','ChestCustomerOrderFinish','SmileOrderDeliver','OrderStateChanged')):
                listeners.append(dict(id=name+'::registration::L'+str(i),module=name,line=i,text=l.strip(),review='pending-reachability-and-downstream'))
    (AUDIT/'source_inventory.json').write_text(json.dumps(dict(modules=records,listener_candidates=listeners,limits='Candidate modules contain unrelated functions; signatures are not bytecode prototype proof; dynamic calls remain open.'),ensure_ascii=False,indent=2),encoding='utf-8')
    return records,listeners

FLOWS={
 'button':['检查按钮是否允许点击；禁用时立即结束。','播放服务音效，再按普通或特殊展示入口分流；声音不代表交付成功。'],
 'counts':['复制棋盘现有代码计数，按精确代码区分裸物与包装物。','首次入口排除仓库、缓存；把结果交给需求核对。'],
 'requirements':['保留需求顺序，把重复代码累计为需要的件数。','逐项比较持有数量，汇总缺口；不在第一次失败时停止。','返回是否足够与缺口，让入口选择直接提交或确认窗。'],
 'inventory':['窗口重算棋盘缺口，展示需要用仓库补交的物品。','取消只关闭；确认先记录意愿，再等窗口关闭完成。','关闭回调优先执行专用回调，否则确认订单仍在槽位才提交；这里没有再次检查材料数量。'],
 'special_window':['选独立棋盘物作展示，没有对象时使用仓库图像。','等待初始化和聚拢表现完成，期间忽略遮罩点击。','再次点击恢复原视图并提交，随后播放仓库补交表现和关闭窗口。'],
 'type':['读取内部类型，先判断特殊任务，再判断分支任务。','任一专用路径处理后立即返回，其余才进入普通结算。'],
 'special':['先完成所属模型，读取当前任务配置。','按需求链和母体链清理棋盘、仓库与缓存。','刷新需求状态，发配置奖励，写完成时间线并通知专用视图。'],
 'branch':['完成模型并清除相关链，建立本次有限奖励池。','每轮按剩余份额抽一件，有空位落盘，无空位入缓存。','减掉该件的一份，池耗尽才写完成标记并通知；总件数由配置固定。'],
 'price':['逐需求累加价格和难度，重复物重复计算；缺配置整体返回零。','有基准标记时使用推荐价，再按金币Buff翻倍并向上取整。','最后按亲密度和BakeOut资格决定是否发基础奖励、发哪种资源。'],
 'activity':['按原调用顺序询问各活动资格，收集本次奖励。','限时订单的相册标记可能阻止重复相册奖励；宝箱标记另留给延迟结算。','最后追加基础奖励，分类处理时不保证不同类别仍按此顺序落账。'],
 'snapshot':['按宝箱标记前缀把奖励拆成即时与延迟两份。','复制两份作为交付快照，避免之后重新取奖改变显示结果。'],
 'acquire':['转换动态奖励并按实际类别分组。','将货币交资源处理器，将棋子交缓存处理器；各组走自己的算法。','逻辑落账先完成，稍后的飞行动画只展示这次结果。'],
 'gift_buff':['先检查礼物是否存在、亲密度功能是否开放，再结算礼物。','随后独立检查Buff奖励；它们不自动混入基础奖励快照。'],
 'smile':['先按活动状态与槽位决定本次增加多少微笑分。','符合主游戏资格才更新活动分数和槽位完成计数、保存并通知。','记录首轮普通微笑资格，提示留到结算尾部触发。'],
 'mark':['冻结完成时的奖励供后来显示。','直接把订单标为完成，让后续刷新不再把它改回可交付状态。'],
 'board':['按需求先后，每一件都从棋盘第一格重新查找。','找到精确代码的第一件就删除，记录原需求索引；找不到才转仓库。'],
 'store':['仅当棋盘没找到这件需求时，从仓库第一项顺序查找。','删除第一个精确匹配项和它的保存属性，保留原需求索引；缓存不参与。'],
 'refresh_failure':['每件尝试后重新计数并刷新订单状态。','材料不足只记错误，前面已发奖励和已扣材料不会回滚，仍继续后续结算。'],
 'cooking':['用订单难度匹配当前烹饪Buff档位，决定全奖还是抽奖。','棋子候选优先考虑微笑缺口、普通缺口，再考虑其它可用物。','按可用空格决定落盘或资源逻辑，保留结果给后续动画。'],
 'chest_delay':['先派宝箱完成通知，再依次处理延迟奖励组。','宝箱标记换成难度预算，抽奖励方案，再展开成具体棋子。','能落盘的先生成，其余进缓存，保存展开结果供视图展示。'],
 'owner_history':['找包含旧订单的模型；未找到也不会撤回前面的发奖。','更新Lucky触发资格、累计难度和重复链历史，作为下一单输入。','再交槽位模型完成并补位，注意它的成员校验发生在这些副作用之后。'],
 'loop':['记录旧订单完成，然后扫描全部空槽和已完成槽。','移除旧单，尝试创建新单；成功才保存并放入槽位。','只要本轮有一个成功就再扫一轮；最终刷新并派完成通知。'],
 'priority':['按固定、回归、教程、连续活动、额外顾客、Lucky、普通随机依次尝试。','第一个成功对象结束选择，补头像、礼物和必要编号。','派新单创建消息后返回，随后外层才把对象保存进槽位。'],
 'fixed_return':['固定订单先看下一进度、允许槽位和等级，需求直接读表。','固定未成功才可能检查回归免费资格和八小时计时。','回归单从现有较高等级物中均匀选需求，此时不扣物。'],
 'lucky':['先消耗本次触发资格，再检查配置、等级、连续次数与冷却。','从未被其它单占用的现有库存建立三个候选池，先决定需求数。','逐项抽代码并扣后续池的可用份数，成功或失败分别更新次数与冷却。'],
 'random_gate':['先按槽位选创建器与实际适用配置。','检查等级、批次剩余次数、恢复计时及活动强制补单条件。','资格通过即消耗创建次数，再构造需求；构造失败不退回次数。'],
 'candidates':['读取扣物后的库存与现有需求，先计算链和代码权重倍率。','逐代码累积检查等级、解锁、槽位、上次单与其它单排除条件。','分出主候选与特定条件下可用的备用池，保留实际遍历顺序。'],
 'dynamic':['按等级、累计难度、付费区间找第一条适用过滤档。','检查是否有严格富余的高阶库存，决定哪些链可提高上限。','提高相应候选权重，再按各自链上限筛选；没有富余就保持常规上限。'],
 'draw':['顺序预选第一、第二、第三候选；每次重建候选并更新重复链记录。','之后才抽需求项数，只保留预选的前几项。','保存重复链历史；未最终保留的预选也可能已经影响随机和历史。'],
 'save':['删除旧槽记录并保留上一单需求，供下次排除判断。','保存新单的需求、类型、头像、编号与独立标记。','重载按保存字段恢复对象与礼物，不重新随机需求。'],
 'sync':['所属模型补位与全局通知返回后，再刷新主棋盘状态。','满足首轮微笑资格才提示，随后检查同步上传。','最后派局部完成消息，把奖励和扣物快照交给视图。'],
 'animation':['先锁定滚动、收集本次扣物对象，播放飞入需求格表现。','按原调度顺序展示普通奖励、烹饪、相册、礼物与宝箱；不重发已落账奖励。','顾客离开后移除旧格、恢复滚动并启动后续提示；特殊与分支使用专用动画。'],
}

def build():
    AUDIT.mkdir(parents=True,exist_ok=True)
    before=AUDIT/'before'
    if not before.exists():
        before.mkdir();shutil.copytree(BASE,before/'pages');shutil.copy2(SITE/'mkdocs.yml',before/'mkdocs.yml')
    define()
    refill=next(s for s in STEPS if s['key']=='refill')
    new=[]
    host=dict(nodes=new)
    node(host,'tutorial','教程单：检查解锁、跳过旧教程、进入进行中',
      '固定与回归没有建单时才检查教程。它按当前教程进度读预设需求，不走普通随机；已经不需要的教程会被跳过，资格查询可能推进进度。',
      'TutorialOrderModel读取LocalConfigKey.TutoriaiOrderConfig，ConfigModel实际映射Data.Config.NewItemOrderConfig。持久字段TutorialOrderModel_CurTutorialID为id_state，缺省1_1；Ready="1"、Doing="2"。按配置id查记录，缺记录、Slot不符或非Ready拒绝。SkipItem非nil且已解锁则推进id+1并递归CanCreate当前槽；若UnlockItem==Fishing05，还同时标完成两个海鲜教程。否则UnlockItem未解锁拒绝，已解锁允许。Create按Requirement1..3非nil顺序追加，取头像，先写当前id_Doing，再创建TutorialOrder内类型11，Id=教程id。\n\nSlot完成通知在补位之后派发，OnOrderFinished只比较消息订单Slot与当前教程Slot；Doing则进度id+1_Ready，没有再核对旧单内部类型或Id。LateInit重载遇Doing且该槽无单，同样推进；这决定下一次补位资格，不能误写成首次补位已经使用推进后的id。',
      '本例未指定教程进度，不断言教程分支成功。对照Ready且UnlockItem已解锁、SkipItem未解锁：按表创建教程需求。',
      '对照id1,state1→创建前写1_2；完成消息同槽→2_1。SkipItem已解锁时先写2_1再递归判断，不消耗普通随机点数。',
      ['Board.Model.Order.TutorialOrderModel','Model.ConfigModel',M],configs=('NewItemOrderConfig',),methods=['CanCreate','CreateOrder','OnOrderFinished','GetCurOrderAndState','SetCurOrderAndState','LateInit'])
    node(host,'continuous','连续订单：按本轮档位逐项抽需求',
      '教程未建单才尝试槽18连续订单。活动状态、进度和界面门控都通过后，按本轮三个需求范围逐项抽物；需求项数来自配置，不另抽普通订单的一二三项权重。',
      'CanCreateOrder仅槽18，状态Started或Ended；Ended还要求GetStarted真，index在0..TotalOrderCount闭区间，GetStarted真，主活动窗未打开且m_canCreateOrderFlag不恰为false。不要擅自将index0排除；Create随后直接取m_ordersConfig[index]，有效配置是调用前提。每项GetAvailableItems传alreadyRequiredItems，主池和备用池分别FilterByLevel；主非空用主，否则备用非空用备用，两者空返回nil。每次衰减重复链权重、加权抽Code、加入已需集合、标选中链。第一项后，只有前一项成功且配置有下一项才抽第二/第三；第一项空兜底ItemType.Flour09=209并记错误。最后UpdateMapInfo保存衰减历史，MainOrder.Create槽18、Id=curIndex、内部20、avatar2001、Luckyfalse。\n\n远端m_ordersConfig.item1/2/3.range_entry为含端点等级区间；没有ItemAmounts项数轮盘。这里没有普通动态上限修正。候选备用可以用于每项，不仅第一项；前项失败后跳过后续，即使第一项随后兜底209也不会补抽第二项。',
      '主例槽1不直接创建连续订单；全槽补位可同时检查槽18。对照第一项两池均空，生成209单需求兜底。',
      '对照req1=nil→req=[209]、avatar2001、innerType20；req2和req3未抽。远端区间需实际活动记录，不把演示区间当默认值。',
      ['Contiorders.Model.ContiordersModel',R,'Board.Model.Item.ItemDefinition'],configs=('OrderItemConfig',),methods=['CanCreateOrder','CreateOrder','GetAvailableItems','FilterByLevel'])
    node(host,'extra','额外顾客：创建空需求入口并保存活动标记',
      '连续订单未成功才检查槽19额外顾客。它先创建活动入口单，需求为空；不能套用普通随机需求或把空需求解释为已经可以完整领取活动奖励。',
      '仅槽19，活动Started且eTime−now≥3600；HasActiveOrder真拒绝，主盘槽19已有任何订单对象拒绝。有冷却值时仅now>coolDown允许，等于时拒绝；无冷却值允许。Create再检查槽19，依次SaveHasActiveOrder(true)、SaveNeedBanner(true)、SaveNeedAutoPopTip(true)、SaveFirstAppear(true)，删CoolDownTime与LimitTime，创建EmptyReqOrder槽19、Idnil、需求{}、内部21、头像3001、Luckyfalse。后续外层给Random大类生成Id并添加礼物，派创建事件，再由Slot保存对象。四个保存函数与EmptyReqOrder活动奖励/入口覆盖是活动独立状态链，不可用普通空需求CanDeliver=true推断最终活动交付奖励。',
      '主例槽1普通交付跳过这条专用创建；全槽扫描时槽19仅符合活动资格才创建空需求入口。',
      '对照剩余3600秒允许，3599秒拒绝；coolDown=1000、now1000拒绝、1001允许。这些边界来自比较运算，不是猜测。',
      ['ExtraCustomerActivity.Model.ExtraCustomerActivityModel','Board.Model.Order.EmptyReqOrder',M],methods=['CanCreateOrder','CreateOrder','SaveHasActiveOrder','SaveNeedBanner','SaveNeedAutoPopTip','SaveFirstAppear'])
    insert=next(i for i,n in enumerate(refill['nodes']) if n['key']=='lucky');refill['nodes'][insert:insert]=new
    new[-1]['detail']+='\n\nEmptyReqOrder明确覆盖空需求：Init标Dormant；Dormant时CanDeliver=false、GetRewards为空、GetBuffRewards/GetCookingFrenzyConfig=nil、GetScore/GetDiffScore为0，所以不会用BaseOrder空数组通过来直接交付。TryRefreshMyRequirements先调用普通随机构造；有对象且需求非空才UpdateRequirements并记refresh日志；对象非nil但空需求时无兜底。只有构造nil才用传入defaultReq或Flour12=212，更新需求、日志并记错误。它只更新旧对象需求，不把临时随机对象整个保存替换。'
    FLOWS.update(tutorial=['读取当前教程进度和预设配置，检查槽位与是否待创建。','已解锁跳过物就推进并递归，否则要求目标母体解锁。','保存进行中状态再建单；完成通知之后推进下一教程。'],continuous=['检查活动、槽位、进度和窗口门控。','按配置范围逐项建立候选，主池失败才用备用；第一项全空用209。','保存重复链状态，再创建固定项数的连续订单。'],extra=['检查槽19、活动剩余时间、已有入口与严格冷却边界。','保存活动入口标记并清除旧计时。','创建空需求入口单，交外层补编号和保存。'])
    CONFIG_MEANINGS['NewItemOrderConfig']='id是教程进度；Slot限定槽位；UnlockItem要求已解锁；SkipItem已解锁时跳过该教程；Requirement1..3按原序作为预设需求，不参与随机项数抽取。'
    for s in STEPS:
        for n in s['nodes']:
            n['icons']=tuple(c for c in n['icons'] if c!='2401')
            n['detail']=n['detail'].replace('m_itemCodeCount','m_codeCountMap')
            for sentence in (
                '这里完整给出订单直接收集顺序，各活动完整奖励闭包仍须依其代码和账号配置核销。',
                '教程/连续/额外顾客的完整专用构造和远端配置另有依赖，不能在此把它们默认为普通随机。',
                '事件所有监听的奖励/任务/延迟回调仍需逐个闭合，不能因直接顺序明确就批准全量消费者。',
                '但辅助函数中额外活动领取和锁定回调仍须按源码逐一核销。',
            ):n['detail']=n['detail'].replace(sentence,'')
    chest=next(n for s in STEPS for n in s['nodes'] if n['key']=='chest_delay')
    chest['detail']+='\n\n### 缺口定向奖励的完整预算过程\n\n先复制棋盘加仓库的计数（不含缓存），以pairs遍历所有未完成订单，再按各单需求顺序消耗这份共享库存；不够的代码列入该单缺口，累加其DiffScore。缺配置需求略过。订单按缺口难度从小到大排序，同分未另设稳定排序。依次处理：预算已经≤0停止；预算+10≥该单缺口总分，直接发全部缺口并扣总分，允许最多10分的超预算。否则按单内代码DiffScore升序处理，预算够整件就发整件并扣分；不够则降阶补足。\n\n旧降阶算法沿同链从当前等级向下，找到第一件有配置且DiffScore≤21的代码；发ceil(剩余预算/该件DiffScore)份并逐份扣预算，允许末份超预算。优化分支还要求RewardStockCount开关：按CalculateOrderCodeLackNumMap(false,true,false)取得合成等价值缺口，每份低阶物扣2^(等级−1)等价值；只在此目标仍有缺口时发，预算或缺口任一个耗尽就停止。找不到有效≤21分代码直接跳过，不替换成任意物。整件分支同步减少缺口且下限钳至0，降阶分支可减至负数。\n\n完成缺口后若预算仍>0，收集玩家等级可用、任一母体已解锁的5级代码；空集合用205。每轮从集合等权有放回抽一件，扣其DiffScore直到预算≤0。这些步骤使用同一预算，不能将每个订单分别重新赋预算。远端chestOrderScoreConfig与chestOrderRewardConfig决定实际分档、比例、方案权重和成本；当前包没有账号实际活动记录，因此给出算法和字段含义，不编造默认档位。'
    chest['calc']+='\n\n对照普通方案预算5、仅一个候选成本3：等权选两次，具体发两件，每件count1，总成本6、预算−1。对照缺口总分14、预算4：4+10≥14，整组交付后预算−10；这是阈值边界的演示，不是远端配置。'
    configs=prepare_configs();nodes=[n for s in STEPS for n in s['nodes']];records,listeners=inventory(nodes)
    p=BASE/'index.md';p.write_text('# 订单提交\n\n一次交付包含输入确认、模型结算与表现三个时间段。普通订单可能先询问仓库；进入模型后先分流特殊/分支，普通路径先发奖再扣物，再处理扣物后的活动与延迟奖励，之后更新历史、补新订单，最后同步与播放表现。\n\n## 本次操作的真实顺序\n\n| 顺序 | 做什么、为什么 | 分支与结束位置 |\n| --- | --- | --- |\n'+ '\n'.join(f'| {i} | {s["title"]} | {s["overview"]} |' for i,s in enumerate(STEPS,1))+case(p,dict(case='203×2与204×1的需求，首次棋盘检查缺204，确认用仓库后得到8金币，消耗三件物，累计难度加9并尝试补位；能量不变。',icons=('203','204','2401'))),encoding='utf-8')
    nav=['operations/orders/index.md'];mapping=[];expected={p}
    for s in STEPS:
        d=BASE/s['key'];d.mkdir(parents=True,exist_ok=True);p=d/'index.md';expected.add(p)
        p.write_text('# '+s['title']+'\n\n'+s['overview']+'\n\n## 本阶段的判断与处理顺序\n\n'+'\n\n'.join(f'{i}. **{n["title"]}**：{n["overview"]}' for i,n in enumerate(s['nodes'],1))+case(p,dict(case=s['case'])),encoding='utf-8')
        snav=[p.relative_to(DOCS).as_posix()];nav.append({s['title']:snav})
        for n in s['nodes']:
            d=BASE/s['key']/n['key'];d.mkdir(parents=True,exist_ok=True)
            p=d/'index.md';expected.add(p);p.write_text('# '+n['title']+'\n\n'+n['overview']+'\n\n## 内部处理顺序与目的\n\n'+'\n\n'.join(f'{i}. {v}' for i,v in enumerate(FLOWS[n['key']],1))+case(p,n),encoding='utf-8')
            p=d/'detail.md';expected.add(p);p.write_text('# '+n['title']+'：具体算法与配置\n\n'+n['detail']+'\n'+table_text(p,n,configs)+evidence(p,n)+case(p,n,True),encoding='utf-8')
            snav.append({n['title']:[(d/'index.md').relative_to(DOCS).as_posix(),{'具体算法与配置':p.relative_to(DOCS).as_posix()}]})
            mapping.append(dict(id='ORDER::'+s['key']+'::'+n['key'],page=p.relative_to(DOCS).as_posix(),modules=n['modules'],method_selectors=n['methods'],status='documented-rules; full-closure-pending'))
    text=(SITE/'mkdocs.yml').read_text(encoding='utf-8');match=re.search(r'(?m)^  -\s+订单提交:',text);end=re.search(r'(?m)^extra_css:',text[match.start():]).start()+match.start()
    subtree='\n'.join('  '+l for l in yaml.safe_dump([{'订单提交':nav}],allow_unicode=True,sort_keys=False,width=1000,indent=4).splitlines())+'\n\n'
    (SITE/'mkdocs.yml').write_text(text[:match.start()]+subtree+text[end:],encoding='utf-8')
    archived=[]
    for old in BASE.rglob('*.md'):
        if old not in expected:
            assert old.resolve().is_relative_to(BASE.resolve());archived.append(old.relative_to(BASE).as_posix());old.unlink()
    historical=[p.relative_to(before/'pages').as_posix() for p in (before/'pages').rglob('*.md') if BASE/p.relative_to(before/'pages') not in expected]
    (AUDIT/'archived_pages.json').write_text(json.dumps(sorted(set(archived+historical)),ensure_ascii=False,indent=2),encoding='utf-8')
    (AUDIT/'document_map.json').write_text(json.dumps(mapping,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(dict(stages=len(STEPS),mechanisms=len(nodes),pages=len(expected),config_modules=len(configs),candidate_modules=len(records),listeners=len(listeners)),ensure_ascii=False))

if __name__=='__main__':build()
