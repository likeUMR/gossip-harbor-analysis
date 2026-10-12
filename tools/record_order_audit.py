"""Record evidence and outstanding semantic gates separately from presentation."""
import json
from stage3_order_documents import AUDIT,ASSETS,BASE,SITE,DOCS
from stage3_merge_documents import ROOT,sha

def run():
 inv=json.loads((AUDIT/'source_inventory.json').read_text(encoding='utf-8'))
 funcs=sum(len(m['functions']) for m in inv['modules'])
 units=sum(len(f['units']) for m in inv['modules'] for f in m['functions'])
 cfg=json.loads((AUDIT/'config_inventory.json').read_text(encoding='utf-8'))
 tests=json.loads((AUDIT/'rule_tests.json').read_text(encoding='utf-8'))
 pages=list(BASE.rglob('*.md'))
 manifest=[dict(path=p.relative_to(ROOT).as_posix(),sha256=sha(p),bytes=p.stat().st_size) for p in sorted(ASSETS.iterdir()) if p.is_file()]
 (AUDIT/'asset_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 review=f'''# 订单提交批次审核（2026-10-12）

按计划6.8工作流建立候选账本、末层算法、四层顺序文档、贯穿案例、源码/原始指令/完整本地配表及专项检查。本批为7真实阶段、35子机制、{len(pages)}页面。父页先讲行为意图、执行顺序与分支，末页讲变量、数值与边界。工作记录留在此处与工作计划，不作为领导网页的主题分类。

## 已有证据

- source_inventory.json：{len(inv['modules'])}候选模块、{funcs}命名函数、{units}控制流/状态候选、{len(inv['listener_candidates'])}监听注册候选。整模块包含无关函数；动态关联可能增加范围，不是最终覆盖率分母。函数/分支候选仍为pending，未自动按方法名认定通过。
- document_map.json：35机制的末页、模块与方法选择器；只表示有对应说明，未批准全部下游闭包。原始指令单独附存，匿名原型与恢复函数的一对一映射仍需核销。
- config_inventory.json：{len(cfg)}份本地表/变体全部执行原始转换字节码解析成功、全记录全字段展示；其中NewItemOrderConfig由ConfigModel的TutoriaiOrderConfig键映射取得。字段总条数是记录计数，不代表去重后的有效账号配置。
- rule_tests.json：{len(tests['cases'])//2}选定案例分别执行原始转换字节码与恢复源码，{tests['passed']}/{tests['total']}通过。服务、DB、活动和视图依赖为显式替身；没有运行原版Unity客户端。
- site_validation.json：{len(pages)}页面四层、每目录父页、渲染、素材和下载路径、正文不以站内文档跳转代替层级的检查通过；母体与合成导航与before记录相同。
- 实际浏览器点击验证第二、第三、第四层各有页面；第三层以步骤与目的概括，第四层含执行变量。物品204原版小图显示正常。OrderItemConfig默认74条，输入203后显示1/74，与Price2、DiffScore2一致。截图inventory-mechanism.png、price-config-filter.png。

## 本轮核实的实现差异

仓库确认关闭后只核对订单成员，不复核材料；普通链先即时发奖再逐件扣物；扣物失败记错并继续，无回滚；棋盘从(1,1)横向扫到(7,1)再下一行，每件需求重扫，仓库仅次级兜底，结果以需求索引稀疏保存；分支奖励有限份额抽至耗尽；宝箱预算可超额，先抽方案再展开，落盘不足进缓存；普通随机先预选三个候选后抽项数；Lucky订单与母体Lucky独立，资格先消耗、points1启动CD；教程完成通知在补位后；连续首池全空兜底209；额外顾客EmptyReqOrder的Dormant状态明确拒绝CanDeliver。

## 门禁判定

G1 pending（最终范围、匿名原型/动态入口未逐项核销）；G2 pending（全部调用/消费者/二次派发未闭合）；G3 pending（所有分支、同帧/回调边界未全部验证）；G4 pending（原生保存、事件后的状态和重载全过程未闭合）；G5 pending（本地记录已导出，逐字段使用与选表/远端参数仍待核对）；G6 pending（结构展示通过，不能代替逐段语义逆查）；G7 unavailable（仅安装包与解包资源，没有原版运行环境）。不得用页面数、测试数或截图声称全量通过、无遗漏或已经可以完整复刻。
'''
 (AUDIT/'REVIEW.md').write_text(review,encoding='utf-8')
 remaining='''# 尚未放行项

## 已取得代码，仍可继续分析

1. 按稳定标识核销原型、函数与分支，逐项区分相关/不相关并给理由。当前整模块候选账本为独立发现起点，不是全部已审阅的分母。
2. OrderFinished、MainOrderCreated、ChestCustomerOrderFinish、SmileOrderDeliver_1、OrderStateChanged及局部FinishOrder的全部注册与动态消费者、再派发、任务/活动状态变化。注册行只发现候选，不能宣称34条监听已闭合。
3. MainOrder.GetRewards全部活动公式和实际奖励handler的动态分派，PropertyDataManager、BuffManager、亲密度礼物及额外领取；当前提供订单直接追加顺序与若干专用规则，未把所有活动内部实现都当作已完成。
4. GetDynamicMaxLevel、普通候选预选/项数、Lucky库存约束、全部随机创建器、头像/礼物、FileReplace装载与缓存，逐路径执行验证及异常数据边界。当前测试未覆盖所有这些算法组合。
5. 组件RemoveItem、仓库删除、缓存写入、DBAdd/DBRemove/重载、SyncModel和事件再派发的存档闭包。只读得保存字段不等于原生数据持久化已验证。
6. MainBoardView、特殊窗、订单动画辅助函数、连续额外奖励、教程/活动弹窗、关闭和延迟回调完整链。当前明确直接调度，仍需所有辅助内部逻辑与锁定状态核销。
7. CookingFrenzy定向选物、宝箱优化分支CalculateOrderCodeLackNumMap及合成库存换算、活动档位读取全部相关原型和本地/远端字段的逆向映射。
8. EmptyReqOrder刷新需求、TimedOrder覆写、连续/额外顾客状态保存与后续要求确定：创建入口规则已补，但活动生命周期和所有运行触发仍待逐项核销。

## 缺少外部材料

- 实际账号FileReplace、服务器活动档位、开关、付费/时间/进度和存档输入：可解释客户端字段/算法，不能给出账号实际抽样分布。
- 原版可运行客户端及相同输入状态：G7逐事件/状态/存档差分 unavailable。受控Lua执行不能代替原版运行观察。
- 服务器内部处理若客户端只暴露接口，另列接口约束与客户端可见行为，不编造实现。

前一组不是“无法解决”，继续分析即可推进。外部材料不足也不能掩盖已有代码尚未核销的工作。
'''
 (AUDIT/'REMAINING.md').write_text(remaining,encoding='utf-8')
 old=ROOT/'analysis_output/logic_recovery/stage3/orders_analysis_report.md'
 if old.exists():
  text=old.read_text(encoding='utf-8')
  if '订单提交四层文档批次取代' not in text:
   old.write_text('> 历史初稿：本报告由2026-10-12订单提交四层文档批次取代。新证据与门禁以order_gate_audit/REVIEW.md、REMAINING.md为准。旧仓库确认未取得、分支配置缺失、限时奖励直接追加、随机语义未知等结论不能继续作为实现依据。\n\n'+text,encoding='utf-8')
 plan=ROOT/'GH_LOGIC_RECOVERY_PLAN.md';text=plan.read_text(encoding='utf-8')
 if '### 9.10 订单提交四层文档批次' not in text:
  entry=f'''### 9.10 订单提交四层文档批次（2026-10-12）

依据6.8工作流补全订单提交的四层叙述，当前7真实阶段、35子机制、{len(pages)}页面：点击交付与确认 → 模型类型分流 → 普通奖励 → 标完成并扣物 → 烹饪/宝箱/延迟奖励 → 所属模型完成与多轮补位 → 同步和交付表现。通知消费者与状态改变归入真实触发步骤，没有创建事件/安全边界主题子树。每层目录有独立页面；第三层定性说明内部处理顺序与目的，第四层算法、边界、完整本地配表与数值案例。贯穿案例为203×2与204×1仓库补交，原版小图按页使用。

确认仓库窗关闭后不复核材料、普通先发奖后扣物且失败不回滚、棋盘横向逐行首匹配、稀疏需求索引、分支有限份额抽尽、宝箱预算/有放回选奖/缓存兜底、普通先选三候选后抽项数、Lucky订单点数/CD与母体Lucky分离。补位专用教程/连续/额外顾客已回到实际优先级：教程跳过/进度、连续兜底209、空需求EmptyReqOrder覆盖拒绝Dormant交付。ConfigModel教程键实际装载NewItemOrderConfig，不因拼写差异误判配表缺失。

{len(cfg)}份本地配置/变体原始转换字节码解析成功并展示全字段；{len(tests['cases'])//2}选定案例双模式执行{tests['passed']}/{tests['total']}通过；{len(pages)}页面结构/渲染/路径/案例专项通过。浏览器实际点击四层父页，展开并筛选默认74条物品表，203定位为1/74、Price2/DiffScore2；截图保存在order_gate_audit。母体/合成导航保持原值，仅订单子树与订单资源更新。

审核目录`analysis_output/logic_recovery/stage3/order_gate_audit/`包含before备份、候选清单、机制映射、配置记录、资源哈希、受控测试、展示检查、REVIEW.md、REMAINING.md及截图。候选{len(inv['modules'])}模块、{funcs}命名函数、{units}控制流/状态候选与{len(inv['listener_candidates'])}注册候选均不等于相关逻辑最终分母，不计算虚假覆盖率。

**未全量放行：G1–G6 pending，G7 unavailable。**可继续工作明确列入REMAINING：匿名原型、动态消费者/二次派发、全部活动/handler、随机组合、保存/重载、视图辅助回调、配置使用闭包与专用活动生命周期。账号远端值及原版差分缺外部材料，单列；不能把已有代码未核销称为无法解决。文档批次与选定验证完成，不宣称所有订单逻辑已无遗漏或可以完整复刻。

'''
  plan.write_text(text.replace('## 10. 证据与问题管理',entry+'## 10. 证据与问题管理'),encoding='utf-8')
 print(json.dumps(dict(pages=len(pages),modules=len(inv['modules']),functions=funcs,units=units,configs=len(cfg),tests=tests['passed']),ensure_ascii=False))

if __name__=='__main__':run()
