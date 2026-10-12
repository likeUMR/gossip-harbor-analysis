"""Explain cumulative buffs and the actual refresh callback at the CD step."""
import json,shutil
from reconcile_generator_logic import ROOT,OUT,DOCS,sha
SOURCES={'Boost':'e153e5646c658a0cfbd2c7ca4bce3a07202bab1ef4e5ef0782585dca7f5e7f01','Board':'c0065dc8ae320f8e49a76b6ab8593622c4cf0c3ff15e58bfe0a58a625636888e','ItemModel':'fb8d36d654cec2246492dcadb68978c704d3e94c4d15fd4571c7d9959133451d','BaseBoard':'014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce','Accelerate':'b7fd3d5b0e2dcd781c170cad2383a069bfad62536e6fe881e4e7a121cf933ceb'}
BODIES={
 'lifecycle/cooldown/detail.md':'''## NoCD解锁与本次点击末尾的跳时

GeneratorBoost的IsBuffActive先要求活动GetState(false)==Started、已解锁等级大于0，再扫描1至当前等级，只要其中任何等级是所问Buff就为真。已解锁Buff累积保留，不是只看当前等级。BuffLevelUp有下一级配置时先保存等级，再记日志；解锁NoCD才发送GeneratorBoostBuffActiveLogic。之后无论是否存在下一级，都设置主窗口待弹标记和主动产出标记。

主棋盘在初始化时为该全局事件注册包装回调：先确认存在已开始的GeneratorBoost活动，然后按棋盘有效格顺序扫描，取得ItemSpread并确认CanSupportGeneratorBoostCDBuff，才调用组件OnTimeSkipInZeroRestNumber。该方法再次要求生成器、需要能量、属于主棋盘；次数恰为0才调用OnTimeSkip(nil,Buff)，随后发StateChanged。不是所有棋子全部清CD，也不是每个合格母体都被扣掉当前恢复时间。

本次点击成功落盘且没有变换或删除母体后，另由_TrySpread调用TryUseCDBuff；普通CD Buff、GeneratorBoost NoCD、测试免费CD任一资格成立，次数0才跳时，最后发状态事件。OnTimeSkip(nil)先把起点改为当前时间，再减当前阶段完整时长，保存、播放加速音效、调用UpdatePerSecond恢复；不能实现成简单“次数补满且清计时”，因为可能在恢复后进入储备阶段。

### NoCD也可能接续储备恢复

假设105次数0、储备10、次数上限80、单轮30秒、储备60秒、已有恢复起点；当前时间1000，NoCD成立。OnTimeSkip(nil)设起点970，随后恢复先补次数80、储备10-80截0，起点推进1000。此时储备阶段进度0，计时仍存在，并非全部恢复已经结束；玩家获得80次可用产出，储备仍0，后续恢复按储备阶段规则处理。

## 活动结束怎样清除Buff

_OnStateChanged在校验资源的状态Started时注册任务进度模块，Ended或Released时移除；不校验资源的状态Ended/Released时调用ClearBuff，最后发送活动状态事件。ClearBuff在当前等级0时直接返回，否则先删等级、额外产出总份额和剩余份额，再删两类额外产出缓存，恢复物品配置、重载Lucky配置、关闭主动产出并发送GeneratorBoostBuffCleared。这里没有把所有母体次数或计时字段统一重置。

## 每秒更新与组件遍历

MainBoardModel仅在其游戏模式等于当前场景模式时推进棋盘组件；订单模型仍在之后逐个更新。BaseBoardModel以pairs遍历全部棋子，再由ItemModel以pairs遍历组件，调用存在的UpdatePerSecond方法。不能假设棋子按坐标排序，或母体组件必定先于加速组件更新。

邻格加速物已有起点时，到期先尝试Transform；没有变换组件才RemoveItem并发送CollapseItem。激活时写起点、立即检查到期、请求保存、发组件Activated，再发全局ItemActivated。ItemAccelerateTime的八邻格重新计算函数与这条每秒遍历并非同名方法；当前直接调用搜索尚未找到其调度入口，因此不能宣称它必定在每秒冷却推进之前执行。
''',
 'output/preparation/detail.md':'''## 累积Buff对配置选择的影响

IsBuffActive扫描所有已解锁等级，早期Buff不会因解锁下一等级自动消失。如果已解锁列表同时包含MoreLuckyProduce和ExtraLuckyProduce，GetItemModelConfig仍优先返回MoreLuckyProduce；ExtraProduce的表优先级更低。能否发生真实配置切换，应结合活动实际等级表与状态判断，不能把“新Buff名称出现”当作“新配置已覆盖”。ClearBuff删除激活等级后才恢复默认物品配置，其变化类型集合仍用于限定恢复范围。
''',
 'lucky/chance/load.md':'''## 接口切换例子与真实升级路线的区别

上面的非nil配置互切例子用于演示ReloadLuckyProduceConfig的布尔判断，前提是假设两次GetLuckyProduceConfig确实返回不同非nil配置。真实IsBuffActive扫描全部已解锁等级；若MoreLuckyProduce与ExtraLuckyProduce同时生效，GetLuckyProduceConfig仍先选MoreLuckyProduce。因此“解锁ExtraLucky”不等于必定从MoreLucky表切走。默认切入Boost可重置机会池，而某个实际升级是否重置，要按累积Buff、取表优先级和上次布尔标记共同判断。
''',
}
def main():
 OUT.mkdir(parents=True,exist_ok=True)
 for rel,body in BODIES.items():
  p=DOCS/'operations/generator'/rel;text=p.read_text(encoding='utf-8');marker='<!-- reconciliation-buff:start -->'
  if marker in text:continue
  dest=OUT/'before_buff'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
  i=text.find('\n## 贯穿案例');i=i if i>=0 else text.find('\n---');assert i>=0
  p.write_text(text[:i]+'\n'+marker+'\n'+body+'\n<!-- reconciliation-buff:end -->\n'+text[i:],encoding='utf-8')
 sources=[]
 for name,h in SOURCES.items():
  p=ROOT/'analysis_data/logic_index/lua/decoded'/h/'decompiled.lua';sources.append(dict(name=name,source=p.relative_to(ROOT).as_posix(),sha256=sha(p)))
 result={'sources':sources,'documents':[dict(page='operations/generator/'+rel,sha256=sha(DOCS/'operations/generator'/rel)) for rel in BODIES], 'resolved_rules':['Buff cumulative qualification and table priority','NoCD activation→dynamic board wrapper→qualified component dispatch→zero-rest skip','ClearBuff state/config sequence','MainBoard mode gate and unordered component iteration','acceleration activation/end direct flow'],'open_edges':['ItemAccelerateTime.UpdateAccelerateTime actual scheduler','task progress and buff unlock all callers','ClearState daily/round lifecycle','state, cleared, ItemActivated, CollapseItem and component listeners','full configuration records and consumer mapping','scheduler and native DB commit'], 'full_acceptance':False}
 (OUT/'buff_lifecycle_review.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print('3 pages supplemented')
if __name__=='__main__':main()
