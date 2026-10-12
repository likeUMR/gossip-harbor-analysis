"""Embed complete, page-scoped configuration records into existing generator pages."""
from __future__ import annotations

import html
import json
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON = ROOT / 'analysis_data/json'
START = '<!-- generator-configs:start -->'
END = '<!-- generator-configs:end -->'
LABELS = {
    'Type': '母体/棋子 ID', 'Code': '产物 ID', 'generator': '适用母体',
    'level_min': '玩家等级下限', 'level_max': '玩家等级上限', 'lucky_chance': '总机会 / Lucky 配额',
    'lucky_items': 'Lucky 产物 × 权重', 'super_items': 'Super Lucky 产物',
    'Spread_Auto': '自动产出', 'Spread_CostEnergy': '是否消耗能量', 'Spread_WeightType': '产出模式',
    'Spread_Weight': '普通产物 × 权重', 'Spread_InitDuration': '初始化时长（秒）',
    'Spread_OpenDuration': '开启时长（秒）', 'Spread_ItemMaxNumber': '单轮次数上限',
    'Spread_ItemRecoveryDuration': '单轮恢复（秒）', 'Spread_StorageMaxNumber': '储备次数上限',
    'Spread_StorageRecoveryDuration': '储备恢复（秒）', 'Spread_InitSpeedUpCost': '初始化加速（宝石）',
    'Spread_OpenSpeedUpCost': '开启加速（宝石）', 'Spread_ItemSpeedUpCost': '单轮加速（宝石）',
    'Spread_StorageSpeedUpCost': '储备加速（宝石）', 'Spread_TransformNumber': '变换点击次数',
    'Transform_Weight': '变换目标 × 权重', 'MergedType': '合成下一等级',
    'DiffScore': '产物难度分', 'UnlockLevel': '解锁等级', 'Weight': '订单权重',
}

# Each family has one bottom-level home, chosen from the recovered read chain.
OWNERS = {
    'item': ('state/model/detail.md', 'configuration-item-model', '母体配置与包内变体',
             'ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。'),
    'lucky': ('lucky/chance/load.md', 'configuration-lucky', 'Lucky 包内配置及活动变体',
              'LuckyProduceModel:_LoadFileConfig → _GetLevelFitConfig → Try2ProduceLuckyItem；按 generator、等级区间选择记录，再用 lucky_chance 重装机会池。'),
    'activity': ('overrides/activity/detail.md', 'configuration-generator-boost', 'Generator Boost 母体替换配置',
                 'GeneratorBoostActivityModel:GetItemModelConfig → ReloadItemModelConfig；按 Buff 选择 MoreLuckyProduce / ExtraProduce 并替换 ItemDataModel 中的母体配置。'),
    'energy': ('energy/boost/detail.md', 'configuration-energy-boost', '能量增益适用母体',
               'EnergyBoostModel:OnSyncDataFinished 直接 require EnergyBoostItemConfig，建立 m_mapTargetItemType；CanEnergyBoost 读取此适用集合。'),
    'order': ('output/order/detail.md', 'configuration-order-item', '产物难度分与解锁配置',
              'ItemSpread:GetOrderItemCode 读取 Slot:GetItemCodeConfigMap()[code].DiffScore；ChestCustomItem 与 SmartItem 复用同一个代码配置映射。'),
    'free': ('lucky/free/generate.md', 'configuration-free-lucky', '免费 Lucky 服务器字段',
             'LuckyProduceModel:_LoadOtherServerConfig 载入 luckyProduceConfig；_AddFreeLuckyProduceEnergyCostCount 读取 energy_cost.range_entry 与 extra_lucky。'),
    'continuous': ('lucky/continuous/trigger.md', 'configuration-continuous-lucky', '连续 Lucky 服务器字段',
                   '_CalculateLuckyProduceConfigIndex 按 energy_cost.range_entry 选段；_Try2TriggerContiLuckyProduce 直接读取 triple_lucky_chance / double_lucky_chance。'),
    'smart': ('lucky/items/smart.md', 'configuration-lucky-smart', 'Lucky Smart Produce 参数',
              '_LoadOtherServerConfig 用 MiscConfigReader:GetInteger(MiscConfKey.LuckyProduceSmart) 载入倍率；_UpdateSpreadConfigSmartWeight 使用原始物品池计算临时权重。'),
    'energy_cost': ('lifecycle/count/detail.md', 'configuration-energy-cost', '能量增益次数扣除配置',
                    'EnergyBoostModel:LoadServerConfig 读取 EnergyBoostCost.boost_num / cost；ItemSpread:CosetRestNumber → NextEnergyBoostCostIndex 消费循环次数序列。'),
    'fish': ('overrides/boost/detail.md', 'configuration-fish-smart', '生鱼链智能升级开关',
             'ItemSpread:SpreadCheckEnergyRatioAndCode 读取服务器通用开关 FishNetProduceSmart，再沿 ItemDataModel 的合成链计算升级。'),
}

# Human-readable source names shown wherever a non-owner page points to the
# canonical table.  This keeps the lookup list concrete without duplicating
# the full records on the orchestration page.
CONFIG_FILES = {
    'item': 'ItemModelConfig.json；ItemModelConfig_shell/carditem2/extracust',
    'lucky': 'LuckyProduceConfig、LuckyProduceConfig_shell/triple/tripleshell',
    'activity': 'GeneratorBoostItemModelConfig、GeneratorBoostItemModelConfig_shell',
    'energy': 'EnergyBoostItemConfig；服务器 EnergyBoostEight',
    'order': 'OrderItemConfig.json；OrderItemConfig_shell/hard/nerf/nerf_more/extracust',
    'free': '服务器 luckyProduceConfig（energy_cost.range_entry、extra_lucky）',
    'continuous': '服务器 luckyProduceConfig（energy_cost.range_entry、triple_lucky_chance、double_lucky_chance）',
    'smart': '服务器 MiscConfig（LuckyProduceSmart）及运行时 Smart 权重',
    'energy_cost': '服务器 EnergyBoostCost（boost_num、cost）',
    'fish': '服务器 FishNetProduceSmart',
}

# These pages consume an already-loaded family. A link is sufficient; no full copy.
REFERENCES = {
    # The Lucky root page orchestrates all of these readers.  Keep the full
    # tables on their leaf owners, but make every concrete source discoverable
    # from the root logic page.
    'lucky/index.md': ['item', 'lucky', 'activity', 'free', 'continuous', 'smart'],
    'state/initializing/detail.md': ['item'], 'state/closed/detail.md': ['item'],
    'state/opening/detail.md': ['item'], 'state/opened/detail.md': ['item'],
    'state/timing/detail.md': ['item'], 'position/auto/detail.md': ['item'],
    'position/disposable/detail.md': ['item'], 'position/recoverable/detail.md': ['item'],
    'energy/cost/detail.md': ['item', 'activity'], 'energy/boost/detail.md': ['item'],
    'energy/consume/detail.md': ['item', 'energy'],
    'lucky/chance/roll.md': ['lucky'], 'lucky/chance/commit.md': ['lucky'],
    'lucky/items/select.md': ['lucky'], 'lucky/items/smart.md': ['lucky'],
    'lucky/items/type.md': ['lucky'], 'lucky/free/consume.md': ['free'],
    'lucky/continuous/state.md': ['continuous'], 'lucky/continuous/consume.md': ['continuous'],
    'output/fixed/detail.md': ['item', 'activity'], 'output/decremental/detail.md': ['item'],
    'output/order/detail.md': ['item'], 'output/chest/detail.md': ['order', 'item'],
    'output/smart/detail.md': ['order', 'item'],
    'lifecycle/count/detail.md': ['item', 'order'], 'lifecycle/cooldown/detail.md': ['item'],
    'overrides/activity/detail.md': ['lucky'], 'overrides/boost/detail.md': ['item', 'energy'],
    'overrides/safety/detail.md': ['item'],
}


def load(name):
    return json.loads((JSON / (name + '.json')).read_text(encoding='utf-8'))


def literal_configs():
    from gh_lua import Chunk
    from lupa.lua53 import LuaRuntime, lua_type
    lua = LuaRuntime(encoding=None)
    # ItemType identifiers are defined by the original view-to-code mapping.
    symbols = {}
    for row in load('ItemViewConfig'):
        for name in row.get('Image', []):
            symbols.setdefault(name.encode(), row['Type'].encode())
    lua.globals()[b'ItemType'] = lua.table_from(symbols)

    def convert(value):
        if isinstance(value, bytes):
            return value.decode('utf-8')
        if lua_type(value) == 'table':
            result = {convert(k): convert(v) for k, v in value.items()}
            if set(result) == set(range(1, len(result) + 1)):
                return [result[i] for i in range(1, len(result) + 1)]
            return result
        return value

    names = ['LuckyProduceConfig', 'LuckyProduceConfig_shell',
             'LuckyProduceConfig_triple', 'LuckyProduceConfig_tripleshell',
             'GeneratorBoostLuckyProduceConfig', 'GeneratorBoostLuckyProduceConfig_shell',
             'GeneratorBoostItemModelConfig', 'GeneratorBoostItemModelConfig_shell',
             'EnergyBoostItemConfig', 'ItemModelConfig_shell', 'ItemModelConfig_carditem2',
             'ItemModelConfig_extracust', 'OrderItemConfig_shell', 'OrderItemConfig_hard',
             'OrderItemConfig_nerf', 'OrderItemConfig_nerf_more', 'OrderItemConfig_extracust']
    return {name: convert(lua.execute(Chunk((ROOT / 'analysis_data/lua_modules/Data/Config' /
                                           (name + '.luac')).read_bytes()).standard()))
            for name in names}


CSS = '''
.config-block{margin:1.5rem 0;border:1px solid #d9e0e8;border-radius:8px;padding:14px;min-width:0}
.config-controls{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin:10px 0}
.config-controls input{border:1px solid #95a6b7;border-radius:5px;padding:8px;width:min(100%,360px);background:transparent;color:inherit}
.config-scroll{overflow:auto;max-height:650px;border:1px solid #d9e0e8}
.md-typeset .config-table{font-size:13px;border-collapse:collapse;width:100%;margin:0}
.config-table th,.config-table td{padding:9px;border-bottom:1px solid #d9e0e8;vertical-align:top;min-width:90px}
.config-table th{position:sticky;top:0;background:var(--md-default-bg-color);z-index:1;white-space:nowrap}
.config-piece{display:inline-flex;gap:6px;align-items:center;margin:3px;min-width:90px}
.config-piece img{width:38px;height:38px;object-fit:contain}
.config-piece small{display:block;color:var(--md-default-fg-color--light);font-size:10px}
.config-table pre{white-space:pre-wrap;word-break:break-word;max-width:680px;font-size:12px}
.config-table details{min-width:150px}.config-pool{min-width:230px}
'''
JS = '''
function bindConfigTables(){document.querySelectorAll('.config-block').forEach(function(block){
 const input=block.querySelector('input');if(!input||input.dataset.bound)return;input.dataset.bound='1';
 const rows=Array.from(block.querySelectorAll('tbody tr'));const count=block.querySelector('.config-count');
 function filter(){const q=input.value.trim().toLowerCase();let visible=0;rows.forEach(function(row){
 row.hidden=!row.textContent.toLowerCase().includes(q);if(!row.hidden)visible++;});
 count.textContent='显示 '+visible+' / '+rows.length+' 条配置';}input.addEventListener('input',filter);filter();});}
if(typeof document$!=='undefined'){document$.subscribe(bindConfigTables);}else{bindConfigTables();}
'''


class Renderer:
    def __init__(self, docs):
        self.docs = docs
        self.models = load('ItemModelConfig')
        self.spread = [r for r in self.models if any(k.startswith('Spread_') for k in r)]
        self.by_code = {r['Type']: r for r in self.models}
        self.views = {r['Type']: r.get('Image', [''])[0] for r in load('ItemViewConfig')}
        self.configs = literal_configs()
        self.icons = set()
        self.names = {}
        self.asset_prefix = ''
        # Only use readable localization; preserve the exact view identifier otherwise.
        from build_pricing_analysis import TEXT_BUNDLE, text_asset_bytes
        translations = json.loads(text_asset_bytes(TEXT_BUNDLE, 'game_text_cn').decode('utf-8'))
        for code in self.by_code:
            for key in ('item_' + code + '_name',):
                if key in translations and isinstance(translations[key], str) and '\ufffd' not in translations[key]:
                    self.names[code] = translations[key]
        self.extract_icons()

    def extract_icons(self):
        import UnityPy
        from stage3_cases import BUNDLE
        dest = self.docs / 'assets/config-pieces'
        dest.mkdir(parents=True, exist_ok=True)
        env = UnityPy.load(str(BUNDLE))
        sprites = {}
        for address, obj in env.container.items():
            if obj.type.name == 'Sprite':
                sprites.setdefault(Path(address).stem.lower(), []).append((address, obj))
        manifest = []
        for code, name in self.views.items():
            matches = sprites.get(name.lower(), [])
            if len(matches) != 1:
                continue
            address, obj = matches[0]
            target = dest / (code + '.png')
            if not target.exists():
                image = obj.read().image.convert('RGBA')
                image.thumbnail((80, 80))
                image.save(target)
            self.icons.add(code)
            manifest.append({'code': code, 'Image': name, 'address': address, 'path_id': obj.path_id})
        (dest / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')

    def piece(self, code):
        code = str(code)
        image = (f'<img loading="lazy" src="{self.asset_prefix}/{html.escape(code)}.png" alt="{html.escape(code)}">'
                 if code in self.icons else '')
        name = self.names.get(code, self.views.get(code, '无本地视图映射'))
        return f'<span class="config-piece">{image}<span><b>{html.escape(code)}</b><small>{html.escape(name)}</small></span></span>'

    def value(self, value, field=''):
        if value is None:
            return '<span title="原始配置中不存在该字段">未配置</span>'
        if field in ('Type', 'Code', 'MergedType', 'TransformType'):
            return self.piece(value)
        if field in ('generator', 'super_items'):
            return ''.join(self.piece(code) for code in value) or '空列表'
        if field in ('Spread_Weight', 'lucky_items', 'Transform_Weight'):
            pool = []
            for pair in value:
                code, weight = pair.rsplit('-', 1)
                pool.append(self.piece(code) + ' × ' + html.escape(weight))
            return '<div class="config-pool">' + '<br>'.join(pool) + '</div>'
        if isinstance(value, (dict, list)):
            return '<code>' + html.escape(json.dumps(value, ensure_ascii=False)) + '</code>'
        return html.escape(str(value))

    def table(self, title, rows, fields, source, note=''):
        columns = ['Type' if any('Type' in r for r in rows) else 'Code'] if rows and any('Type' in r or 'Code' in r for r in rows) else []
        columns += [k for k in fields if k not in columns]
        headers = ''.join('<th>' + html.escape(LABELS.get(k, k)) +
                          ('<small style="display:block">' + html.escape(k) + '</small>' if k in LABELS else '') +
                          '</th>' for k in columns) + '<th>完整记录</th>'
        body = []
        for row in rows:
            cells = ''.join('<td>' + self.value(row.get(k), k) + '</td>' for k in columns)
            raw = html.escape(json.dumps(row, ensure_ascii=False, indent=2))
            body.append('<tr>' + cells + '<td><details><summary>展开全部字段</summary><pre>' + raw + '</pre></details></td></tr>')
        return ('\n\n### ' + title + f'（{len(rows)} 条）\n\n来源：`{source}`。' + note + '\n\n'
                '<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">'
                f'全部 {len(rows)} 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr>'
                + headers + '</tr></thead><tbody>' + ''.join(body) + '</tbody></table></div></div>\n')

    def item_table(self, rows, fields, title='本页相关母体配置'):
        result = self.table(title, rows, fields, 'analysis_data/json/ItemModelConfig.json',
                          '时长单位为秒；“未配置”不等于 0。完整记录保留本页相关母体的全部原始字段。')
        codes = {r['Type'] for r in rows}
        for name in ('ItemModelConfig_shell', 'ItemModelConfig_carditem2', 'ItemModelConfig_extracust'):
            related = [r for r in self.configs[name] if r['Type'] in codes]
            changed = [r for r in related if r != self.by_code.get(r['Type'])]
            result += f'\n\n`{name}`：本页涉及 {len(related)} 条；与默认表不同 {len(changed)} 条。相同记录的完整值见上表；不同记录完整列于下表，变体由配置选择决定。\n'
            if changed:
                result += self.table(name + ' 的不同记录', changed, fields, 'Data.Config.' + name)
        return result

    def order_tables(self):
        fields = ['DiffScore', 'UnlockLevel', 'Weight']
        base = load('OrderItemConfig')
        result = self.table('产物评分与解锁配置', base, fields, 'analysis_data/json/OrderItemConfig.json',
                            '列出全部可配置候选；本次候选仍受订单缺口、库存和解锁条件筛选。')
        base_map = {r['Code']: r for r in base}
        for name in ('OrderItemConfig_shell', 'OrderItemConfig_hard', 'OrderItemConfig_nerf',
                     'OrderItemConfig_nerf_more', 'OrderItemConfig_extracust'):
            variant = self.configs[name]
            changed = [r for r in variant if r != base_map.get(r['Code'])]
            removed = sorted(set(base_map) - {r['Code'] for r in variant})
            result += f'\n\n`{name}`：共 {len(variant)} 条，新增/不同记录 {len(changed)} 条；相同记录见默认表。移除代码：{", ".join(removed) or "无"}。\n'
            if changed:
                result += self.table(name + ' 的新增/不同记录', changed, fields, 'Data.Config.' + name)
        return result

    def lucky(self, mode='all'):
        fields = ['generator', 'level_min', 'level_max']
        fields += ['lucky_chance'] if mode == 'chance' else ['lucky_chance', 'lucky_items', 'super_items']
        out = ''
        for name, config in self.configs.items():
            if 'LuckyProduceConfig' not in name:
                continue
            groups = config if isinstance(config, dict) else {'包内默认': config}
            for group, rows in groups.items():
                out += self.table(name + ' / ' + group, rows, fields,
                                  'Data.Config.' + name,
                                  '`lucky_chance=[总机会,Lucky配额]`；等级上下界均包含。不同变体由配置选择/活动决定，不同时叠加。')
        return out

    def server(self, mode):
        rows = [
            {'字段': 'energy_cost.range_entry', '用途': '当前能量消耗区间 [下界,上界]，用于选段与生成阈值', '来源': '活动服务器 luckyProduceConfig', '本地值': '未采集服务器生效配置'},
            {'字段': 'extra_lucky', '用途': '区间内免费 Lucky 的阈值数量；取 min(区间长度,extra_lucky)', '来源': '活动服务器 luckyProduceConfig', '本地值': '未采集服务器生效配置'},
            {'字段': 'triple_lucky_chance', '用途': '三连阈值，与整数 1..10000 比较', '来源': '活动服务器 luckyProduceConfig', '本地值': '未采集服务器生效配置'},
            {'字段': 'double_lucky_chance', '用途': '三连失败后比较二连阈值，与整数 1..10000 比较', '来源': '活动服务器 luckyProduceConfig', '本地值': '未采集服务器生效配置'},
        ]
        if mode == 'free':
            rows = rows[:2]
        elif mode == 'continuous':
            rows = [rows[0], *rows[2:]]
        return self.table('本页服务器配置字段', rows, ['字段', '用途', '来源', '本地值'],
                          'LuckyProduceModel:_LoadOtherServerConfig',
                          '这些字段不是 LuckyProduceConfig_triple 的包内字段；当前材料只确认读取结构，不能填写账号实际阈值。')

    def owned_body(self, family):
        if family == 'item':
            fields = sorted({k for r in self.spread for k in r if k.startswith('Spread_')})
            return self.item_table(self.spread, fields, 'ItemModelConfig：全部可产出母体')
        if family == 'lucky':
            body = self.lucky()
            codes = sorted({c for n, config in self.configs.items() if 'LuckyProduceConfig' in n
                            for rs in (config.values() if isinstance(config, dict) else [config])
                            for r in rs for c in r['generator']})
            return body + self.table('机会池数据库键（运行时状态，不是配表文件）',
                [{'Type': c, '总机会键': 'tl_' + c, 'Lucky配额键': 'll_' + c,
                  '当前值': '运行时状态，非包内配置'} for c in codes],
                ['总机会键', 'Lucky配额键', '当前值'], 'LuckyProduceModel DBKey')
        if family == 'activity':
            result = ''
            for name in ('GeneratorBoostItemModelConfig', 'GeneratorBoostItemModelConfig_shell'):
                for group, rows in self.configs[name].items():
                    fields = sorted({k for r in rows for k in r if k.startswith('Spread_')})
                    result += self.table(name + ' / ' + group, rows, fields, 'Data.Config.' + name,
                                         '仅在对应活动分组生效时替换母体配置，不能与默认配置累加。')
            return result
        if family == 'energy':
            codes = self.configs['EnergyBoostItemConfig']
            assert isinstance(codes, list) and len(codes) == 38
            return self.table('EnergyBoostItemConfig：完整适用列表', [{'Type': c} for c in codes],
                              [], 'Data.Config.EnergyBoostItemConfig', '本文件只配置适用母体 ID，不配置次数、CD 或普通产出权重。') + self.table(
                '八倍能量档的服务器字段', [{'字段': 'EnergyBoostEight', '作用': '八倍能量档触发能量门槛',
                '配置值': '服务器通用配置，未采集'}], ['字段', '作用', '配置值'],
                'EnergyBoostModel:TryTriggerEightEnergyBoost / OnLoginFinished')
        if family == 'order':
            return self.order_tables()
        if family in ('free', 'continuous'):
            return self.server(family)
        if family == 'smart':
            return self.table('Smart Produce 参数与临时权重',
                [{'字段': 'LuckyProduceSmart', '值': '服务器整数，未采集', '用途': '控制 Smart Produce 倍率'},
                 {'字段': 'SpreadSmartWeightKey', '值': '由订单缺口与倍率计算', '用途': '运行时临时权重，不是另一个包内配表文件'}],
                ['字段', '值', '用途'], 'LuckyProduceModel:_LoadOtherServerConfig / _UpdateSpreadConfigSmartWeight')
        if family == 'energy_cost':
            return self.table('EnergyBoostCost 服务器字段',
                [{'字段': 'boost_num', '作用': '消耗档位索引', '配置值': '服务器下发，未采集'},
                 {'字段': 'cost', '作用': '该档位的循环扣除次数序列', '配置值': '服务器下发，未采集'}],
                ['字段', '作用', '配置值'], 'EnergyBoostModel:LoadServerConfig / NextEnergyBoostCostIndex')
        if family == 'fish':
            return self.table('FishNetProduceSmart 服务器字段',
                [{'字段': 'FishNetProduceSmart', '作用': '生鱼链智能升级开关', '配置值': '服务器通用配置，未采集'}],
                ['字段', '作用', '配置值'], 'ItemSpread:SpreadCheckEnergyRatioAndCode')
        raise ValueError(family)

    def section(self, path):
        output_parent = path.parent if path.stem == 'index' else path.parent / path.stem
        self.asset_prefix = os.path.relpath(self.docs / 'assets/config-pieces', output_parent).replace('\\', '/')
        key = path.relative_to(self.docs / 'operations/generator').as_posix()
        families = [family for family, (owner, *_rest) in OWNERS.items() if owner == key]
        references = REFERENCES.get(key, [])
        if not families and not references:
            return ''
        result = '\n\n' + START
        for family in families:
            owner, anchor, title, reader = OWNERS[family]
            result += f'\n\n<a id="{anchor}"></a>\n\n## 本页涉及的配表：{title}\n\n**实际读取链**：`{reader}`\n\n'
            result += '本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。\n'
            result += self.owned_body(family)
        if references:
            result += '\n\n## 本逻辑使用的配表在哪里\n\n'
            for family in references:
                owner, anchor, title, reader = OWNERS[family]
                rel = os.path.relpath(self.docs / 'operations/generator' / owner, path.parent).replace('\\', '/')
                result += f'- [{title}]({rel}#{anchor})：配表文件/字段：`{CONFIG_FILES[family]}`；{reader}\n'
        return result + '\n\n' + END + '\n'


def supplement(docs):
    renderer = Renderer(docs)
    assets = docs / 'assets'
    (assets / 'generator-configs.css').write_text(CSS, encoding='utf-8')
    (assets / 'generator-configs.js').write_text(JS, encoding='utf-8')
    pages = sorted((docs / 'operations/generator').rglob('*.md'))
    for page in pages:
        body = page.read_text(encoding='utf-8')
        body = re.sub(r'\n*' + re.escape(START) + r'.*?' + re.escape(END) + r'\n*', '\n', body, flags=re.S)
        # Older builds could leave an unmarked lookup list when another
        # supplement rewrote the page after the config block. Remove that
        # stale generated list before inserting the canonical one again.
        body = re.sub(r'\n## 本逻辑使用的配表在哪里\n\n(?:- .*\n)+', '\n', body)
        # Configurations and lookup links follow the full worked example.
        page.write_text(body.rstrip() + renderer.section(page) + '\n', encoding='utf-8')
    (assets / 'generator-config-source-snapshot.json').write_text(json.dumps(renderer.configs, ensure_ascii=False, indent=2), encoding='utf-8')
    manifest = {family: {'page': owner, 'anchor': anchor, 'title': title, 'reader': reader}
                for family, (owner, anchor, title, reader) in OWNERS.items()}
    (assets / 'generator-config-placement.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Updated {len(pages)} existing pages; configurations on {len({v[0] for v in OWNERS.values()})} bottom-level pages.')


if __name__ == '__main__':
    supplement(ROOT / 'analysis_output/logic_recovery/stage3/mkdocs_site/docs')
