"""Scoped drag/merge documentation, independent source inventory and evidence.

Only edits the merge nav subtree and merge pages. Name matches never approve
semantic coverage. Originals are backed up before the first write.
"""
from pathlib import Path
import hashlib
import html
import json
import os
import re
import shutil
import yaml

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'analysis_output/logic_recovery/stage3'
SITE = STAGE / 'mkdocs_site'
DOCS = SITE / 'docs'
BASE = DOCS / 'operations/merge'
AUDIT = STAGE / 'merge_gate_audit'
MODULES = json.loads((ROOT / 'analysis_data/logic_index/lua_modules.json').read_text(encoding='utf-8'))
BY_NAME = {m['name']: m for m in MODULES}


def source(name):
    return ROOT / BY_NAME[name]['source_path']


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inventory():
    AUDIT.mkdir(exist_ok=True)
    snapshot = AUDIT / 'before'
    if not snapshot.exists():
        snapshot.mkdir()
        shutil.copytree(BASE, snapshot / 'pages')
        shutil.copy2(SITE / 'mkdocs.yml', snapshot / 'mkdocs.yml')
    names = [
        'Board.View.MainBoardView', 'Board.View.BaseActionBoardView',
        'Board.Model.Board.MainBoardModel', 'Board.Model.Board.BaseBoardModel',
        'Board.Model.Board.BaseActionBoardModel', 'Board.Model.Board.BaseItemLayerModel',
        'Board.Model.Board.MainBoardItemLayerModel', 'Board.Model.Base.BoardPosition',
        'Board.Model.Item.ItemModel', 'Board.Model.ItemModelFactory',
        'Board.Model.Item.ItemSwallow', 'Board.Model.Item.ItemTransform',
        'Board.Model.Item.ItemSplit', 'Board.Model.Item.ItemPaperBox',
        'Board.Model.Item.ItemCobweb', 'Board.Model.Board.ItemFixedSwallowModel',
        'BubbleDecrease.Model.BubbleDecreaseModel', 'TempItem.Model.TempItemModel',
        'TempItem.Board.ItemTemp', 'EnergyBubble.Model.EnergyBubbleModel',
        'ScoreRace.Model.ScoreRaceModel', 'CardItem.CardItemModel', 'Common.Event.PairEvent',
    ]
    # Include attached downstream evidence in the next audit pass. This is a
    # candidate inventory, not approval of membership or semantic completeness.
    map_path = AUDIT / 'document_map.json'
    if map_path.exists():
        mapped = json.loads(map_path.read_text(encoding='utf-8'))
        names = list(dict.fromkeys(names + [name for entry in mapped for name in entry['source_modules']]))
    records=[]
    for name in names:
        p=source(name); lines=p.read_text(encoding='utf-8').splitlines()
        starts=[i for i,l in enumerate(lines) if re.match(r'^function\s',l)]
        funcs=[]
        for k,i in enumerate(starts):
            end=starts[k+1] if k+1<len(starts) else len(lines)
            identifier=lines[i].split('(')[0].removeprefix('function ')
            units=[{'id':f'{name}::{identifier}::L{j+1}', 'line':j+1,'text':lines[j].strip(),'semantic_review':'pending'}
                   for j in range(i,end) if re.search(r'\b(if|elseif|for|while|return)\b|DispatchEvent|:Call\(|:Set\(|self\.m_\w+\s*=',lines[j])]
            funcs.append({'id':f'{name}::{identifier}', 'identifier':identifier,
                          'line':i+1,'end_line':end,'logic_candidates':units,
                          'review_status':'pending'})
        records.append({'module':name,'source':p.relative_to(ROOT).as_posix(),
                        'source_sha256':sha(p),'bytecode_sha256':BY_NAME[name]['sha256'],
                        'functions':funcs,'scope':'dependency candidate, not automatic operation membership'})
    events=('ItemMerged','ItemShocked','ItemMoveEnd','BoardPointerUp','StartDraggingItem',
            'ItemSwallow','ItemTransform','BubbleSpread','CardItemGenerate','OrderStateChanged')
    listeners=[]; seen=set()
    for m in MODULES:
        if m['sha256'] in seen: continue
        seen.add(m['sha256'])
        p=ROOT/m['source_path']
        if not p.exists(): continue
        for i,line in enumerate(p.read_text(encoding='utf-8').splitlines(),1):
            if ('AddListener' in line or 'REGISTER_BOARD_EVENT' in line or 'AddHandler' in line) and any(e in line for e in events+('MergeItem','SplitItem','SwallowItem','TransformItem')):
                listeners.append({'id':f"{m['name']}::registration::L{i}", 'module':m['name'],'source':m['source_path'],'line':i,
                                  'registration':line.strip(),'review_status':'pending'})
    (AUDIT/'source_inventory.json').write_text(json.dumps({'modules':records,'listener_candidates':listeners,
        'warning':'Whole modules include unrelated functions. Candidate extraction misses implicit/dynamic calls; no semantic approval is inferred.'},ensure_ascii=False,indent=2),encoding='utf-8')
    return records,listeners


# Each tuple is one actual stage; children are substeps, not topic buckets.
STEPS=[]


def stage(key,title,overview,example):
    entry={'key':key,'title':title,'overview':overview,'example':example,'children':[]}
    STEPS.append(entry)
    return entry


def node(parent,key,title,overview,detail,example,calculation,modules,config=None,icons=()):
    parent['children'].append(dict(key=key,title=title,overview=overview,detail=detail,
        example=example,calculation=calculation,modules=modules,config=config,icons=icons))


def define():
    s=stage('release','释放拖拽：确认落点与源对象',
'''拖动中的图像位置只是预览。松手后，视图先把屏幕位置换成棋盘格，处理最近合成高亮的短暂吸附和教程指定落点，再检查拖入棋子能否移动。指针落在仓库上时先尝试存入；存入失败才回到棋盘处理。

进入棋盘模型后，依次检查目标坐标是否合法、源格是否仍是这只棋子。任一步不通过就复位并结束，不再尝试特殊作用、合成或交换。这样可以防止拖动期间对象已经消失或被替换，却仍用过期图像修改棋盘。''',
    '玩家把源格的201拖向另一只201。棋子没有被锁住，也没有落在仓库或教程禁用的位置；源格仍是同一对象，因此允许解释目标格。')
    node(s,'movable','开始拖动与移动资格',
'''先检查拖入棋子能否移动。纸箱、蜘蛛网、锁定物不能作为拖动源；吞噬物还取决于它是否允许点击。首次有效拖动通知教程和界面，之后图像跟随手指，棋盘模型尚未换格。''',
'''`CanItemMove`按顺序检查ItemPaperBox/ItemCobweb、ItemLocked，再读取ItemSwallow。前三类存在时返回false；没有吞噬组件返回true；有则返回AllowTap。AllowTap来自`Swallow_AllowTap ~= 0`，缺省nil也会得到true，不能擅自当false。

`_OnDrag`要求m_lastTouchedItem及其模型非nil。首次`not m_dragging and canItemMove`时派发StartDraggingItem，刷新指示器、完成格与作用效果；随后设m_dragging=true，即使不可移动也设置此标记，但立即返回不移动图像。可移动时用ScreenToWorldPoint投影，图像z设0；Inventory悬停进/出播放按钮效果；最后尝试合成高亮。移动许可不等于合成许可：蜘蛛网不能拖动，但可以作为合成目标。''',
    '201是普通食物，可以被拖动；源格内容此时没有改变。',
    '201没有PaperBox/Cobweb/Locked/Swallow组件，CanItemMove=true。首次拖动发StartDraggingItem；m_dragging变true，格层仍保存源物ID。',
    ['Board.View.MainBoardView','Board.Model.Board.BaseBoardModel','Board.Model.Item.ItemSwallow'],icons=('201',))
    node(s,'position','屏幕落点、吸附与教程限制',
'''松手位置先转为格坐标。刚显示过的合成高亮可以在短时间内把落点吸到对应棋子；教程指定目标不满足时改成非法坐标。它们改变传给模型的落点，不改变普通合成的代码匹配规则。''',
'''`_OnPointerUp`先清合成灯光，用相机ScreenToWorldPoint和_GetBoardPosition得到落点。最近可合成物存在且`timeSinceLevelLoad-lastTime < 0.15`时，分别检查x差平方≤1、y差平方≤1，成立则用该物位置。这是每轴相差最多1格，包含斜对角，不是曼哈顿距离≤1，也不是0.15秒防抖。

强制教程目标非nil且与落点不同，改为BoardPosition.Create(0,0)。然后计算boardPositionChanged，清最近高亮缓存，结束仓库悬停效果。视图的吸附时间使用Unity运行时间，模型资格使用棋盘状态，两种来源不能混用。

异常指针退出会ResetPressedState；源仍可移动时DragItem到(0,0)，通过模型非法位置路径复位，再清指针、指示器和信息栏。''',
    '松手对准目标201；没有最近高亮吸附或强制教程改写，目标格保持不变。',
    '演示源S=(3,3)、目标T=(4,3)，无强制目标。对照：高亮在(4,4)，经过0.10秒且松手(3,3)，每轴差都为1，会吸附(4,4)；恰好0.15秒不吸附。',
    ['Board.View.MainBoardView','Board.Model.Base.BoardPosition'])
    node(s,'inventory','仓库落点的优先分流',
'''指针落在仓库按钮上时，先检查仓库是否开启、物品是否能存、仓库是否有容量。成功则从棋盘移入仓库，本次不进行棋盘合成；失败会提示原因，再按实际棋盘落点继续分派。''',
'''视图要求raycast对象名恰为Inventory。功能开启才StoreItem；关闭时显示锁定提示。stored默认false，成功才设true并播放入库效果；没有成功则DragItem(item,target,false)。当前DragItem定义只有两个形参，额外false不会被使用，不能推断其关闭订单刷新。

CanItemStore先CanItemMove，再拒绝Bubble/Temp/PropertyBubble、带Duration的Transform、Opening状态Spread及当前工厂专用物（返回GeneratorFactory原因）。StoreItem先资格再容量：失败派StoreFailed，Reason用具体原因或CannotStore；满仓为InventoryFull。

成功先_SetItem(原格,nil,false)，再m_itemStoreModel:AddItem；CountItemsCode、UpdateOrderState；写StoreItem日志；局部StoreItem；全局InventoryStoryItem。仓库仍纳入订单计数，但不能把移入误写成消耗物品。''',
    '本例落在棋盘目标201，没有尝试存入。对照：把松手位置改为仓库，201可存且仓库有空位时进入仓库，取消这次合成。',
    '本例raycast.name≠Inventory。对照stored=true时不会调用DragItem；stored=false时保留已计算棋盘坐标，包括教程可能改写的(0,0)。',
    ['Board.View.MainBoardView','Board.Model.Board.MainBoardModel'])
    node(s,'identity','坐标与源身份的最后核对',
'''先排除棋盘外落点，再核对源格对象。如果拖动期间源格被替换，旧棋子的拖动也会被拒绝。这两项先于读取目标棋子，防止过期输入继续执行。''',
'''主棋盘HorizontalTiles=7、VerticalTiles=9。PositionIsValid要求`1≤x≤7 and 1≤y≤9`；失败执行item:SetPosition(item:GetPosition())并return。

其次GetItem(item:GetPosition())必须与item对象相等，不能仅比较Type或ID字符串。不同对象即复位并return。SetPosition即使传原位置，也派ItemEventType.SetPosition，供视图播放回位；不是写一次新的格层记录。

DragItem模型入口本身没有再次调用CanItemMove(source)，依赖正常视图入口；直接测试调用模型不能假定它自动拒绝所有不可移动源。''',
    '目标格在棋盘内，源格仍是被拖动的201，因此进入目标格分派。',
    'S=(3,3)、T=(4,3)，两坐标合法；GetItem(S)==source。对照旧source被新201替换时，即使Type同为201也返回；(0,0)越界也返回。',
    ['Board.Model.Board.MainBoardModel','Board.Model.Board.BaseBoardModel','Board.Model.Item.ItemModel'])

    s=stage('move','空格或原格：移动后立即结束',
'''取得目标后，如果目标为空，或者目标就是拖入棋子本身，就走移动路径。先更新格层，再记录位置和刷新加速影响，发移动结束通知，随后返回。因此空格移动不会继续抽副产物，也不会把普通移动当成合成。

原格松手也经过这条路径，位置日志被省略，但移动结束通知仍然发送。''',
    '贯穿合成例的目标格有另一只201，所以跳过移动。把同一拖动的目标改为空格，201直接移过去，类型与能量保持不变。')
    node(s,'write','写格、原格复位与位置日志',
'''空位移动沿用原棋子对象，不新建物品或重置母体次数。回到原格时也会清格再写回，但省略移动日志，随后进入移动收尾。''',
'''条件`targetItem==nil or targetItem==item`。先_SetItem(sourcePos,nil,false)，再_SetItem(targetPos,item,false)。目标不是源自身时_LogMove；最后SetPosition(targetPos)。两次写格都明确false，不在此刷新订单。

MainBoardItemLayerModel:SetItem检查位置有效，移除原占用时空格数+1/从m_mapItems删除；写数据库position.GetKey()→itemId，空值则Remove；更新二维m_items；新占用空格数−1并加入m_mapItems。因此正常移动空格总数不变。ItemModel:SetPosition更新内存并派位置事件；格位置持久化在格层表，不靠SetPosition自动保存棋子配置。

_LogMove记录棋子code、源/目标坐标、特定活动日志参数；原格分支省略这一日志。正常路径没有资源扣除API，也没有普通合成事件。''',
    '本例T被占用，不执行移动。空格对照：201从S移到T，S空出，T仍是原对象。',
    '对照T为空：_SetItem(S,nil,false)→_SetItem(T,source,false)→LogMove→SetPosition(T)。原格T=S时仍写两次格，不写LogMove，但会进入收尾。',
    ['Board.Model.Board.MainBoardModel','Board.Model.Board.MainBoardItemLayerModel','Board.Model.Item.ItemModel'],icons=('201',))
    node(s,'accelerate','移动后的加速刷新与通知',
'''移动可能改变加速棋子的覆盖，所以移动完成后立即刷新计时组件。随后通知移动结束并返回；这次拖动的合成、吞噬和交换均不会执行。''',
'''_UpdateAccelerate对源/目标依次检查：Spread存在且CanAccelerate；或Transform存在且CanAccelerate；或Accelerate存在且IsActivated。任一对象满足就连续调用UpdatePerSecond两次，不是按移动距离增加秒数。Transform.CanAccelerate要求duration与startTimer都非nil。

之后全局ItemMoveEnd消息为`{item=item}`，再return。原格复位也会走这段；交换分支调用同一加速更新却没有此处的ItemMoveEnd。通知的监听可产生后续行为，不能据模型函数return断言全局监听无副作用。''',
    '本例合成目标非空，移动收尾不执行。空格对照的201无计时/加速组件，只发移动结束。',
    '对照201：checkFunc(source)=false、target=nil，所以UpdatePerSecond次数0，ItemMoveEnd一次。换成正在计时的母体，则调用两次UpdatePerSecond，类型与计时结果由组件更新决定。',
    ['Board.Model.Board.MainBoardModel','Board.Model.Item.ItemTransform'])

    s=stage('special','有目标：先尝试特殊作用',
'''有目标时，先判断拖入物能否对目标产生特殊作用。升级道具和普通剪刀通常弹确认窗；窗口已打开就结束当前拖拽，确认后再复核资格并执行。两把剪刀则直接合并剩余次数。

特殊作用没有接管时继续普通合成。特殊物不能作用会先给失败提示，但提示本身不阻断后续合成、吞噬或交换。''',
    '201没有特殊类型，特殊作用不接管，也没有失败提示，继续检查普通合成。以下对照更换拖入物，分别说明升级道具和剪刀。')
    node(s,'eligibility','目标资格与满盘限制',
'''资格由目标配置决定：目标是否允许被升级或拆分。剪刀对普通目标还要求棋盘有空位；两把剪刀合并次数例外，不受这个满盘限制。''',
'''CanItemAffect转发target:CanSpecialTypeAffect(source:GetSpecialType())。specialType=nil立即false。目标本身SpecialType=LevelDown且传入也是LevelDown，直接true；否则m_mapSpecialTypeTarget必须存在且该key为true。映射在ItemModel._Init中遍历ItemSpecialType2ConfigKey，仅配置值恰为1才标记。

LevelDown普通目标再要求not board:IsBoardFull()；其它目标通过映射便true。普通配置字段LevelUpPiece/LevelDownPiece=1给出许可，不代表每件棋子都可升级/拆分。模型确认回调再次核对该资格，但没有在此重新校验源格身份/对象仍在棋盘的全部条件，不能擅自补成事务保护。''',
    '201.SpecialType缺省，资格false。对照202允许升级和拆分；201仅允许升级。',
    '默认201：LevelUpPiece=1、无LevelDownPiece；202两字段均1。source=level_down_piece_1作用202时，非满盘才通过；两剪刀即使满盘也通过。',
    ['Board.Model.Item.ItemModel','Board.Model.Board.MainBoardModel'],config='special')
    node(s,'upgrade','升级确认与目标替换',
'''升级道具把目标替换为其配置下一等级，消耗一件升级道具。等待确认时道具回原位；取消不执行替换。该路径有合成通知和邻格震动，但不经过普通合成的副产物流水线。''',
'''SpecialType=LevelUp打开UseSpecialItemConfirmWindow，参数源Type、目标Type、目标MergedType、nil、场景rainbow_item_use_confirm。外层立即SetPosition(原位置)并return true，截断普通分派。

确认回调CanItemAffect仍true时RemoveItem(source)，ReplaceItem(target,target.MergedType)，局部MergeItem→全局ItemMerged→ShockNeighborItems(T)→ItemShocked→BI LogMerge(ext.levelup=1)，最后window.Close。message仅Source/Target/New，不带普通合成的itemType/isFirstUnlock。不是调用MainBoardModel:_DoMergeItem，故没有它追加的ScoreRace直接计分、临时/卡片/气泡/金币检查；全局监听仍可运行。''',
    '主例无升级道具。升级对照：把level_up_piece_1拖到202并确认，目标变203，道具消失；这次不走普通合成副产物。',
    '本地202.MergedType=203、LevelUpPiece=1。确认前棋盘不变；确认后源移除、T生成203，ext.levelup=1；若资格变false只关闭窗口。',
    ['Board.Model.Board.MainBoardModel','Board.Model.Item.ItemModel'],icons=('202',))
    node(s,'scissors','两把剪刀合并剩余次数',
'''目标也是剪刀时，不打开拆分确认窗；两把剪刀合成一把，其次数为两者剩余次数之和。它保留使用量，不把次数恢复成默认值。''',
'''LevelDown目标分支先获取两边ItemSplit组件，RemoveItem(source)→RemoveItem(target)→GenerateItem(T,target.Type)。新剪刀初始化默认次数1，随即SetSplitUseCount(targetCount+dragCount)覆盖并保存。

派局部MergeItem、全局ItemMerged，日志scissor=合计次数，return true。没有震动邻格，也没有调用普通合成流水线。ItemSplit.CostSplitUseCount每次m_count−1并SaveItemProperty；HasLeftSplitUseCount用严格>0；SetSplitUseCount赋值并保存，无上限截断。''',
    '主例两边是201，无剪刀。对照剩余2次和3次的剪刀合并后，只留一把5次剪刀。',
    '演示dragCount=2、targetCount=3，newCount=5；新对象默认1被5覆盖；满盘资格也通过，因为剪刀同类分支先于空位检查。',
    ['Board.Model.Board.MainBoardModel','Board.Model.Item.ItemSplit'],config='special')
    node(s,'split','拆分确认、扣次数与第二落点',
'''剪刀作用普通目标时，将目标拆为两件同链前一级物品，消耗一次剪刀次数。第一件放在目标原格，第二件按周围空位顺序放下；剪刀次数耗尽才删除。''',
'''从目标type读取chainId、level、chain，prevType=chain[level−1]；打开确认窗，两个结果参数都为prevType，场景scissor_item_use_confirm。外层复位剪刀并return true。

确认再CanItemAffect；CostSplitUseCount先减1并保存；剩余≤0则RemoveItem剪刀。RemoveItem(target)；GenerateItem(T,prevType)；FindEmptyPositionInSpreadOrder(T)；GenerateItem(otherPosition,prevType)。局部SplitItem消息含Split/Target/New1/New2，LogSplit记录scissor=1，_TryLogBoardFull，最后关窗。没有全局ItemMerged或ItemShocked，也不检查普通合成副产物。

落点扫描从T左下角环的第一步开始：右、上、左、下，每边2r步，半径1到max(宽,高)−1，取首个合法空格，跳过中心；不是随机位置。正常资格要求非满盘，确认时复核。若重入等使第二位置nil，GenerateItem仍可创建并保存无格位置对象，因为只在position非nil时写格；源码没有回滚，不能发明自动缓存或取消分支。''',
    '主例没有剪刀。拆分对照：把剪刀拖到202，确认后得到两个201。',
    '202为链第二级，chain[1]=201。演示剪刀剩余1→0并移除；T生成201。其它格全满而剪刀在S=(3,3)、T=(4,3)时，第二件最终落入腾出的S；若剪刀仍有次数，则要求已有另一空位。',
    ['Board.Model.Board.MainBoardModel','Board.Model.Board.BaseItemLayerModel','Board.Model.Item.ItemSplit'],icons=('201','202'))
    node(s,'failure','失败提示后继续普通分派',
'''特殊物不满足目标资格时显示原因，但仍继续合成资格检查。弹出确认窗与显示失败提示的控制流不同：前者接管拖拽，后者通常继续。''',
'''CanItemAffect=false且source.SpecialType非nil时_ShowAffectFailTip。LevelUp提示hint_not_upgrade；LevelDown先IsBoardFull，满则hint_board_full，否则hint_not_split；其它SpecialType无这两类提示。

之后仍CanItemMerge→Swallow→目标移动检查→交换。_AffectItem仅LevelUp/LevelDown处理，未知特殊类型即使CanItemAffect=true也可能return false而继续。不能把SpecialType非nil等同于“禁止普通合成”。''',
    '201没有特殊类型，不显示失败提示。对照：升级物拖到不允许升级的目标，提示后仍可能交换位置。',
    'source.SpecialType=LevelUp，target映射不含LevelUp：CanItemAffect=false，提示hint_not_upgrade；不return，继续CanItemMerge。',
    ['Board.Model.Board.MainBoardModel'])

    s=stage('normal','普通合成：生成新物，再依次结算',
'''特殊作用未接管，才判断普通合成。两边逻辑类型相同且有下一等级、没有已使用宝箱和工厂限制时，消耗两件输入，在目标格创建新物。随后发合成通知、震动四邻格，再进入主棋盘追加结算。

追加顺序为：清购买气泡记忆 → 竞速计分 → 临时棋子 → 卡片 → 能量气泡 → 普通气泡 → 金币 → 同步检查 → 合成日志。临时、卡片、能量气泡、普通气泡相互占用一个主副产物位置；金币独立检查。所有条件都在实际执行时读取，所以同步监听或邻格变化可能影响后续空位与状态。完成后立即返回，不再吞噬或交换。''',
    '两个201合成202，源格空出，目标出现202。演示关闭相关活动且邻格无障碍；202基础气泡概率0，链等级2低于默认金币阈值8，所以只得到202，能量不变。')
    node(s,'eligibility','使用状态、内含类型与下一等级',
'''先排除任一已用过的一次性宝箱，再取得两侧用于比较的类型。蜘蛛网和临时物使用内含物代码；普通物提供下一等级。最后排除工厂专用物，确认同类型且仍能升级。''',
'''CanItemMerge先读取两侧ItemSpread；任一IsChestUsedOnce即false。依次检查每侧`ItemCobweb or ItemTemp`，有则比较InnerItemCode；无则比较GetType并把mergedType写为该侧GetMergedType。第二个普通侧会覆盖第一个mergedType，即使它为nil；不能改成“任一侧非nil就通过”的泛化公式。

工厂功能与判定方法都存在、IsGeneratorFactoryOpen=true、IsGeneratorFactoryItem(itemType1)=true则false。最终`itemType1==itemType2 and mergedType~=nil`。不额外检查目标CanItemMove，所以普通201可以拖向蜘蛛网内201；纸箱/锁定不能被错误地一概套用为合成目标拒绝条件，须按组件和实际类型判断。

MergedType从ItemModelConfig复制到实例，不由数字Type+1推算；最高级缺省nil。两包装物都不提供mergedType，不能合成。生成结果选择又是独立规则：源非Temp用源MergedType，源Temp用目标MergedType。''',
    '两只201逻辑类型一致，都配置下一等级202，既不是已用宝箱，也不受工厂限制，因此合成成立。',
    'Type1=201、Type2=201、mergedType=202→true。最高级同码但MergedType=nil→false。两蜘蛛网即使内含201相同，也没有普通物提供下一等级。',
    ['Board.Model.Board.BaseBoardModel','Board.Model.Item.ItemModel','Board.Model.Item.ItemSpread'],config='merge',icons=('201','202'))
    node(s,'replacement','移除输入、创建与保存结果',
'''先删除拖入物，再用新物替换目标。新物按配置重新创建组件和状态，不沿用两件输入的次数、CD或对象身份；普通合成之后才通知其它系统。''',
'''BaseBoardModel._DoMergeItem：RemoveItem(source,false)，源非Temp则mergedType=source.MergedType，否则用target.MergedType；itemType始终source.Type。生成前IsUnlocked(mergedType)，isFirstUnlock只在返回nil时为true。

ReplaceItem先RemoveItem(target,false)，GenerateItem(T,mergedType,autoUpdateOrderState)。MainBoardModel._DoMergeItem当前只有三个形参，调用基类也没有传autoUpdateOrderState，因此本路径通常nil；最终_SetItem刷新CountItemsCode、UpdateOrderState。GenerateItem先ItemModelFactory.CreateWithCode(默认needUnlockType=true)，SaveItemProperty，再position非nil时写格，最后登记MergeAll忽略集合。

RemoveItem先清格，再ItemManager.RemoveItem删除持久化对象；Opening宝箱还UpdateOpeningItem。创建普通物从GetModelConfig读取配置；SetUnlocked；解析StateCollection并建立组件：Spread、Transform、Swallow、Collectable、Choose、Command、Accelerate、Split等按相应字段存在性决定。新母体Spread重新Init，不能把两旧母体剩余次数相加；剪刀特殊合并才明确相加。

顺序不是数据库原子事务，创建缺配置或同步消费者出错的实际失败边界须保留，源码没有统一回滚。''',
    '删除两只201，在T保存一个新的202；S为空。订单在新物写格后看到更新后的物品数量。',
    '默认201.MergedType=202，源非Temp。Remove(source,false)→Remove(target,false)→Create202→Save→SetItem(T,new,nil)→Count/UpdateOrder。演示202未解锁时isFirstUnlock=true；已解锁时false。',
    ['Board.Model.Board.BaseBoardModel','Board.Model.Board.MainBoardModel','Board.Model.Board.BaseActionBoardModel','Board.Model.ItemModelFactory'],config='merge',icons=('201','202'))
    node(s,'notify','合成通知与四邻格震动',
'''新物已经写入棋盘后，先通知合成，再震动目标周围四个正交邻格。可解锁纸箱会在震动中消除，并可能腾出空间；这些变化发生在副产物判断之前。''',
'''message含Source/Target/New/itemType/isFirstUnlock。局部BoardEventType.MergeItem先于全局ItemMerged；PairEvent按注册数组从1到#handlers同步执行。随后ShockNeighborItems(T)按dir1..4，偏移(1,0)、(0,1)、(−1,0)、(0,−1)，读取当时邻格对象并DispatchComponentEvent(OnShock)；再全局ItemShocked。不是八邻格，也不递归震动所有棋子。

ItemPaperBox.OnShock仅not IsItemPaperBoxLocked才CollapseItem(position)；Try2Unlock的等级解锁路径还要求UnlockLevel>0。Collapse将内含物替换到原格，局部CollapseItem与全局PaperboxDisappear等通知在自身调用内发生。带蜘蛛网的纸箱内含编码由Factory决定，消箱不一定得到裸普通物。

ItemMerged消费者可包括卡片链、教程、解锁表现和活动；必须按各自注册及资格判断，不能认为所有订阅都无条件加分。主棋盘ScoreRace的直接计分在下一个调用位置，不是上述通知自动等价完成。''',
    '本例四邻格无纸箱，仍发送合成与震动通知，没有新增空位。对照邻格有已解锁纸箱时先消箱，再检查副产物。',
    'T=(4,3)，检查(5,3)、(4,4)、(3,3)、(4,2)；S=(3,3)已被删除，因此该邻格无OnShock。顺序MergeItem→ItemMerged→四邻OnShock→ItemShocked。',
    ['Board.Model.Board.BaseBoardModel','Board.Model.Item.ItemPaperBox','Common.Event.PairEvent','Board.View.MainBoardView'])
    node(s,'score','清气泡记忆，再处理竞速分数',
'''普通合成的基础处理完成后，清除上一购买气泡类型，再尝试竞速计分。计分查的是被拖入物类型，不是合成结果；竞速未开启或未入组则跳过，继续副产物。''',
'''MainBoardModel._DoMergeItem先m_lastBreakBubbleType=nil，再ScoreRace:_OnItemMerged(source)。该模型要求m_config存在、CheckOpen及IsInGroup，再_TryAddMergeScore：按source.GetType查mergeItemScore；取merge_score_race，非nil调用_AddScore，最后返回配置分数供mergeInfo.ScoreRace_Score日志使用。

_AddScore当前分数≥目标立即return，但外层仍可返回配置分数，不能把日志字段当实际增分。未达标时_OnTokenChanged(addScore, 新分数<目标且scene=Merge)，派ScoreRaceScoreChanged、写活动日志；达到目标且无ViewController时创建并State0。后续奖励流程受活动模型控制。

重要：_CanBubbleBuyBonus要求m_lastBreakBubbleType匹配target.Type，但普通链在此已经清空。不能根据helper存在就声称普通合成购买加成一定可达；同步调用是否重新写此字段需要事件闭包证据。末层气泡仍讲清helper本身的规则。''',
    '演示竞速未开启，两个201的合成不计竞速分；清气泡购买记忆后继续临时物检查。',
    '本例CheckOpen=false→分数nil。对照配置201.merge_score_race=5（假设）且当前9/目标10：调用加5；若当前已10，实际不加，但返回字段仍可能为5。',
    ['Board.Model.Board.MainBoardModel','ScoreRace.Model.ScoreRaceModel'],config='score')
    node(s,'temp','优先尝试临时棋子',
'''副产物首先尝试临时物：活动、库存和资源条件通过后，按当前合成链的订单缺口选择帮助物。生成成功会占用本次主副产物名额，跳过卡片和两类气泡；未选出物品才继续。''',
'''棋盘非满且hasCreateItem=false才GenerateType(New.Type)。_CanGenerateTempItem要求Started且主盘没有任何ItemTemp；_CanTrigger要求Energy≤TriggerEnergy（缺省不限制）、排除免费后的能量购买价格≥TriggerGem（缺省不限制），且非无限能量。RoundInterval由interval×60秒；轮间条件严格serverTime−lastEnd>interval。

旧模式：间隔未过返回；没有保存targetType才选择当前链订单缺口中最低等级的合格需求。需求须有Rule且同链；非Advanced时前1级及前2级库存代码不得存在；Advanced时到需求等级的一等价库存总量<floor(2^max(需求等级−3,0))。并要求某个临时候选等级严格高于当前合成等级。保存需求目标；然后按已排序候选找第一个level>mergedLevel，没有则MarkRoundEnd。选到候选列表末项标needUpload。

新模式：先清旧目标并写lastEnd；满足资源后，间隔过或允许同链无间隔且lastChain匹配才继续。计算diff[L]=2^(L−1)−sum(count[i]×2^(i−1),i≤L)，库存仅棋盘+仓库，无缓存；从有订单缺口及Rule且diff>threshold的需求找最高可用等级。优先在mergedLevel+1..maxLevel−1选候选，找不到才在1..min(mergedLevel,maxLevel−1)选；diff严格>阈值，MoreBetter取更大、LessBetter取更小，等值后遍历项覆盖先项。阈值先Duration[temp].trigger_item_min，否则主/副链默认阈值。

选出后保存StartTimer、LastTempItemChainId；needUpload真则检查同步。棋盘在合成新物附近按方形环找到空位，以Temp前缀+type SpreadItem(logSpread=false)，记TempType并hasCreateItem=true。它是订单缺口规则选择，不是一次均匀随机抽取。服务器temp_item_general_config、temp_item_rule_config、temp_item_duration实际记录未取得，不把演示阈值当原值。''',
    '本例临时物活动未开启，跳过，继续卡片。对照活动开启且选出204时，在202旁生成临时204并跳过卡片和气泡。',
    '本例Started=false，GenerateType=nil。新模式演示当前链库存202×1：diff[1]=1、diff[2]=2−2=0、diff[3]=4−2=2；选物还需实际订单、阈值和触发类型，不能仅凭diff自动生成。',
    ['Board.Model.Board.MainBoardModel','TempItem.Model.TempItemModel','TempItem.Board.ItemTemp'])
    node(s,'card','临时物未生成，再尝试卡片',
'''没有临时物且仍有空位时，按拖入物类型、玩家等级和卡片活动条件判断是否生成卡片。命中后生成当前卡片链的一级物，通知卡片系统，并跳过后续气泡。''',
'''TryGenerateItem先CanGenerateCardItem：Started，CheckFinish，再CheckCanMergeMaxCardItem为false。读m_mapCardItemProduceConfig[source itemType]，按ipairs选第一条LevelMin≤玩家等级且LevelMax缺省或等级≤Max的记录；两端包含。

然后遍历m_mapCardItemTypeConfig，任一level≥UnlockLevel就isLevelLock=false；源码这里`if not isLevelLock then return nil`。因此此合成备用入口在已有解锁链时退出，与普通产出进度入口不同，不能按直觉反转条件。使用原字节码受控验证此分支。

math.random(10000)得到1..10000，R≤Chance或测试TestForceCreateCard=1时GenerateCardItem。测试强制只绕过此随机，不能绕过前面的资格/等级返回。当前chain非nil且isFinish=false，返回同链一级；否则TryGenerateNewChain，保存chain与isFinish=false，再返回一级。换链、库存最高级整数倍暂停和stack模式由卡片模型内部处理。

落子用SpreadItem，spreadType=CardItem、logSpread=false；mergeInfo.CardType、hasCreateItem=true，再全局CardItemGenerate消息取实际位置对象。相关5份完整本地卡片配置随本页展示；账号后缀由全局require FileReplace精确匹配选择，实际分组未取得。''',
    '本例卡片活动未开启，不调用卡片随机，继续能量气泡。对照改为备用入口资格通过且随机命中，生成一张卡片，普通气泡不再检查。',
    '演示Chance=250，R=250命中、R=251失败（阈值为假设）。若任一卡片链UnlockLevel≤当前等级，则在随机前return nil；强制测试开关也无法绕过。',
    ['Board.Model.Board.MainBoardModel','CardItem.CardItemModel'],config='card')
    node(s,'energy','没有前两种副产物，再尝试能量气泡',
'''能量气泡根据活动时间、当前能量与购买价格门槛选择一条配置。成功时先更新活动下次可触发时间，再尝试落子；没有选到配置才进入普通气泡。它不按普通物品的BubbleChance抽取。''',
'''此分支只检查not hasCreateItem，没有像临时/卡片那样外层not IsBoardFull。CanSpreadEnergyBubble要求Started且serverTime>TriggerTime，恰好相等不触发。配置energyBubbleConfig先按trigger_energy升序，同值trigger_gem降序。

GetTriggerConfig逐条：当前Energy≤trigger_energy；若连锁能量商店开启，读取当前step的price，跳过连续price=0记录，越末尾break；否则读取EnergyData.costNum。cost≥trigger_gem才选第一条。未选到返回nil。

GetBubbleInfo拼`PropertyBubble前缀 + Energy属性 + '-' + energy + '-' + gem`，Group=groupId；先保存TriggerTime=serverTime+interval×60和GroupId，然后返回Code/Group。棋盘找环形空位并SpreadItem，记录BubbleType/Group、hasCreateItem=true。若此前同步变化使满盘，这里可能位置nil而活动冷却已保存；不可补成“满盘必不推进冷却”。

字段trigger_energy、trigger_gem、energy、gem、interval、groupId均来自服务器活动表，包内实际账号记录缺失；表排序与时间/价格规则可恢复，实际产量和价格不能冒充已知。''',
    '本例能量气泡活动未开启，继续普通气泡。对照能量低且购买价格过门槛，生成一枚指定能量/宝石价格的气泡。',
    '假设serverTime=1000、旧TriggerTime=999、interval=5：通过时间条件，选择后新TriggerTime=1300。恰好serverTime=999不通过；能量10与trigger_energy=10相等可通过。',
    ['Board.Model.Board.MainBoardModel','EnergyBubble.Model.EnergyBubbleModel'])
    node(s,'bubble','普通气泡：资格、加成、衰减与抽取',
'''前三类没有生成，才考虑普通气泡。先确认空间、功能、基础概率与同类气泡限制；满足特定加成时设为必出，否则按订单需要、高等级气泡存量和未购买天数依次衰减。最后一次独立阈值抽样决定是否落子。

普通配置基础概率为零时不进入正常加成/衰减，也不会因“最低1%”变成有机会。测试强制开关放在这些规则之后，可以覆盖普通限制；棋盘满的最早返回仍挡住它。''',
'''## 1. 先资格，再加成

_TrySpreadBubbleByMerge先IsBoardFull直接return；功能Bubble开启才读取new.GetBubbleChance。只有p非nil且p>0才进入正常处理。同类型气泡扫描全盘有效格，ItemBubble.InnerItemCode==New.Type就把p=nil。否则购买加成或订单加成通过则p=100，跳过全部普通衰减。

购买helper要求sourceType非nil、m_lastBreakBubbleType==target.Type且HasBubbleBuyBonus。BreakItem可记录刚打破的innerCode；但普通合成在竞速前已清空此字段，正常可达性须结合全部同步消费者，不能仅凭helper定义断言购买必出。

订单加成type必须为1或2；新物在Slot物品配置中且WeightMultiple=1；GetModelConfig(New.Type)存在且有下一MergedType；下一等级在订单缺口中数量>0。mode2额外要求棋盘+仓库中的New.Type数量<2，缓存不计。它帮助制作订单目标的前一级，不是只要新物本身在订单中就必出。

## 2. 普通衰减按顺序结算

订单衰减r1：BubbleOrderDecrease非nil且0<r1<1才有效。汇总所有Slot订单要求中WeightMultiple=1的代码出现次数；只核对当前新物同链且WeightMultiple=1的代码。棋盘+仓库数量只要有一项小于订单次数，就返回nil不衰减；全部够用或该链没有对应需求，返回r1。不是按库存过剩数量线性扣概率。

链衰减r2：BubbleChainDecreaseLevel=L须>0，BubbleChainDecreaseRatio=q须0<q<1，L<链长度。构造同链L+1至末级的气泡代码，统计棋盘中各代码数，`r2=product(q^count)=q^总数`；只算该链高于固定配置等级的气泡，不是高于本次新物的所有棋子。无符合气泡时返回nil。

玩家衰减r3：BubbleDecrease开关关闭、无档位或noPurchaseLoginDays≤0返回1。服务器档位按no_purchase_days升序，选择满足`day < loginDays`的最大day，ratio=decrease_ratio/100；恰等门槛仍用前档。登录/同步按UTC日桶serverTime//Sec2Day跨日才+1，记录时间；非免费、Cost>0的BubbleBroken把天数重置0。并非从最后购买日起自然流逝每一天都累计。

先 `p = p × r1`（仅返回值>0时），再 `p = p × r2`（同条件），再 `p = p × r3`（直接乘），最后 `p = max(p, 1)`。基础p=0不进这段；倍率无效也不会被擅自应用。

## 3. 测试覆盖、随机与落子

在上述处理之后，测试模式且TestBubbleMustSpread=1直接p=100：可以覆盖功能关闭、基础0、同类重复拒绝；不能覆盖最早满盘return。p非nil便调用MathUtil.Random(100)，即floor(u×100)+1，u为math.random()或测试注入浮点，R∈1..100。条件R≤p；小数阈值如1.9实际只允许R=1，因此有效概率floor(p)/100（p≥100必过）。独立判定，不保存不放回池；p=100仍调用随机，p=nil不调用。

命中bubbleType=New.Type。非数字code用Bubble前缀；数字code用tostring(tonumber(type)+ItemCodeOffset.Bubble)。按方形环找首个空格，SpreadItem(logSpread=false)，派BubbleSpread消息itemModel为合成新物，不是新气泡对象。返回值也是内含New.Type，mergeInfo.BubbleType因此可能是内含code，不能无条件当实体气泡code。

普通气泡出现后BubbleSale活动开启才GetBubblePrice(returnedType)，日志补折扣/原价。这是抽后价格表现，不是另一轮生成。测试模式记录概率推导信息，不额外改变正常概率。

## 4. 生效配置与不可假定值

基础BubbleChance来自新物配置，各本地ItemModelConfig变体完整记录在本页。BubbleOrderBonus/Decrease、BubbleChainDecreaseLevel/Ratio、BubbleDecreaseConfig来自账号远端配置，缺实际记录；按前述算法解释，不用演示值替代。已有同类检测、订单资格、倍率与测试覆盖必须按这里的顺序实现。''',
    '主例202.BubbleChance=0，正常路径不会生成气泡。为了看清概率，对照把源与目标都改为203，合成204；204基础3%，其它加成关闭、衰减倍率为1时，抽到3会生成204气泡，抽到4不会。',
    '默认201→202，p=0，没有正常加成/衰减，仍执行MathUtil.Random(100)因为p=0非nil，比较0≥R恒false。对照203→204：p0=3，r1/r2未命中、r3=1，p=3；R=3命中。衰减演示r1=0.5、r2=0.8²、r3=0.5：3×0.5×0.64×0.5=0.48→下限1，R=1才过。假设档day=3：loginDays=3不启用该档，4才启用。',
    ['Board.Model.Board.MainBoardModel','BubbleDecrease.Model.BubbleDecreaseModel','Common.Utility.MathUtil'],config='bubble',icons=('202','204'))
    node(s,'coin','主副产物之后，独立检查金币',
'''不论主副产物是哪一类，最后再检查是否还有空位以及新物链等级是否达到金币门槛。通过就多生成一枚一级金币。主副产物占满最后空格时，金币不会生成。''',
'''`not IsBoardFull()`后读取SystemConfigKey.SpreadCoinMinChainLevel；条件`threshold ≤ New.Type链等级`，含等号。按FindEmptyPositionInSpreadOrder(New.Position)取首空位，SpreadItem(Coin01,logSpread=false)。没有随机接口，不按概率给金币，也不以hasCreateItem为互斥条件。

SystemConfigModel.LoadFileConfig读取GetLocalConfig(LocalConfigKey.System)，逐条用name作键、tonumber(value)保存，GetConfig直接查该键；默认SystemConfig本地值8。不能凭空添加远端覆盖优先级，实际本地装载变体应按ConfigModel选择核对。普通合成等级2时不达；等级8且有位时会给1枚Coin01。特殊升级/剪刀不会调用此普通后处理，因此不可默认它们也按等级发金币。''',
    '202是当前链第2级，低于默认门槛8，因此主例没有金币。对照合成到第8级且还有空格时，多出1枚一级金币。',
    '默认threshold=8，newLevel=2→false。newLevel=8→true；若上一副产物用完唯一空位，IsBoardFull=true，则连阈值读取也跳过。',
    ['Board.Model.Board.MainBoardModel','Model.SystemConfigModel'],config='system')
    node(s,'landing','副产物共同落点、写格与通知',
'''每种选出的副产物都在其分支内立即落子，之后才判断下一分支。落点是附近按固定顺序找到的第一个空位，位置不随机；创建、订单刷新与同步监听会影响下一次空位检查。''',
'''FindEmptyPositionInSpreadOrder从New.Position开始，maxTiles=max(7,9)=9；r=1..8。每轮当前位置先(−1,−1)，然后按dir右/上/左/下，每边走2r步，每步之后检查合法且GetItem=nil就return。无位return openedPosition（本链未传即nil）。中心不扫描，角落越界跳过但步进继续。

例如中心(4,3)，r1依次(4,2),(5,2),(5,3),(5,4),(4,4),(3,4),(3,3),(3,2)。若唯一空位为源S=(3,3)，落在r1第7项；不是总优先源格。

SpreadItem内GenerateItem→SaveItemProperty→_SetItem（默认刷新订单）→局部SpreadItem→主盘全局ItemSpread→日志/满盘检查。本操作传logSpread=false禁产出日志，但不禁上述通知。消息CostEnergy缺省值与BoardSpreadType由SpreadItem实现填充，活动应读取实际消息，不把合成来源冒充母体消耗能量。

EnergyBubble分支缺外层满盘检查是前述例外；GenerateItem(nil,code)仍保存对象但不写格，不能当落子已成功。顺序写入不是统一事务。''',
    '主例不选副产物，因此没有第二次落子。对照203→204气泡命中，若唯一空格为S，气泡按固定扫描在S落下。',
    '演示中心T=(4,3)，其余格满、S=(3,3)空；扫描第7项命中S；副产物创建保存后写S。已满时扫描无结果为nil。',
    ['Board.Model.Board.BaseItemLayerModel','Board.Model.Base.BoardPosition','Board.Model.Board.BaseBoardModel','Board.Model.Board.MainBoardModel'])
    node(s,'finish','同步检查、合成日志与返回',
'''所有副产物处理后，检查新物是否需要额外上传，汇总本次合成日志，返回拖拽入口。已经合成成功的拖动不会再进入吞噬或交换；界面释放收尾仍会继续。''',
'''GM.SyncModel:CheckMoreUpload(New.Type)位于金币之后；_DoMergeItem返回mergeInfo，_MergeItem调用_LogMerge。日志ext含TempType、BubbleType、BubbleSalePrice、BubblePrice、Balloon、ScoreRace_Score、CardType；目标有Cobweb时cobWeb=1；Group非nil写ebGroup；最近触碰配对命中写isTouched=true。

logType默认Source.Type；Target有ItemTemp时改为Target.Type，不与普通结果类型混淆。LogMerge(logType,New.Code,ext,BoardType)之后DragItem立即return；视图函数继续选中状态、BoardPointerUp等收尾。

CheckMoreUpload是触发检查而非无条件已上传；上传开关、队列与远端结果分别决定。客户端规则恢复不等于已确认服务端存档一致。''',
    '主例日志记录201合成202，没有临时/气泡/卡片字段；同步模型检查202，随后视图选中202。',
    'Source.Type=201、Target无Temp/Cobweb、New.Code=202；ext副产物字段nil。执行次序Coin检查→CheckMoreUpload(202)→LogMerge(201,202)→DragItem return。',
    ['Board.Model.Board.MainBoardModel'])

    s=stage('swallow','不能合成：再尝试目标吞噬',
'''只有普通合成失败才读取目标吞噬组件。目标需要这种物品且数量未满时，接收一件，保存进度并删除拖入物；所有需求都完成时变换成奖励物。吞噬成功立即结束，不再交换。

吞噬所需物品通常在目标创建时已经确定，拖入时只比对代码和剩余数量，不在每次拖动时重新随机需求。''',
    '主例已经合成并返回，吞噬不执行。吞噬对照改为一个要求201的目标，201被消耗、目标进度加1；这是另一条互斥路径。')
    node(s,'target','创建需求、固定池与拖入资格',
'''目标创建时为最多两项需求选代码和数量。玩家拖入时按完整物品代码检查需求是否尚缺；目标是否允许点击影响移动资格，但不是拖入吞噬的额外门槛。''',
'''ItemSwallow.Init调用_CreateSwallowInfo(config,1/2)。Swallow_WeightN=nil返回nil；有教程forcedTypes时用其第N项，否则FixedSwallow.GenerateTargetCode(Type,weights,N)。Count=Swallow_NumberN，Swallowed=0；Swallow_AllowTap~=0；generateTime=serverTime。

固定池按目标Type与需求槽N共享存档。配置串与pairsN不同或sequenceN空时重建序列：展开1..sumWeight，倒序i=sum..1，用MathUtil.Random(i)做Fisher–Yates交换；序列保存逗号串。创建需求时消费序列首个索引，按原Weight累计映射Code，保存余串；最后一个消费后sequence=nil，下次重装。不是每次独立有放回随机，也不是每个目标实例自己的需求池。

CanSwallow遍历m_swallowInfo，必须info.Code==drag.GetCode且Swallowed<Count。比较完整code，不用GetType或InnerItemCode替代；组件AllowTap=false并不阻止拖入。TapProtectionTime=1秒限制OnTap批量吞噬，不限制此DragItem入口。ipairs遇nil缺口停止，不能擅自容忍槽1缺失但仅槽2存在。''',
    '主例合成优先，未检查需求。吞噬对照目标保存Code=201、Count=2、Swallowed=0，拖201可吞。',
    '对照CanSwallow：201==201且0<2→true；包装代码即使内含201，GetCode不同则false。假设权重201×2/202×1，序列3,1,2：本次需求选202，保存1,2；下一同类型同槽需求选201。',
    ['Board.Model.Item.ItemSwallow','Board.Model.Board.ItemFixedSwallowModel'],config='swallow',icons=('201',))
    node(s,'progress','吞入、保存与进度通知',
'''匹配后先更新目标进度并保存，再删除拖入物、通知吞噬与刷新进度。最后检查全部需求是否完成；未完成则保留目标等待下一件。''',
'''Swallow遍历info，遇Code相等即Swallowed+=1并break，内部未再次检查<Count；依赖外层CanSwallow。存在重复需求代码时，它可能给第一条已满项继续加数，不能按设计直觉改成优先未满项。

SaveItemProperty(target)→RemoveItem(source)→局部SwallowItem(Source,Target)→BI SwallowItem→遍历所有info，任一Swallowed<Count则canTransform=false→局部ProgressChanged。其后完成才Transform；全局ItemSwallow在变换之后派发。

持久化将每项Code-Swallowed-Count以';'连接；恢复逐项'-'分割、tonumber两计数。需求选定后恢复保存记录，不能重抽需求或清空进度。原版重载仍需实际存档差分验证。''',
    '吞噬对照第一件201使0/2变1/2，源201删除，目标暂不变换。',
    'Code=201、Count=2、Swallowed=0→1；canTransform=false；ProgressChanged后直接派ItemSwallow。重复Code边界须保留外层与内部选择差别。',
    ['Board.Model.Item.ItemSwallow','Board.Model.Board.BaseActionBoardModel'],config='swallow')
    node(s,'transform','需求完成后的奖励变换',
'''全部需求完成后，目标按变换权重选一个结果并原格替换。吞噬引起的变换不再额外消耗点击能量；不允许点击的吞噬物还会震动邻格，随后发全局吞噬完成通知。''',
'''所有info.Swallowed≥Count才完成。ItemTransform.Transform()用Table.ListWeightSelectOne(Transform_Weight).Code选择结果，不扣候选权重；独立有放回加权选择，整数累计区间来自MathUtil.Random(sum)。ReplaceItem(target,result)删除吞噬物并创建保存新物，默认刷新订单。

Transform消息Source/New/CostEnergy=false（因为参数未传true），先局部TransformItem，再全局ItemTransform，日志e=0。该函数不调用OnTap的扣1能量路径。随后如果not Swallow.AllowTap，震动原目标位置四邻格；最后全局ItemSwallow仍携带原Source/Target引用，Target可能已被替换。

没有通过普通_DoMergeItem，所以不自动检查普通合成气泡/金币。Transform_Weight、Swallow_WeightN/NumberN来自目标实际配置；本地默认主表没有吞噬记录时必须查变体/活动表，不等于吞噬算法不存在。''',
    '吞噬对照第二件201把1/2变2/2，假设变换配置只含202，目标变202，能量不变。',
    '演示Transform_Weight={202:1}，Random(1)=1→202；CostEnergy=false；若AllowTap=false才ShockNeighborItems；最终ItemSwallow消息Target仍是原吞噬物。',
    ['Board.Model.Item.ItemSwallow','Board.Model.Item.ItemTransform'],config='swallow',icons=('201','202'))

    s=stage('swap','未被接收：拒绝或交换位置',
'''特殊作用、合成与吞噬都没接管，才检查目标可移动性。目标不能移动则拖入物复位；能移动则两件棋子交换位置，保留对象、类型和各自内部状态。最后处理移动加速，返回界面收尾。''',
    '主例合成成功，交换不执行。交换对照把目标改为不同类型的可移动普通物，两件物品互换；能量和物品总量不变。')
    node(s,'blocked','不可移动目标：复位结束',
'''到最后兜底仍不能合成或吞噬，目标被纸箱、蜘蛛网、锁定或吞噬点击限制固定时，不允许交换。拖入物回原格，不消耗双方。''',
'''目标CanItemMove使用与源同一规则：PaperBox/Cobweb/Locked拒绝；Swallow存在则AllowTap。失败SetPosition(source原位置)并return，不改格、不发ItemMoveEnd、不调用_UpdateAccelerate。该检查在CanItemMerge/CanSwallow之后，所以不能移动的目标仍可能在前面作为合成或吞噬目标成功。''',
    '主例在合成已返回。对照201拖到内含不同类型的蜘蛛网，既不匹配合成又不可交换，所以201复位。',
    'CanItemMerge=false、CanSwallow=false、target.Cobweb存在→CanItemMove=false；仅source.SetPosition(S)。',
    ['Board.Model.Board.MainBoardModel','Board.Model.Board.BaseBoardModel'])
    node(s,'exchange','交换写格、订单刷新与计时',
'''目标可移动时，先交换格层，再分别更新位置和移动日志，刷新加速。棋子对象与组件不重建，因此不会重置母体次数或计时。''',
'''记itemPosition=S。顺序_SetItem(S,nil,false)→_SetItem(T,source,false)→_SetItem(S,target)；第三次未传false，会CountItemsCode/UpdateOrderState。旧说明“两次对象写回都禁订单刷新”错误，当前实现只前两次禁用。

随后_LogMove(source,source.GetPosition(),T)，_LogMove(target,T,S)，再source.SetPosition(T)、target.SetPosition(S)，最后_UpdateAccelerate(source,target)。因此订单刷新通知发生在两对象SetPosition之前，但格层已经交换；同步消费者读取格层与对象位置时须按该时点理解。

交换没有空位移动分支的ItemMoveEnd，也没有普通合成/吞噬事件。存在计时或激活加速组件时UpdatePerSecond调用两次；不是两件新物，不SaveItemProperty重建状态。''',
    '本例不交换。不同类型对照：source201与target202不可普通合成，均可移动时互换。',
    'S=(3,3)、T=(4,3)：第三次SetItem(S,target,nil)触发一次订单刷新，此时source.Position仍S、target.Position仍T；随后改为T/S，再加速更新。',
    ['Board.Model.Board.MainBoardModel','Board.Model.Board.MainBoardItemLayerModel'],icons=('201','202'))

    s=stage('pointer','返回视图：更新选中与释放反馈',
'''模型处理结束后，松手函数仍会完成界面收尾：选中当前结果、刷新信息栏和可交付格，通知释放，清拖动缓存并重启提示。模型提前返回只是结束动作分派，不等于这一整次玩家输入已经不再触发任何界面逻辑。''',
    '主例源201已删除，视图选择目标格的新202，显示其信息，清理拖动灯光和状态。')
    node(s,'selection','选择结果、提示与释放通知',
'''空位移动通常继续选原对象；合成后原对象消失则选目标格结果。最后根据物品是否消失或位置是否变化决定收集提示，发送释放事件并清理拖拽状态。''',
'''非仓库棋盘分派后：GetItem(source.GetPosition())==source时m_selectedBoardPosition=source.GetPosition，否则用targetBoardPosition。仓库存入成功不走这段选择分支；局部StoreItem视图回调移除源视图并刷新栏。

selectedItemDisappeared=(selectedItem~=source and GetItem(source.Position)~=source)。为true用MergeItem收集提示；否则not boardPositionChanged用SelectItem；否则None。_UpdateIndicator、infoBar.UpdateInfoBar→全局BoardPointerUp{dragging=m_dragging}→_ClearPointerData→_UpdateItemAffectedEffect。startedPromptStep2为true则清标记，否则_StartPrompt；最后_UpdateCompleteTiles(true)。

普通合成的局部MergeItem视图回调还会先更新指示器/信息栏，调用BaseActionBoardView._OnMergeItem处理动画，再_TryToRemoveSandFills(Target)。它与最后PointerUp收尾是不同触发位置。动画不负责替代模型创建、保存与订单更新。''',
    '视图看到源201已不在S，选T上的202；信息栏改为202，释放事件标记本次确实拖动。',
    'source仍引用旧201但GetItem(S)≠source，selectedPosition=T。BoardPointerUp.dragging=true在_ClearPointerData之前发出；不是清理后false。',
    ['Board.View.MainBoardView','Board.View.BaseActionBoardView'])


def link(page,target):
    return os.path.relpath(target,page.parent).replace('\\','/')


def html_link(page,target):
    # Raw HTML links are not rewritten by MkDocs' directory-URL processor.
    return ('../' if page.stem!='index' else '')+link(page,target)


def configs(node,page):
    kind=node['config']
    if not kind:return ''
    names=[];fields=[]
    if kind in ('merge','special','bubble','swallow'):
        names=[n for n in BY_NAME if n.startswith('Data.Config.ItemModelConfig') or n.startswith('Data.Config.GeneratorBoostItemModelConfig')]
        if kind=='swallow':
            names=[n for n in BY_NAME if n.startswith('Data.Config.') and 'ItemModelConfig' in n]
        fields={'merge':['Type','MergedType','BubbleChance','StateCollectionType','StateCollectionIndex'],
                'special':['Type','SpecialType','LevelUpPiece','LevelDownPiece','MergedType'],
                'bubble':['Type','BubbleChance','MergedType'],
                'swallow':['Type','Swallow_Weight1','Swallow_Number1','Swallow_Weight2','Swallow_Number2','Swallow_AllowTap','Transform_Weight']}[kind]
    elif kind=='score':
        names=[n for n in BY_NAME if n.startswith('Data.Config.MergeItemScoreConfig')];fields=['item_id','merge_score_race','bubble_score','shop_score']
    elif kind=='card':
        names=[n for n in BY_NAME if n.startswith('Data.Config.CardItem')];fields=[]
    elif kind=='system':
        names=['Data.Config.SystemConfig'];fields=['name','value']
    from lupa.lua53 import LuaRuntime,lua_type
    runtime=LuaRuntime(encoding=None)
    symbols={}
    for row in json.loads((ROOT/'analysis_data/json/ItemViewConfig.json').read_text(encoding='utf-8')):
        for image in row.get('Image',[]): symbols.setdefault(image.encode(),row['Type'].encode())
    runtime.globals()[b'ItemType']=runtime.table_from(symbols)
    def conv(v):
        if isinstance(v,bytes):return v.decode('utf-8',errors='replace')
        if lua_type(v)=='table':
            keys=list(v.keys())
            if keys and set(keys)==set(range(1,len(keys)+1)):return [conv(v[i]) for i in range(1,len(keys)+1)]
            return {str(conv(k)):conv(v[k]) for k in keys}
        return v
    meanings={
      'merge':[('Type','棋子逻辑类型，不保证是连续数字'),('MergedType','普通合成的新物类型；缺省意味着不能提供下一等级'),('BubbleChance','结果物的基础百分比阈值，读取的是新物而非输入物'),('StateCollectionType / Index','状态集合的源类型与状态索引，创建组件时参与选配置')],
      'special':[('SpecialType','源特殊类型；1升级、2剪刀；其它类型不自动走这两条作用'),('LevelUpPiece / LevelDownPiece','目标允许被作用的标记，必须恰为1'),('MergedType','升级结果；拆分则从链的前一级取结果')],
      'bubble':[('Type','合成结果的类型，用于查同类气泡与链'),('BubbleChance','基础阈值，百分比；0不进入正常加成衰减'),('MergedType','订单必出资格需要该结果还有下一等级')],
      'swallow':[('Swallow_Weight1/2','创建目标时两项需求的代码与份额，不是每次吞入的概率'),('Swallow_Number1/2','对应需求总件数；逐个吞入+1'),('Swallow_AllowTap','恰为0禁点击/移动，其余包含缺省允许；拖入资格单独检查'),('Transform_Weight','完成后的独立加权奖励候选，不扣份额')],
      'score':[('item_id','以Source.Type索引的输入棋子'),('merge_score','Avenue/Road/Exped/Upward/FloatRace/Combo等读取的分数'),('merge_score_race','竞速、Battle、Team读取的分数；缺省跳过'),('bubble_score / shop_score','本表的其它字段；不是本次合成加分，不能合计进merge分数')],
      'card':[('ItemChain / UnlockLevel / Weight / Rarity','卡片链、选链等级门槛、选链权重、表现稀有度'),('ItemType / LevelMin / LevelMax / Chance','被合成输入类型、玩家等级含端点区间、万分整数阈值；Max缺省无上限')],
      'system':[('name / value','以name索引的本地数值；SpreadCoinMinChainLevel默认8，比较新物链等级')],
    }
    output=['\n## 对应本地配表\n',
      '| 字段 | 在本步骤中的含义 |\n| --- | --- |\n'+'\n'.join('| '+a+' | '+b+' |' for a,b in meanings[kind])+'\n',
      '同一文件后缀是可选变体，不代表本次账号全部同时生效。全局require按FileReplace的首个精确file匹配追加后缀，替换装载失败才回退默认；账号实际后缀尚未取得。下表列出此步骤所用字段，下载保留完整原记录。字段缺省以“—”表示，不能当作数值0。\n']
    if kind=='swallow':output.append('以下包含其它活动棋盘的吞噬配置，表名表明其适用玩法；用于解释共同组件和包内记录，不表示主棋盘本次拖动会加载这些活动表。默认主棋盘表未发现吞噬需求记录，主例的吞噬对照为明确假设。\n')
    receipt=[]
    assets=DOCS/'assets/merge-evidence';assets.mkdir(parents=True,exist_ok=True)
    for name in sorted(names):
        m=BY_NAME[name]
        try:
            value=runtime.execute((ROOT/m['standard_path']).read_bytes())
            rows=conv(value)
            if not isinstance(rows,list):continue
        except Exception as e:
            receipt.append({'module':name,'status':'unparsed','error':str(e)});continue
        original=rows
        if kind=='swallow':rows=[r for r in rows if r.get('Swallow_Weight1') is not None or r.get('Swallow_Weight2') is not None]
        if kind=='special':rows=[r for r in rows if any(r.get(f) is not None for f in ['SpecialType','LevelUpPiece','LevelDownPiece'])]
        if kind=='system':rows=[r for r in rows if r.get('name')=='SpreadCoinMinChainLevel']
        if kind=='card':fs=sorted(set().union(*(r.keys() for r in rows))) if rows else []
        else:fs=fields
        leaf=name.split('.')[-1]
        dest=assets/(leaf+'.json');dest.write_text(json.dumps(original,ensure_ascii=False,indent=2),encoding='utf-8')
        receipt.append({'module':name,'records':len(original),'displayed_records':len(rows),'fields':fs,
                        'bytecode_sha256':m['sha256'],'consumer_explanation_status':'pending-full-field-review'})
        if not rows:continue
        output.extend([f'<details><summary>{html.escape(leaf)}：{len(rows)}条相关记录（原表{len(original)}条）</summary>',
            '<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr>'+''.join('<th>'+html.escape(f)+'</th>' for f in fs)+'</tr></thead><tbody>'])
        for row in rows:
            output.append('<tr>'+''.join('<td>'+html.escape(json.dumps(row[f],ensure_ascii=False) if isinstance(row.get(f),(list,dict)) else str(row.get(f,'—')))+'</td>' for f in fs)+'</tr>')
        output.extend(['</tbody></table></div></div>',f'<p><a href="{html_link(page,dest)}">完整原记录</a></p>','</details>',''])
    path=AUDIT/('config_'+kind+'.json');path.write_text(json.dumps(receipt,ensure_ascii=False,indent=2),encoding='utf-8')
    if not any(r.get('displayed_records',0)>0 for r in receipt):
        output.append('当前包内这些配表中未取得此机制的实际记录；算法由组件源码确认。远端或其它版本记录不能由演示数据替代。')
    return '\n'.join(output)


def evidence(node,page):
    assets=DOCS/'assets/merge-evidence'; assets.mkdir(parents=True,exist_ok=True)
    lines=['\n## 源码依据\n']
    for name in node['modules']:
        if name not in BY_NAME:
            raise ValueError('Missing source '+name)
        p=source(name);dest=assets/(name+'.lua');shutil.copy2(p,dest)
        dis=assets/(name+'.disassembly.txt');shutil.copy2(ROOT/BY_NAME[name]['disassembly_path'],dis)
        lines.append(f'- {name}：[恢复源码]({link(page,dest)}) · [原指令与源码行]({link(page,dis)})')
    return '\n'.join(lines)+'\n'


def case(page,text,detail='',icons=()):
    images=''
    for code in icons:
        target=DOCS/'assets/cases'/('item-'+code+'.png')
        if target.exists(): images+=f'<img src="{html_link(page,target)}" alt="棋子{code}" style="width:72px;height:72px;object-fit:contain;margin-right:12px;">'
    return '\n---\n\n## 贯穿案例：两个201合成202\n\n'+images+'\n\n'+text+'\n'+ ('\n### 代入本页的值\n\n'+detail+'\n' if detail else '')+'''
<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
'''


def prepare_assets():
    from stage3_cases import BUNDLE
    import UnityPy
    codes={'203','level_up_piece_1','level_down_piece_1','2401'}
    rows=json.loads((ROOT/'analysis_data/json/ItemViewConfig.json').read_text(encoding='utf-8'))
    desired={r['Type']:r['Image'][0] for r in rows if r['Type'] in codes}
    env=UnityPy.load(str(BUNDLE));assets=DOCS/'assets/cases';assets.mkdir(exist_ok=True)
    receipt=[]
    for code,name in desired.items():
        choices=[(k,v) for k,v in env.container.items() if k.endswith('/'+name+'.png') and v.type.name=='Sprite']
        if len(choices)!=1:
            receipt.append({'code':code,'image':name,'status':'unresolved','matches':len(choices)});continue
        address,obj=choices[0];dest=assets/('item-'+code+'.png')
        obj.read().image.convert('RGBA').save(dest)
        receipt.append({'code':code,'image':name,'address':address,'path_id':obj.path_id,
                        'bundle_sha256':sha(BUNDLE),'image_sha256':sha(dest),'status':'extracted-original'})
    (AUDIT/'asset_manifest.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2),encoding='utf-8')


def build():
    records,listeners=inventory()
    define()
    prepare_assets()
    # Landing is an inline operation inside each branch, never a separate
    # after-coin stage. Repeat its full algorithm where readers need it.
    normal=next(s for s in STEPS if s['key']=='normal')
    landing=next(n for n in normal['children'] if n['key']=='landing')
    for n in normal['children']:
        if n['key'] in ('temp','card','energy','bubble','coin'):
            n['detail']+='\n\n## 本分支的落点与写入顺序\n\n'+landing['detail']
            n['modules']=list(dict.fromkeys(n['modules']+landing['modules']))
        if n['key']=='card':
            n['detail']=n['detail'].replace('因此此合成备用入口在已有解锁链时退出，与普通产出进度入口不同，不能按直觉反转条件。使用原字节码受控验证此分支。','但这个条件是否执行取决于下方解释的映射结构，不能只看变量名推断真实账号会被等级门槛拒绝。原字节码受控验证数组与字符串映射两条路径。')
            n['calculation']='演示Chance=250，R=250命中、R=251失败（阈值为假设）。真实本地字符串ItemChain映射不会被ipairs遍历；对照改成连续数字键数组且UnlockLevel≤等级，才在随机前return nil，强制测试也无法绕过。'
            n['detail']+='''\n\n## 等级循环与真实配置结构的区别

LoadCardItemConfig把记录按ItemChain作为键建m_mapCardItemTypeConfig；本地ItemChain是字符串，如main_card_item_energy_b。上述备用入口却用ipairs遍历这张映射；对只有字符串键的正常映射，循环不访问任何记录，isLevelLock保留true，不会因已解锁链而提前返回。只有存在从1开始连续数字键的不同结构才执行那个等级拒绝分支。原始字节码与恢复源码的两种结构均做受控验证；复刻当前行为不能擅自把ipairs改成pairs。

CheckCanMergeMaxCardItem统计棋盘、缓存和仓库里当前卡片链的裸普通代码，按2^(等级−1)转一级等价；总量非零且能被最高级所需2^(maxLevel−1)整除才暂停，不是总量≥需求。stack开关为1时CheckFinish先把旧链标finished并保存，随后暂停检查可能返回false，允许新链生成。

TryGenerateNewChain遍历已解锁链，先排除旧链；没有其它可选链才退回旧链，按Weight选择。未取得可选链时加权工具的异常边界须保留，不自造奖励。ItemMerged监听在新物为最高级卡片、活动Started且该链未记录已展示时保存提示标志并派CardItemFirstPopWindow；这属于基础合成通知时的同步响应，不是本次备用卡片随机的再次判定。
'''
    normal['children'].remove(landing)
    # Explain listeners at the exact synchronous dispatch position, not under
    # a separate "events" nav bucket.
    notify=next(n for n in normal['children'] if n['key']=='notify')
    notify['overview']+=' 合成通知还会让已开启的活动读取源物分数、更新任务，或检查新物解锁；这些响应发生在主棋盘后续副产物判断之前。'
    notify['detail']+='''

## ItemMerged通知内的同步响应

这些响应由订阅与资格决定，不是每次合成都全部生效，也没有源码保证以下活动之间的固定注册顺序。普通合成、升级和两剪刀都发送ItemMerged，故监听需按Source/New及自身条件区分，不能把它们都当普通合成副产物。

| 消费者 | 读取什么、何时处理 | 已确认的本地规则 |
| --- | --- | --- |
| Avenue、Road、Exped、Upward、FloatRace | Source属于主棋盘，CanAddScore通过，按Source.Type读MergeItemScoreConfig | 取merge_score，非nil才交给各活动加分 |
| Battle、Team | 主棋盘Source且活动允许加分 | 取merge_score_race；Team在监听直接读表，Battle在helper内读 |
| Combo | 主棋盘，活动Started；任务Doing或自己未达目标且无网络 | 按Source.Type取merge_score，加连击代币 |
| Pass | 不在入口额外过滤棋盘，处理New.Code与固定目标merge各1次 | 活动Started；非Super票且已到最后配置等级时不再加任务；遍历活动任务，Target一致才增加 |
| CardItem | 活动Started且New.Type为最高级卡片 | 未标记已展示则保存链提示标志，派CardItemFirstPopWindow，不再抽一张卡 |
| Farmboard | 活动Started，New.Type在Item等级表 | 找匹配等级，严格高于当前等级才保存、尝试解雾并通知；入口未额外检查Source主棋盘 |
| GeneratorFactory | 服务器开关开启，尚未全部解锁，New.Type在工厂母体集合 | 重新计算开启状态；从关闭转开启会CheckCobweb，再发状态通知与刷新仓库红点 |
| TaskEventProgressGainModule | 读取New并逐个调用已注册且conditionFunction通过的任务模型 | 发ItemMerge+1和Item+1；New链等级恰为3..10时额外发对应ItemMergeN+1及Source.BoardType，超范围无这条额外类型 |
| TutorialOrderModel | 当前教程订单Doing、UnlockItem=Fishing05、新物RawFish05、海鲜第二教程未完成 | 标记待开始并派TutorialStartPop |
| SDKHelper | 日期按服务器时间转YMD，按本地计数处理 | 新日期清零；每5次合成发一次支付宝行为，日上传次数上限40，即最多200次合成对应40次行为；不足5次的运行内余数与持久化上传计数不同 |
| GooglePgsManager | 合成通知入口调用RecordGameStatsMerge | 平台统计不改棋盘结果；平台可用性由平台服务控制 |

TaskEventProgressGainModule默认operation=Add；BubbleSpread监听则为Bubble、operation=Update、num=1。动态注册任务模型的具体任务条件、目标量和奖励仍由各自活动配置决定，不能把注册器当成统一奖励算法。事件响应需要继续追到各活动存档/奖励边界，表格描述的是已核实的入口与直接规则，不把尚未取得的远端档位当已知值。
'''
    notify['modules']+=['Avenue.Model.AvenueModel','Road.Model.RoadModel','ExpedActivity.Model.ExpedModel','Upward.Model.UpwardModel','FloatRace.Model.FloatRaceModel','BattleActivity.Model.BattleActivityModel','TeamActivity.Model.TeamActivityModel','ComboActivity.Model.ComboActivityModel','PassActivity.Model.PassActivityModel','CardItem.CardItemModel','FarmboardActivity.Model.FarmboardActivityModel','Board.Model.Board.ItemGeneratorFactoryModel','Model.Activity.ActivityModule.TaskEventProgressGainModule','Board.Model.Order.TutorialOrderModel','Common.Platform.SDKHelper','Model.GooglePgsManager']
    notify['config']='score'
    transform=next(n for s in STEPS if s['key']=='swallow' for n in s['children'] if n['key']=='transform')
    transform['detail']+='''

## ItemTransform通知的能量活动条件

Adventure、Room、TriggerBoost及ItemClickAcquire的变换监听均要求Source主棋盘且CostEnergy=true；HitBricks还要求ruleType=0。吞噬调用Transform()得到CostEnergy=false，因此这次吞噬变换不会通过这些消耗能量资格，不应在案例虚构相应活动代币。其它活动棋盘的视图/教程监听仍按自身条件处理；这里的过滤不能泛化到所有ItemTransform订阅。
'''
    # Short qualitative sequence on each third-level page; numeric derivation
    # stays in its fourth-level detail page.
    flows={
      'movable':'先检查障碍与锁定 → 再检查吞噬物移动许可 → 首次拖动通知 → 图像跟随手指。',
      'position':'转换松手坐标 → 按近期高亮判断吸附 → 应用教程指定落点 → 交给后续分派。',
      'inventory':'是否落在仓库 → 功能开启 → 物品可存 → 容量足够 → 存入；任一步失败回到棋盘落点。',
      'identity':'目标坐标合法 → 源格仍是原对象 → 读取目标棋子；失败直接复位。',
      'write':'目标为空或原格 → 清源格并写目标格 → 按是否真实移动记录日志 → 更新位置。',
      'accelerate':'是否涉及计时或激活加速组件 → 有则立即刷新计时 → 发移动结束 → 返回。',
      'eligibility':'按实际来源状态与配置依次排除 → 取得本步骤比较对象 → 判断资格；不通过进入后续互斥路径。',
      'upgrade':'目标允许升级 → 打开确认窗并复位道具 → 确认后复核 → 消耗道具并替换目标 → 通知与邻格震动。',
      'scissors':'确认双方都是剪刀 → 读取剩余次数 → 消耗两旧对象 → 创建新剪刀并保存合计次数 → 合成通知。',
      'split':'确定同链前一级 → 确认与复核资格 → 扣一次剪刀 → 原格生成第一件 → 找空位生成第二件 → 拆分反馈。',
      'failure':'判断失败原因 → 显示提示 → 继续普通合成；提示不等于当前拖动结束。',
      'replacement':'确定新物类型 → 删除拖入物与目标 → 创建并保存结果 → 写目标格并刷新订单。',
      'notify':'新物已写入 → 局部合成通知 → 全局同步响应 → 四邻格组件处理 → 震动通知 → 返回普通追加结算。',
      'score':'清除购买气泡记忆 → 判断竞速资格 → 查源物分数 → 更新竞速状态 → 保留日志字段。',
      'temp':'检查空间、活动和资源 → 按旧/新规则选择订单帮助物 → 保存轮次状态 → 成功落子并排除后续主副产物。',
      'card':'仍无主副产物且有空位 → 卡片资格与源物等级配置 → 按配置结构处理等级循环 → 概率判定 → 确定卡片链并落子。',
      'energy':'仍无主副产物 → 活动时间可触发 → 能量/购买价格选档 → 保存冷却与分组 → 落子；未选档继续普通气泡。',
      'bubble':'确认空间与基础资格 → 去除同类重复 → 检查必出加成 → 否则依次衰减 → 测试覆盖 → 阈值随机 → 落子与价格。',
      'coin':'副产物处理完毕 → 是否还有空位 → 新物等级是否到门槛 → 生成一枚一级金币。',
      'finish':'金币检查完毕 → 新物同步检查 → 汇总合成日志 → 返回拖拽分派与视图。',
      'target':'目标创建时选定需求并保存 → 拖入时比对完整代码与剩余数量 → 匹配才接收。',
      'progress':'增加匹配项 → 保存目标进度 → 删除输入并通知 → 核对所有需求 → 未完成等待下一件。',
      'transform':'需求全部完成 → 权重选择奖励 → 原格替换并通知变换 → 按允许点击状态决定震动 → 发吞噬通知。',
      'blocked':'前三条路径均未接管 → 目标不能移动 → 源物复位并结束。',
      'exchange':'目标可移动 → 三次写格完成交换与订单刷新 → 两条日志 → 更新双方位置 → 刷新加速。',
      'selection':'根据模型结果选中物品 → 刷新提示与信息栏 → 通知释放 → 清输入状态 → 恢复指示与完成格。',
    }
    for s in STEPS:
        for n in s['children']:
            flow=flows[n['key']]
            if n['key']=='eligibility' and s['key']=='normal':flow='排除已用宝箱 → 比较普通/内含类型并取得下一等级 → 排除工厂限制 → 同类型且有下一等级才合成。'
            if n['key']=='eligibility' and s['key']=='special':flow='读取源特殊类型 → 两剪刀直接许可 → 否则核对目标许可 → 拆分再检查空位。'
            n['overview']+='\n\n## 本机制怎样执行\n\n'+flow+'\n\n本页说明这一步的条件与结果；下一层给出对应变量、比较、完整配表与数值推演。'
            if s['key']=='special' and n['key']=='upgrade':n['icons']=('level_up_piece_1','202')
            if s['key']=='special' and n['key'] in ('scissors','split'):n['icons']=('level_down_piece_1',)
            if s['key']=='normal' and n['key']=='coin':n['icons']=('2401',)
    nav=[{'棋子拖拽与合成':['operations/merge/index.md']}]
    root_nav=nav[0]['棋子拖拽与合成']
    mapped=[]
    BASE.mkdir(exist_ok=True)
    p=BASE/'index.md'
    p.write_text('''# 棋子拖拽与合成

一次拖动由松手位置和当前棋盘状态共同决定。先把输入转换为有效落点，再按固定优先级解释目标：空格移动优先结束；有目标先尝试特殊作用，再尝试普通合成，再尝试吞噬；都没有接收才拒绝或交换。模型处理结束后，界面还会更新选中状态与释放反馈。

## 从松手到结果的顺序

| 顺序 | 当前做什么 | 何时结束这条分派 |
| --- | --- | --- |
| 1 | 检查可移动性、吸附/教程落点、仓库存入、坐标与源身份 | 存入成功、非法位置或旧对象 |
| 2 | 目标为空或是原对象：移动并刷新加速 | 移动完成立即返回 |
| 3 | 有目标：升级/剪刀等特殊作用 | 打开确认窗或特殊作用成功 |
| 4 | 同逻辑类型且有下一等级：普通合成与其追加结算 | 合成完成立即返回 |
| 5 | 不可合成：目标是否需要吞入这件物品 | 吞噬成功立即返回 |
| 6 | 最后兜底：目标不可移动则复位，否则交换 | 拒绝或交换完成 |
| 7 | 返回视图：选中结果、刷新栏与提示、发释放通知 | 本次输入收尾完成 |

这些是有条件执行的阶段，不是每次拖动都执行所有操作。普通合成内部还有严格顺序：新物创建与订单刷新、合成通知、四邻格震动、竞速、临时物、卡片、能量气泡、普通气泡、金币和同步日志。特殊升级、剪刀与吞噬各有自己的结算路径，不能自动套用普通合成奖励。
'''+case(p,'两个201匹配普通合成，目标格出现202、源格空出；无额外气泡或金币，能量仍为10。左侧逐层展开可以查看每一步的判断，末层给出实现算法、对应配表与数值推演。',icons=('201','202')),encoding='utf-8')
    for s in STEPS:
        d=BASE/s['key'];d.mkdir(exist_ok=True);p=d/'index.md'
        steps='\n'.join(f"{i}. **{n['title']}**：{n['overview'].splitlines()[0]}" for i,n in enumerate(s['children'],1))
        p.write_text('# '+s['title']+'\n\n'+s['overview']+'\n\n## 判断与分支（按触发位置）\n\n'+steps+'\n'+case(p,s['example']),encoding='utf-8')
        snav=[f"operations/merge/{s['key']}/index.md"]
        root_nav.append({s['title']:snav})
        for n in s['children']:
            d=BASE/s['key']/n['key'];d.mkdir(exist_ok=True)
            p=d/'index.md'
            p.write_text('# '+n['title']+'\n\n'+n['overview']+'\n'+case(p,n['example'],icons=n['icons']),encoding='utf-8')
            p=d/'detail.md'
            p.write_text('# '+n['title']+'：具体算法与配置\n\n'+n['detail']+'\n'+configs(n,p)+evidence(n,p)+case(p,n['example'],n['calculation'],n['icons']),encoding='utf-8')
            snav.append({n['title']:[f"operations/merge/{s['key']}/{n['key']}/index.md",{'具体算法与配置':f"operations/merge/{s['key']}/{n['key']}/detail.md"}]})
            mapped.append({'step':s['key'],'mechanism':n['key'],'page':p.relative_to(DOCS).as_posix(),
                           'source_modules':n['modules'],'review_status':'documented-rule-scope; whole-branch-closure pending'})
    # Preserve all non-merge YAML text byte-for-byte, including user custom nav.
    config=SITE/'mkdocs.yml';text=config.read_text(encoding='utf-8')
    start=re.search(r'(?m)^  -\s+棋子拖拽与合成:',text).start()
    end=re.search(r'(?m)^  -\s+订单',text[start:]).start()+start
    subtree=yaml.safe_dump(nav,allow_unicode=True,sort_keys=False,width=1000,indent=4)
    subtree='\n'.join('  '+l for l in subtree.splitlines())+'\n'
    config.write_text((text[:start]+subtree+text[end:]).replace('    - navigation.sections\n',''),encoding='utf-8')
    expected={BASE/'index.md'}
    for s in STEPS:
        expected.add(BASE/s['key']/'index.md')
        for n in s['children']:
            expected.update({BASE/s['key']/n['key']/'index.md',BASE/s['key']/n['key']/'detail.md'})
    # Backed-up stale pages must not remain searchable competing explanations.
    removed=[]
    for old in BASE.rglob('*.md'):
        if old not in expected:
            if not old.resolve().is_relative_to(BASE.resolve()):raise ValueError(old)
            removed.append(old.relative_to(BASE).as_posix());old.unlink()
    archive_path = AUDIT/'archived_pages.json'
    previous = json.loads(archive_path.read_text(encoding='utf-8')) if archive_path.exists() else []
    archive_path.write_text(json.dumps(sorted(set(previous + removed)),ensure_ascii=False,indent=2),encoding='utf-8')
    (AUDIT/'document_map.json').write_text(json.dumps(mapped,ensure_ascii=False,indent=2),encoding='utf-8')
    # Preserve separately maintained gate reviews on later document rebuilds.
    if not (AUDIT/'REVIEW.md').exists():
        (AUDIT/'REVIEW.md').write_text('''# 拖拽与合成工作记录

按计划6.8建立独立源码/监听候选清单、真实执行骨架与四层说明。备份在before；只改merge导航和本操作页面。

已纠正旧报告：交换最后一次写格会刷新订单；0基础气泡不进入正常衰减；吸附为每轴1格且时间严格小于0.15秒；购买气泡记忆在普通后处理先清空；卡片备用入口等级条件按源码而非直觉解释；能量气泡外层无满盘检查；同code重复吞噬槽的内部选择不同于外层资格。

source_inventory.json为独立候选分母，不等于所有函数属于本操作，也不授予语义通过。document_map.json为已解释规则到页面映射，不批准整函数和全部下游。所有原型、动态/局部消费者、订单状态及奖励/同步生命周期须继续核销。

门禁：G1 pending；G2 pending（消费者闭包未全核销）；G3 pending；G4 pending；G5 pending（本地记录已展示，全字段/实际账号选表仍需核对）；G6 pending（展示与语义分别验证）；G7 unavailable（没有原版运行环境，受控字节码验证另外记录）。不能宣称全量通过或完整复刻。
''',encoding='utf-8')
    print(json.dumps({'stages':len(STEPS),'mechanisms':len(mapped),'pages':1+len(STEPS)+2*len(mapped),'dependency_modules':len(records),'listener_candidates':len(listeners)},ensure_ascii=False))


if __name__=='__main__':build()
