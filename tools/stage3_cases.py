"""Page-specific, evidence-labelled walkthroughs and original Unity sprite cache."""
from pathlib import Path
import hashlib
import json
import os

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / 'analysis_output/logic_recovery/stage3/case_assets'
BUNDLE = ROOT / 'analysis_data/logic_index/sources/apk/base/assets/aa/android/board_assets_all_a06cb7eb11e631b6dc558a459bb4a11f.bundle'


def prepare_assets(docs):
    import UnityPy
    from PIL import Image, ImageDraw, ImageFont
    CACHE.mkdir(parents=True, exist_ok=True)
    view = json.loads((ROOT / 'analysis_data/json/ItemViewConfig.json').read_text(encoding='utf-8'))
    models = json.loads((ROOT / 'analysis_data/json/ItemModelConfig.json').read_text(encoding='utf-8'))
    codes = ['104', '105', '201', '202', '204', '205', '303', '304', '305', 'main_t_chest_new_1']
    names = {r['Type']: r['Image'][0] for r in view if r['Type'] in codes}
    env = UnityPy.load(str(BUNDLE))
    records = []
    for code, name in names.items():
        matches = [(k, v) for k, v in env.container.items()
                   if k.endswith('/' + name + '.png') and v.type.name == 'Sprite']
        if len(matches) != 1:
            raise ValueError(f'Ambiguous sprite {code}: {len(matches)}')
        address, obj = matches[0]
        image = obj.read().image.convert('RGBA')
        dest = CACHE / f'item-{code}.png'
        image.save(dest)
        records.append({'code': code, 'image': name, 'address': address,
                        'path_id': obj.path_id, 'bundle': str(BUNDLE.relative_to(ROOT)),
                        'sha256': hashlib.sha256(dest.read_bytes()).hexdigest(),
                        'mapping': 'ItemViewConfig.Image', 'processing': 'UnityPy Sprite extraction'})
    # Lucky is represented by board-level visual assets rather than an item code.
    for lucky_name in ('lucky_item_1', 'lucky_item_2'):
        matches = [(k, v) for k, v in env.container.items()
                   if k.endswith('/' + lucky_name + '.png') and v.type.name == 'Sprite']
        if len(matches) != 1:
            raise ValueError(f'Ambiguous Lucky sprite {lucky_name}: {len(matches)}')
        address, obj = matches[0]
        dest = CACHE / f'{lucky_name}.png'
        obj.read().image.convert('RGBA').save(dest)
        records.append({'code': None, 'image': lucky_name, 'address': address,
                        'path_id': obj.path_id, 'bundle': str(BUNDLE.relative_to(ROOT)),
                        'sha256': hashlib.sha256(dest.read_bytes()).hexdigest(),
                        'mapping': 'Board Lucky visual', 'processing': 'UnityPy Sprite extraction'})
    font = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc', 22)
    small = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc', 17)
    for filename, items, labels in [
        ('generator.png', ['105', '201', '204'], ['母体 105', 'A：普通产出 201', 'B：Lucky 产出 204']),
        ('merge.png', ['201', '201', '202'], ['拖动棋子 201', '目标棋子 201', '合成结果 202']),
        ('order.png', ['201', '201'], ['需求：201 × 1', '消耗：棋盘 201 × 1'])]:
        canvas = Image.new('RGBA', (900, 245), 'white')
        draw = ImageDraw.Draw(canvas)
        for i, (code, label) in enumerate(zip(items, labels)):
            x = 70 + i * 285
            draw.rounded_rectangle((x, 20, x + 205, 193), radius=6, fill='#edf4f2')
            icon = Image.open(CACHE / f'item-{code}.png').convert('RGBA')
            icon.thumbnail((155, 145))
            canvas.alpha_composite(icon, (x + (205-icon.width)//2, 32+(145-icon.height)//2))
            draw.text((x, 202), label, font=font, fill='#253f3c')
        draw.text((660, 5), '原版图标 / 案例组合示意', font=small, fill='#59706c')
        canvas.convert('RGB').save(CACHE / filename)
    manifest = {'bundle_sha256': hashlib.sha256(BUNDLE.read_bytes()).hexdigest(),
                'sprites': records, 'compositions': 'Original sprites on explanatory backgrounds; not runtime screenshots',
                'generator_config': next(r for r in models if r['Type'] == '105')}
    (CACHE / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    import shutil
    shutil.copytree(CACHE, docs / 'assets/cases', dirs_exist_ok=True)


# Each entry describes this page's actual place in one shared scenario.
STEPS = {
 'index.md': ('玩家希望继续制作订单所需食物。点击食品袋后，先确认可操作、有落点、付得起能量；再决定普通或 Lucky 产出，保存母体次数，扣能量并落子。', ''),
 'state/index.md': ('按源码顺序先排除关闭、开启中，再排除初始化或次数为零。本例均通过，进入空位检查。', ''),
 'state/closed.md': ('本例没有开启计时配置，不处于关闭状态。此关放行。', '`m_state=3 (Opened)`，与 `Closed=1` 不相等；不发送 `ItemClosed`。'),
 'state/opening.md': ('本例没有正在开启的计时器，此关放行。', '`m_state=3`，与 `Opening=2` 不相等；不发送 `ItemOpening`。'),
 'state/initializing.md': ('本例已可产出且次数充足，既不在初始化，也没有耗尽。', '`m_state=3`；`m_itemRestNumber=80`。`state==Initializing or rest==0` 为 false。反事实：把次数改为 0 时，即使仍是 Opened，也会阻止产出。'),
 'state/opened.md': ('前面所有阻断条件都没有发生，允许继续找空位。', '`CheckSpreadState()` 返回 true；这里不是另一次随机抽样。'),
 'position/index.md': ('本例为手动母体，检查落点后进入能量检查。棋盘满时在此结束。', ''),
 'position/recoverable.md': ('食品袋是可恢复母体，演示棋盘已提供有效空格 P。点击入口找到 P 后继续。', '演示输入：落点搜索返回 `P`。`CheckSpreadPosAndAuto` 实际调用 `FindEmptyPositionInSpreadOrder`；P 是搜索结果符号，不冒充未核对的坐标或扫描序列。'),
 'position/disposable.md': ('本页使用一次性测试宝箱 `main_t_chest_new_1` 作为独立案例。它没有 `Spread_ItemRecoveryDuration`，因此 `IsDisposable()` 为 true；手动点击仍先按母体周围的方形环找空位，自动路径才会使用全盘随机空位。', '`Spread_OpenDuration=120`、`Spread_ItemMaxNumber=7`、`Spread_StorageMaxNumber=7`、`Spread_WeightType=2`、权重 `2401-2/2402-2/2501-2/2502-1`；未配置物品恢复时长。'),
 'position/disposable_detail.md': ('本页继续使用一次性测试宝箱 `main_t_chest_new_1`，把同一输入代入方形环扫描、自动随机和缓存分支的底层算法。', '`Spread_OpenDuration=120`、`Spread_ItemMaxNumber=7`、`Spread_StorageMaxNumber=7`、`Spread_WeightType=2`；当前手动案例指定母体周围存在首个合法空位，自动案例单独讨论当前空位集合。'),
 'position/auto.md': ('食品袋不会自行吐出物品，本次来自玩家手动点击。', '`Spread_Auto=0`；自动缓存分支未执行。'),
 'position/full.md': ('本次存在 P，棋盘满失败没有发生。', '本例 `position=P`。对照输入 `position=nil` 时返回 false，发送 `BoardFull`；能量仍为 10，次数仍为 80。'),
 'energy/index.md': ('本例使用基础能量档，余额足够。此处先检查余额，实际扣除稍后执行。', ''),
 'energy/cost.md': ('食品袋需要能量；本例没有免能量活动。', '`Spread_CostEnergy=1`；Disco 不生效；`costEnergy=true`。'),
 'energy/boost.md': ('本例不用能量倍增，物品等级不会因为倍增提升。', '演示输入 `maxEnergyBoostRatio=0`；基础扣能量 1。'),
 'energy/consume.md': ('余额 10 足够一次点击。母体先算出产物，随后扣到 9。', '余额检查：`10>=1`。`SpreadCostEnergy(0,true)` 调用 `Consume`；`m_testLastCostEnergyCount=1`。对照余额 0：在生成产物前返回 false。'),
 'lucky/index.md': ('本例有适用的 Lucky 配置。先检查活动、等级和已有连续资格，再抽周期机会；失败才检查免费资格。A 未命中回普通池，B 命中再抽 Lucky 物品。', ''),
 'lucky/chance/index.md': ('A 抽到普通机会，B 抽到本周期的一次 Lucky。两者都会消耗本次普通机会。', ''),
 'lucky/chance/load.md': ('读取食品袋自己的周期计数。本例周期刚装满，不需要重新装填。', '`sourceItemType="105"`；`tl_105=60`、`ll_105=1`。若 `tl_105=0`，本地配置 `lucky_chance={60,1}` 重装为 60/1。'),
 'lucky/chance/roll.md': ('A 是普通产出；B 获得 Lucky 资格。', 'A 演示整数 `index=60`，比较 `1>=60` 为 false；B 改为 `index=1`，`1>=1` 为 true。随机区间 `[1,60]`；演示关闭测试强制开关。'),
 'lucky/chance/commit.md': ('A 留住本周期 Lucky 配额；B 用掉它。下一点击概率随剩余计数变化。', 'A（免费未命中）：`tl_105:60→59`，`ll_105:1→1`，下一次概率 1/59。B：`tl_105:60→59`，`ll_105:1→0`，本周期后续普通机会不会再命中。'),
 'lucky/items/index.md': ('A 不执行 Lucky 物品抽取；B 从高阶产物中选择，拿到 204。', ''),
 'lucky/items/select.md': ('B 的 Lucky 奖励是高阶面粉物品 204；候选不会移除。', '本地池 `204:63,205:10,303:15,304:10,305:2`，总权重 100。演示累计抽样点 50 落在第一项区间，选择 204。下次仍保留完整池；不是机会池的无放回语义。'),
 'lucky/items/smart.md': ('本例关闭 Smart 修正，直接用原始 Lucky 权重。', '演示 `m_smartProduceRatio=nil`；`_UseSmartProduce()` 为 false；使用 `Weight`，不读 `Weight_Smart`。启用时还需订单缺口和修正倍率，不能由本例推断实际账号值。'),
 'lucky/items/type.md': ('204 属于普通 Lucky 奖励，不是 Super，也不是免费奖励。', '`super_items={205,304,305}` 不含 204；`isFree=false`，类型为 `BoardSpreadType.Lucky`。'),
 'lucky/free/index.md': ('A 普通机会失败后才检查免费资格；本例没有达到免费阈值。B 已命中普通机会，跳过免费判断。', ''),
 'lucky/free/generate.md': ('本例沿用已存在的阈值状态；本次资格判断不重新生成阈值队列。', '演示 `_CanFreeLuckyProduce()` 为 false；没有采集本例账号的 `energy_cost`/`extra_lucky` 生效值，故不编造 `elpec` 阈值数字。阈值生成需单独记录 PropertyConsumed 回调及能量区间。'),
 'lucky/free/consume.md': ('A 免费资格也失败，所以普通产出；B 不走该路径。', 'A 演示 `_CanFreeLuckyProduce()=false`：不调用免费消费后处理。若改为 true，则消费队首，`tl_105` 保持 60，进入 Free Lucky 物品抽取。这是对照分支，非 A 的实际演示路径。'),
 'lucky/continuous/index.md': ('本例开始时没有连续资格。B 命中后尝试建立后续连续资格；A 不执行该尝试。', ''),
 'lucky/continuous/trigger.md': ('本例使用基础配置，没有断言本次触发二连或三连。', '基础 105 行确认的是 `lucky_chance` 和物品池；没有能量区间的实际配置快照，不能填写二连/三连概率。B 调用 `_Try2TriggerContiLuckyProduce("105")`，是否写入连续状态取决于实际配置。'),
 'lucky/continuous/state.md': ('本例没有设定连续命中。以下只说明一旦二连/三连触发会保存什么。', '对照输入：服务器时间 T=1000，触发函数最大次数参数 N；写入 `clpit="105"`、`clpmc=N`、`clpc=0`、`clpeet=1010`。T 是演示输入，N 必须由实际触发调用确定。'),
 'lucky/continuous/consume.md': ('开始时没有连续状态，所以本例继续周期抽样。', '对照状态：`clpit="105",clpmc=2,clpc=0,clpeet=1010` 且 `serverTime=1005` 时资格有效；消费后 `clpc=1`、期限 1015。时间或母体不匹配时清除；此对照不是主案例已发生的事实。'),
 'output/index.md': ('A 没有 Lucky 资格，按食品袋的 Fixed 配置产出；B 已走 Lucky，跳过普通分派。', ''),
 'output/fixed.md': ('A 选中低阶面粉 201，同样的低阶物品可以连续出现。', '`Spread_WeightType=1`；候选 `201:35,202:2,301:5`，总权重 42。演示累计抽样点 20 落在首项；原始池不删除候选，下次仍是 35/42、2/42、5/42。'),
 'output/decremental.md': ('本例 Fixed，不执行递减池逻辑。', '`m_weightType=1`，与 `Decremental=2` 不相等；本次没有递减候选权重。'),
 'output/order.md': ('本例不根据订单生成候选，不执行订单产出算法。', '`m_weightType=1`，与 `OrderItem=3` 不相等；订单难度分值不参与本次 Fixed 原始池抽样。'),
 'output/chest.md': ('食品袋不是定制订单宝箱。', '`m_weightType=1`，与 `ChestCustomItem=4` 不相等；不调用本分支生成规则。'),
 'output/smart.md': ('本例不是 SmartItem 母体。', '`m_weightType=1`，与 `SmartItem=5` 不相等。本分派与 Lucky 的 Smart 权重修正是两个不同入口。'),
 'lifecycle/index.md': ('成功选出物品后保存次数并启动恢复；能量和棋盘随后结算。', ''),
 'lifecycle/count.md': ('A 普通点击消耗一个可用次数；食品袋仍留在棋盘。', 'A 初始 `m_spreadCount=0,m_itemRestNumber=80`，普通基础档扣次后为 1/79。`Spread_TransformNumber` 未配置且母体可恢复，不因这一点击销毁。储备 240 不在这里立即减 1。'),
 'lifecycle/cooldown.md': ('食品袋启动短恢复，补回本次缺少的次数，并从储备里支付。', 'A 演示 `serverTime=T`、`m_startTimer=nil`：扣次至 79 后 UpdatePerSecond 写 `m_startTimer=T`。配置 105 的物品恢复 30 秒、储备恢复 60 秒；物品恢复时 79→80，储备 240→239。实际 tick 时间需回放。'),
 'events.md': ('先保存母体状态，再扣能量和落子，随后触发反馈及后续活动处理。', 'A：次数状态 0/80→1/79，能量 10→9，P 写入 201；`VibrationLight` 在 SpreadItem 后发出。ItemLandOpt 演示关闭，P 不二次替换。PropertyConsumed 的所有监听器仍需按调用链逐项分析；本例不等于事件覆盖验收。'),
}


def render_case(path):
    prefix = 'operations/generator/'
    # MkDocs emits directory-style URLs (``page/index.html``), which add one
    # URL segment beyond the Markdown parent directory.
    depth = len(Path(path).parent.parts) + 1
    asset = '../' * depth + 'assets/cases/'
    if path.startswith(prefix):
        key = path[len(prefix):]
        # Branch index/detail pages are generated under a directory so the
        # section label itself opens the mechanism page. Reuse the same case
        # facts as the legacy source names while calculating fresh asset paths.
        branch_aliases = {
            'state/initializing/index.md': 'state/initializing.md',
            'state/initializing/detail.md': 'state/initializing_detail.md',
            'state/closed/index.md': 'state/closed.md',
            'state/closed/detail.md': 'state/closed_detail.md',
            'state/opening/index.md': 'state/opening.md',
            'state/opening/detail.md': 'state/opening_detail.md',
            'state/opened/index.md': 'state/opened.md',
            'state/opened/detail.md': 'state/opened_detail.md',
            'position/disposable/index.md': 'position/disposable.md',
            'position/disposable/detail.md': 'position/disposable_detail.md',
            'position/recoverable/index.md': 'position/recoverable.md',
            'position/recoverable/detail.md': 'position/recoverable_detail.md',
            'position/auto/index.md': 'position/auto.md',
            'position/auto/detail.md': 'position/auto_detail.md',
            'position/full/index.md': 'position/full.md',
            'position/full/detail.md': 'position/full_detail.md',
            'energy/cost/index.md': 'energy/cost.md',
            'energy/cost/detail.md': 'energy/cost_detail.md',
            'energy/boost/index.md': 'energy/boost.md',
            'energy/boost/detail.md': 'energy/boost_detail.md',
            'energy/consume/index.md': 'energy/consume.md',
            'energy/consume/detail.md': 'energy/consume_detail.md',
            'output/fixed/index.md': 'output/fixed.md',
            'output/fixed/detail.md': 'output/fixed_detail.md',
            'output/decremental/index.md': 'output/decremental.md',
            'output/decremental/detail.md': 'output/decremental_detail.md',
            'output/order/index.md': 'output/order.md',
            'output/order/detail.md': 'output/order_detail.md',
            'output/chest/index.md': 'output/chest.md',
            'output/chest/detail.md': 'output/chest_detail.md',
            'output/smart/index.md': 'output/smart.md',
            'output/smart/detail.md': 'output/smart_detail.md',
            'lifecycle/count/index.md': 'lifecycle/count.md',
            'lifecycle/count/detail.md': 'lifecycle/count_detail.md',
            'lifecycle/cooldown/index.md': 'lifecycle/cooldown.md',
            'lifecycle/cooldown/detail.md': 'lifecycle/cooldown_detail.md',
            'events/resource/index.md': 'events/resource.md',
            'events/resource/detail.md': 'events/resource_detail.md',
            'events/board/index.md': 'events/board.md',
            'events/board/detail.md': 'events/board_detail.md',
            'events/side_effects/index.md': 'events/side_effects.md',
            'events/side_effects/detail.md': 'events/side_effects_detail.md',
        }
        source_key = branch_aliases.get(key, key)
        if key in STEPS:
            summary, details = STEPS[key]
        elif source_key in STEPS:
            summary, details = STEPS[source_key]
        else:
            summary = '本页是该阶段的第四层证据节点；沿用食品袋 105 的同一组案例输入，只展示当前节点涉及的算法和状态变化。'
            details = '本页没有新增运行时输入；具体字段以本页正文的源码和配表为准。'
        key = source_key
        # Images are deliberately selected by the mechanism explained on the page.
        # The composite is useful only for the generator overview; detail nodes use
        # one small icon or remain text-only when an icon would add no information.
        if key == 'index.md':
            images = [('generator.png', '母体点击的产出分支', 'composite')]
        elif key.startswith('position/disposable'):
            images = [('item-main_t_chest_new_1.png', '一次性测试宝箱 main_t_chest_new_1', 'icon')]
        elif key.startswith('state/') or key.startswith('lifecycle/'):
            images = [('item-105.png', '食品袋 105', 'icon')]
        elif key.startswith('lucky/chance/'):
            images = [('lucky_item_1.png', 'Lucky 标记', 'icon')]
        elif key.startswith('lucky/items/'):
            images = [('item-204.png', 'Lucky 产物 204', 'icon')]
        elif key.startswith('lucky/free/') or key.startswith('lucky/continuous/'):
            images = [('lucky_item_1.png', 'Lucky 标记', 'icon')]
        elif key == 'lucky/index.md':
            images = [('lucky_item_1.png', 'Lucky 标记', 'icon'), ('item-204.png', 'Lucky 产物 204', 'icon')]
        elif key.startswith('output/fixed'):
            images = [('item-201.png', '普通产物 201', 'icon')]
        else:
            images = []
        if images:
            rendered = []
            for filename, alt, kind in images:
                if kind == 'composite':
                    rendered.append(f'<img src="{asset}{filename}" alt="{alt}" class="case-composite" style="display:block;max-width:560px;width:100%;height:auto;">')
                else:
                    rendered.append(f'<img src="{asset}{filename}" alt="{alt}" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;">')
            image_block = '\n<div class="case-assets">' + ''.join(rendered) + '</div>\n'
        else:
            image_block = ''
        is_disposable_case = key in ('position/disposable.md', 'position/disposable_detail.md')
        case_title = '打开一次性测试宝箱 main_t_chest_new_1' if is_disposable_case else '点击食品袋 105'
        purpose = ('观察一次性母体在开启、落点、Decremental 权重和耗尽销毁之间的完整链路。'
                   if is_disposable_case else
                   '制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。')
        block = f'\n\n---\n\n## 贯穿案例：{case_title}\n{image_block}\n'
        block += f'**目的**：{purpose}\n\n'
        block += '**本页发生什么**：' + summary + '\n\n'
        if details:
            block += '### 代入本页的值\n\n' + details + '\n\n'
        if key == 'index.md':
            block += 'A 产出 201（低阶面粉），B 产出 204（高阶面粉）；两个分支分别从同一初始状态演示，不能当作连续两次点击。母体 104 是低级对照：基础 Lucky 配置没有包含它。\n\n'
        block += '<details><summary>本案例共同前提</summary>\n\n'
        if is_disposable_case:
            block += '本地配表确认：`main_t_chest_new_1` 的开启时长 120 秒、可产出 7 次、储备 7 次，`Spread_WeightType=2`，权重为 `2401-2 / 2402-2 / 2501-2 / 2502-1`；没有 `Spread_ItemRecoveryDuration`，因此是一次性母体。素材为原版 Sprite 图标加说明性排布，不是运行时截图。\n\n'
        else:
            block += '本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。\n\n'
        block += '演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。\n\n'
        block += '本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。\n\n</details>\n'
        return block
    if path.startswith('operations/merge/'):
        body = '拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。'
        image = 'merge.png'
        title = '两个 201 合成 202'
    elif path.startswith('operations/orders/'):
        body = '讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。'
        image = 'order.png'
        title = '提交单需求订单'
    else:
        return ''
    # Keep composite visuals on operation overviews. Child pages get only the
    # icon(s) they discuss, so the image carries information instead of repetition.
    if path.startswith('operations/merge/'):
        merge_key = path[len('operations/merge/'):]
        if merge_key == 'index.md':
            visual = f'<img src="{asset}merge.png" alt="{title}" class="case-composite" style="display:block;max-width:560px;width:100%;height:auto;">'
        elif merge_key == 'normal.md':
            visual = (f'<img src="{asset}item-201.png" alt="输入棋子 201" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin-right:12px;">'
                      f'<img src="{asset}item-202.png" alt="合成结果 202" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin-right:12px;">')
        elif merge_key == 'dispatch.md':
            visual = f'<img src="{asset}item-201.png" alt="棋子 201" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin-right:12px;">'
        else:
            visual = ''
    else:
        order_key = path[len('operations/orders/'):]
        if order_key == 'index.md':
            visual = f'<img src="{asset}order.png" alt="{title}" class="case-composite" style="display:block;max-width:560px;width:100%;height:auto;">'
        elif order_key in ('check.md', 'remove.md'):
            visual = f'<img src="{asset}item-201.png" alt="棋子 201" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin-right:12px;">'
        else:
            visual = ''
    image_block = f'<div class="case-assets">{visual}</div>\n' if visual else ''
    return f'\n\n---\n\n## 贯穿案例：{title}\n\n{image_block}\n{body}\n'
