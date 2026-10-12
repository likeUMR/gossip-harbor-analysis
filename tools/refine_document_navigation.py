"""Refine labels in place; keep execution order, URLs, specifications and cases."""
from pathlib import Path
import hashlib,json,re,shutil
import yaml
ROOT=Path('C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis')
SITE=ROOT/'analysis_output/logic_recovery/stage3/mkdocs_site'
DOCS=SITE/'docs'
AUDIT=ROOT/'analysis_output/logic_recovery/stage3/navigation_naming_audit'

# Keys are stable content directories; labels describe responsibility, not a narrated transition.
NAMES={
 'merge/release':'拖拽检查',
 'merge/release/movable':'拖动资格',
 'merge/release/position':'落点吸附与教程限制',
 'merge/release/inventory':'棋子入库',
 'merge/release/identity':'坐标与对象校验',
 'merge/move':'棋子移动',
 'merge/move/write':'位置更新',
 'merge/move/accelerate':'加速刷新',
 'merge/special':'升级与剪刀',
 'merge/special/eligibility':'道具目标资格',
 'merge/special/upgrade':'道具升级',
 'merge/special/scissors':'剪刀次数合并',
 'merge/special/split':'剪刀拆分',
 'merge/special/failure':'道具作用失败',
 'merge/normal':'普通合成',
 'merge/normal/eligibility':'合成资格',
 'merge/normal/replacement':'合成结果生成',
 'merge/normal/notify':'合成通知与邻格震动',
 'merge/normal/score':'竞速计分',
 'merge/normal/temp':'临时棋子产出',
 'merge/normal/card':'卡片产出',
 'merge/normal/energy':'能量气泡产出',
 'merge/normal/bubble':'普通气泡产出',
 'merge/normal/coin':'金币棋子产出',
 'merge/normal/finish':'合成记录与同步',
 'merge/swallow':'棋子吞噬',
 'merge/swallow/target':'吞噬需求与资格',
 'merge/swallow/progress':'吞噬进度',
 'merge/swallow/transform':'吞噬完成变换',
 'merge/swap':'棋子交换',
 'merge/swap/blocked':'交换资格',
 'merge/swap/exchange':'位置交换',
 'merge/pointer':'拖拽收尾',
 'merge/pointer/selection':'选中与释放',
 'orders/entry':'交付检查',
 'orders/entry/button':'按钮资格',
 'orders/entry/counts':'棋盘物品计数',
 'orders/entry/requirements':'需求数量核对',
 'orders/entry/inventory':'仓库补交',
 'orders/entry/special_window':'特殊任务确认',
 'orders/dispatch':'订单分流',
 'orders/dispatch/type':'订单类型判断',
 'orders/dispatch/special':'特殊任务交付',
 'orders/dispatch/branch':'分支任务交付',
 'orders/rewards':'奖励结算',
 'orders/rewards/price':'订单价格与难度',
 'orders/rewards/activity':'活动奖励收集',
 'orders/rewards/snapshot':'奖励分组与快照',
 'orders/rewards/acquire':'即时奖励发放',
 'orders/rewards/gift_buff':'礼物与Buff奖励',
 'orders/rewards/smile':'微笑进度',
 'orders/consume':'需求扣除',
 'orders/consume/mark':'订单完成标记',
 'orders/consume/board':'棋盘扣物',
 'orders/consume/store':'仓库扣物',
 'orders/consume/refresh_failure':'扣物刷新与缺物处理',
 'orders/after':'烹饪与宝箱奖励',
 'orders/after/cooking':'烹饪狂热奖励',
 'orders/after/chest_delay':'宝箱顾客奖励',
 'orders/refill':'订单补位',
 'orders/refill/owner_history':'完成历史与Lucky资格',
 'orders/refill/loop':'补位循环',
 'orders/refill/priority':'创建优先级',
 'orders/refill/fixed_return':'固定与回归订单',
 'orders/refill/tutorial':'教程订单',
 'orders/refill/continuous':'连续订单',
 'orders/refill/extra':'额外顾客入口',
 'orders/refill/lucky':'Lucky订单',
 'orders/refill/random_gate':'随机订单资格',
 'orders/refill/candidates':'候选筛选与权重',
 'orders/refill/dynamic':'订单难度调整',
 'orders/refill/draw':'需求抽取与项数',
 'orders/refill/save':'订单存档与恢复',
 'orders/finish':'交付收尾',
 'orders/finish/sync':'状态刷新与同步',
 'orders/finish/animation':'交付动画',
}

def paths(nav):
    if isinstance(nav,str):return [nav]
    if isinstance(nav,list):return [p for n in nav for p in paths(n)]
    if isinstance(nav,dict):return [p for n in nav.values() for p in paths(n)]
    return []

def main():
    AUDIT.mkdir(parents=True,exist_ok=True)
    before=AUDIT/'before'
    if before.exists():raise RuntimeError('Existing snapshot: review before a second naming pass')
    before.mkdir()
    config=SITE/'mkdocs.yml';original=config.read_text(encoding='utf-8');nav=yaml.safe_load(original)['nav']
    replacements={};ledger=[]
    for directory,new in NAMES.items():
        page=DOCS/'operations'/directory/'index.md'
        text=page.read_text(encoding='utf-8');old=text.splitlines()[0].removeprefix('# ')
        assert old!=new,(directory,old)
        replacements[old]=new
        ledger.append(dict(directory=directory,old=old,new=new,responsibility=text.split('\n\n')[1],url='http://127.0.0.1:8000/operations/'+directory+'/'))
    pattern=re.compile('|'.join(re.escape(old) for old in sorted(replacements,key=len,reverse=True)))
    def rename(text):return pattern.sub(lambda m:replacements[m.group()],text)
    targets=[config]+[p for op in ('merge','orders') for p in sorted((DOCS/'operations'/op).rglob('*.md'))]+[ROOT/'tools/stage3_merge_documents.py',ROOT/'tools/stage3_order_documents.py']
    changed=[]
    for p in targets:
        old=p.read_text(encoding='utf-8');new=rename(old)
        if old==new:continue
        dest=before/p.relative_to(ROOT);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
        p.write_text(new,encoding='utf-8');changed.append(str(p.relative_to(ROOT)))
        # Every byte of content other than the explicit label substitutions must stay intact.
        assert p.read_text(encoding='utf-8')==rename(old)
    updated=yaml.safe_load(config.read_text(encoding='utf-8'))['nav']
    assert paths(nav)==paths(updated),'Path membership/order changed'
    assert nav[0]==updated[0],'Generator navigation changed'
    for row in ledger:
        p=DOCS/'operations'/row['directory']/'index.md'
        assert p.read_text(encoding='utf-8').splitlines()[0]=='# '+row['new']
        detail=p.parent/'detail.md'
        if detail.exists():assert detail.read_text(encoding='utf-8').splitlines()[0]=='# '+row['new']+'：具体算法与配置'
    report=dict(nodes=len(ledger),changed_files=changed,names=ledger,structure_decision='Retain existing four levels and real execution order. Labels require refinement; no evidence warrants moving nodes.',checks={'urls_and_order_preserved':True,'generator_nav_preserved':True,'label_substitutions_only':True,'headings_consistent':True},limits='Naming and organization review only; semantic/runtime recovery gates retain existing status.')
    (AUDIT/'naming_map.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(dict(nodes=len(ledger),changed_files=len(changed),checks=report['checks']),ensure_ascii=False))

if __name__=='__main__':main()
