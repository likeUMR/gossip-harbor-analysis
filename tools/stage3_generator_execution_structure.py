"""Place explanations within execution stages; never add thematic stage groups."""
from pathlib import Path
import re

def wire(config):
    config=config.replace('operations/generator/overrides/activity/', 'operations/generator/output/disco/')
    for title in ('事件与后续影响','产出改写与安全边界'):
        config=re.sub(r'(?ms)^      - '+title+r':\n.*?(?=^      - |^  - |\Z)','',config)
    if '次数上限与教程强制:' not in config:
        config=config.replace('          - Fixed:\n','''          - 次数上限与教程强制:
              - operations/generator/output/preparation/index.md
              - 数值边界与强制代码的结算: operations/generator/output/preparation/detail.md
          - Fixed:
''',1)
    if '链升级与订单补缺:' not in config:
        config=config.replace('      - 扣除次数与 CD 恢复:\n','''          - 链升级与订单补缺:
              - operations/generator/output/upgrade/index.md
              - 升级截档与生鱼补缺算法: operations/generator/output/upgrade/detail.md
          - 产物落子:
              - operations/generator/output/landing/index.md
              - 创建、落子与活动响应的结算顺序: operations/generator/output/landing/detail.md
      - 扣除次数与 CD 恢复:
''',1)
    return config

def body(text):
    return text.split('\n---\n',1)[0]

def append(page,content):
    text=page.read_text(encoding='utf-8')
    text=re.sub(r'\n<!-- execution-inline:start -->.*?<!-- execution-inline:end -->\n?', '\n',text,flags=re.S)
    content=re.sub(r'^# ', '## ',content,flags=re.M)
    addition='\n<!-- execution-inline:start -->\n'+content+'\n<!-- execution-inline:end -->\n'
    text=text.replace('\n---\n',addition+'\n---\n',1)
    page.write_text(text,encoding='utf-8')

def supplement(docs):
    base=docs/'operations/generator'
    for old,new in [('overrides/activity','output/disco'),('overrides/safety','output/preparation'),('overrides/boost','output/upgrade'),('events/board','output/landing')]:
        target=base/new
        target.mkdir(parents=True,exist_ok=True)
        for name in ('index.md','detail.md'):
            (target/name).write_text((base/old/name).read_text(encoding='utf-8'),encoding='utf-8')
    landing=base/'output/landing/index.md'
    text=landing.read_text(encoding='utf-8'); tail=text[text.index('\n---\n'):]
    # Reuse the corrected concrete case, not the old overview's invented events.
    detail=(base/'output/landing/detail.md').read_text(encoding='utf-8')
    corrected=detail.split('\n---\n',1)[1].split('<!-- source-links:start -->',1)[0]
    landing.write_text('''# 产物落子

最终代码和落点已确定、次数与实际能量处理完成后，创建新棋子并保存，写入目标格，再刷新订单状态。随后通知棋盘和活动；符合资格的活动可能复制物品、累计进度或发奖励。通知完成后记录本次产出，再回到点击收尾检查母体变换、销毁和CD辅助。

这里按“创建→写格与订单刷新→通知及其同步响应→日志→返回收尾”的实际顺序解释。各活动独立判断资格，并非每次点击都会触发全部活动；通知还可同步引出追加落子。

---
'''+corrected,encoding='utf-8')
    append(base/'output/landing/detail.md',body((base/'events/side_effects/detail.md').read_text(encoding='utf-8')))
    append(base/'energy/consume/detail.md',body((base/'events/resource/detail.md').read_text(encoding='utf-8')))
    # No in-article documentation hyperlinks. The left tree is the only way to
    # choose a level; source/download evidence and images remain available.
    for p in base.rglob('*.md'):
        if any(x in p.parts for x in ('events','overrides')):
            continue
        text=p.read_text(encoding='utf-8')
        text=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',lambda m:m[0] if '/assets/' in m[2] or m[2].startswith('http') else m[1],text)
        text=text.replace('跨阶段查阅可使用事件与监听链，其中每条事件均应以实际触发位置理解。','落子通知与活动响应在产物落子步骤解释，资源通知在能量扣除步骤解释。')
        text=text.replace('产出改写与数值边界集中说明它们分别嵌入哪个位置；这个说明页不增加新的点击阶段。','左侧依次列出Disco前置、次数上限检查、候选选择、链升级和产物落子；各页在本步骤内解释修正和结果。')
        p.write_text(text,encoding='utf-8')

if __name__=='__main__':
    site=Path(__file__).resolve().parents[1]/'analysis_output/logic_recovery/stage3/mkdocs_site'
    supplement(site/'docs')
    p=site/'mkdocs.yml'
    p.write_text(wire(p.read_text(encoding='utf-8')),encoding='utf-8')
