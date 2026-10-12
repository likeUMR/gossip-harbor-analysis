"""Review reload and acceleration contracts; keep unresolved edges explicit."""
import json,shutil
from reconcile_generator_logic import ROOT,OUT,DOCS,sha
SOURCES={'Boost':'e153e5646c658a0cfbd2c7ca4bce3a07202bab1ef4e5ef0782585dca7f5e7f01','ItemData':'a0ad2195b6bcb12714dad2e37c1d07ba366d85ab9283aa3679b220e257ee3340','AccelerateTime':'aa7c402120a0154e9f84c75888adc25ea2a8aa3d7a33dc14520e5640772205c8','Lucky':'937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505'}
BODIES={
 'output/preparation/detail.md':'''## 活动替换配置与当前母体实例的区别

GeneratorBoost的GetItemModelConfig依次判断MoreLuckyProduce、ExtraLuckyProduce、ExtraProduce，返回第一个生效Buff的对应本地表；都未生效则返回nil。ReloadItemModelConfig在非nil配置时重建变化类型集合，然后交给ItemDataModel:ReloadFileConfig；传nil时没有在这里清空变化类型集合。

ItemDataModel重载要求GeneratorBoost模型存在。传入替代表时只遍历该表，将记录按Type写入配置映射；传nil时遍历默认ItemModel，变化集合不存在就全恢复，否则只恢复集合中的类型。记录ChainId为nil时才解析链号和等级，并把Spread_Weight字符串转为Code/Weight数组、保存其字符串形式；已经有ChainId则跳过这些预处理。

这段重载修改配置映射，没有直接遍历现有棋子重新Init，也没有在这里改已有实例的次数、CD起点或权重池。SafeSpreadItem比较的是实例保存的上限；不能认为替换配置后，它会自动用新表上限裁剪旧实例。新对象和重建对象取得哪份配置，由实际创建路径决定。
''',
 'lifecycle/cooldown/detail.md':'''## 邻近加速如何影响母体计时

ItemAccelerateTime初始化m_time=0、m_lastUpdateTime=0。UpdateAccelerateTime扫描母体八个邻格，只取存在且已激活的ItemAccelerate，计算每个邻格的起点加时长，并取最晚结束时间；多枚加速物不会在这一步累加倍率。最晚结束时间不大于当前服务器时间，就改为0。

旧m_time或新时间任一非0时，保存lastUpdateTime=当前时间、m_time=新时间并请求SaveItemProperty；两者都0不写这两个字段。无论是否保存，最后都发组件UpdateView。IsAccelerated仅比较m_time是否非0，不再比较当前时间；过期标记的清理依赖UpdateAccelerateTime调用，不能将这个getter自行改成时间比较。

母体随后推进冷却时，以min(加速结束时间,当前时间)封顶修正计时起点，所以仅结算有效加速区间。例如起点990、当前1000、上次更新时间995、加速结束1005：新起点=990+995-1000=985；本次恢复进度按15秒而非10秒计算。加速结束与上次更新时间保存在accelerateTime、accelerateLastUpdateTime，恢复对象分别用存档值和原样字段覆盖；加速结束缺值时默认0。
''',
 'lucky/chance/load.md':'''## Buff切换何时真正清机会池

GeneratorBoost重载Lucky前，要求Lucky模型存在且GetState(true)==Started，否则直接返回。取得当前Buff的Lucky配置后，比较“上次是否使用GeneratorBoost配置”和“当前配置是否非nil”，布尔状态不同才传bUpdate=true；先保存当前布尔标记，再调用Lucky的ReloadFileConfig。两个非nil的Buff配置互相切换时，这个布尔比较仍相同，因此本入口不必然清池。

Lucky重载先_LoadFileConfig，再CalculateItemChainMap，最后仅在bUpdate为真时，遍历新表的generator，依次清幸运剩余份额和总剩余份额。清除方法仅在该类型的进程内键缓存已生成时删除DB行；未生成键时直接返回。新表没有列出的旧母体、免费机会和连续Lucky状态，不由此循环统一删除。

### 两种切换的具体例子

假设母体105当前机会池总剩余8、Lucky剩余2，两种键都已缓存。默认配置切入GeneratorBoost配置，旧标记false、新标记true，bUpdate=true；新表列出105则删除ll_105和tl_105，后续点击按新配置重新建立机会池。若从MoreLuckyProduce切为ExtraLuckyProduce，两份配置都非nil，旧新标记均true，则bUpdate=false；本入口不删除这两行，不能在复刻时无条件重置。若新表只列106，105旧行不在本次清除范围。
''',
}
def main():
 OUT.mkdir(parents=True,exist_ok=True)
 for rel,body in BODIES.items():
  p=DOCS/'operations/generator'/rel;text=p.read_text(encoding='utf-8');start='<!-- reconciliation-reload:start -->'
  if start in text:continue
  dest=OUT/'before_reload'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
  heading=text.find('\n## 贯穿案例')
  if heading<0:heading=text.find('\n---')
  assert heading>=0,rel
  text=text[:heading]+'\n'+start+'\n'+body+'\n<!-- reconciliation-reload:end -->\n'+text[heading:];p.write_text(text,encoding='utf-8')
 sources=[]
 for name,h in SOURCES.items():
  p=ROOT/'analysis_data/logic_index/lua/decoded'/h/'decompiled.lua';sources.append({'name':name,'source':p.relative_to(ROOT).as_posix(),'sha256':sha(p)})
 report={'sources':sources,'documents':[{'page':'operations/generator/'+rel,'sha256':sha(DOCS/'operations/generator'/rel)} for rel in BODIES],'rules':['Boost configuration priority and retained changed-type set','ItemData mapping reload vs instance state','Lucky boolean transition controls bUpdate','cached-key-only clear and new-config-only generators','eight-neighbor acceleration max endpoint, save conditions and view notice'],'open_edges':['IsBuffActive and transition lifecycle','config selection/FileReplace all variants and fields','new/rebuilt ItemModel component configuration','acceleration update scheduling and neighbor ItemAccelerate lifetime','component UpdateView consumers','DB clear/serialize/native commit'], 'full_acceptance':False}
 (OUT/'reload_review.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8');print('3 existing pages supplemented')
if __name__=='__main__':main()
