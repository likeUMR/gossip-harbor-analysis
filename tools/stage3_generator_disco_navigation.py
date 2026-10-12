"""Expose Disco at its actual place in the four-level operation tree."""
from pathlib import Path

def wire_disco(config):
    if 'Disco：前置产出与普通回退:' in config:
        return config
    anchor='          - Fixed:\n'
    if anchor not in config:
        raise ValueError('Ordinary-output branch not found')
    branch='''          - Disco：前置产出与普通回退:
              - operations/generator/overrides/activity/index.md
              - 订单选择、助力扣分与降级算法: operations/generator/overrides/activity/detail.md
'''
    return config.replace(anchor,branch+anchor,1)

def supplement(docs):
    p=docs/'operations/generator/output/index.md'
    text=p.read_text(encoding='utf-8')
    text=text.replace('[活动前置分支](../overrides/activity/index.md)', '[Disco 前置产出](../overrides/activity/index.md)')
    text=text.replace('[活动后置改写](../overrides/activity/detail.md)', '[Disco 普通回退后的降级与扣分](../overrides/activity/detail.md)')
    marker='<!-- disco-tree:start -->'
    if marker not in text:
        text=text.replace('分支页面：', '''<!-- disco-tree:start -->
## Disco 与五种普通候选如何衔接

左侧的[Disco 专门说明](../overrides/activity/index.md)对应上述第1步和第5步。它先尝试直接补订单，有合适目标便返回；没有目标才继续五种普通候选选择，随后可能再次降级改写。Disco有专用助力余额，既不是第六种Spread_WeightType，也不是所有普通点击都必经的生效分支。

直接路径不消费普通池或母体次数；普通回退路径仍会消费对应候选池，但把母体次数消耗改成0、点击累计仍加1。两条路径都按Disco助力规则结算，详见[底层算法](../overrides/activity/detail.md)。
<!-- disco-tree:end -->

五种原始候选选择：''',1)
    p.write_text(text,encoding='utf-8')

if __name__=='__main__':
    site=Path(__file__).resolve().parents[1]/'analysis_output/logic_recovery/stage3/mkdocs_site'
    supplement(site/'docs')
    p=site/'mkdocs.yml'
    p.write_text(wire_disco(p.read_text(encoding='utf-8')),encoding='utf-8')
