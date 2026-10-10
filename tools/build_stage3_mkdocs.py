"""Build the logic-tree shaped MkDocs Material site for Stage 3."""
from __future__ import annotations

import json
import inspect
import shutil
import subprocess
import textwrap
from pathlib import Path

from stage3_cases import prepare_assets, render_case

ROOT = Path(__file__).resolve().parents[1]
STAGE3 = ROOT / "analysis_output" / "logic_recovery" / "stage3"
SITE = STAGE3 / "mkdocs_site"
DOCS = SITE / "docs"


CASE_ASSET = DOCS / "assets" / "cases" / "generator-fixed-104.svg"
MERGE_ASSET = DOCS / "assets" / "cases" / "merge-201-to-202.svg"
ORDER_ASSET = DOCS / "assets" / "cases" / "order-submit.svg"


def ensure_case_asset() -> None:
    """Create a cached, self-contained case visual for the leadership site.

    The recovered snapshot has no verified sprite-to-item-code mapping for 104/201.
    This is therefore an explanatory composition, clearly labelled as such rather
    than presented as an original runtime screenshot.
    """
    CASE_ASSET.parent.mkdir(parents=True, exist_ok=True)
    CASE_ASSET.write_text("""<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"900\" height=\"250\" viewBox=\"0 0 900 250\">
<defs><linearGradient id=\"bg\" x1=\"0\" x2=\"1\"><stop stop-color=\"#f7fbff\"/><stop offset=\"1\" stop-color=\"#e6f1ff\"/></linearGradient></defs>
<rect width=\"900\" height=\"250\" rx=\"18\" fill=\"url(#bg)\"/><rect x=\"24\" y=\"24\" width=\"170\" height=\"170\" rx=\"28\" fill=\"#2d6cdf\"/>
<circle cx=\"109\" cy=\"92\" r=\"48\" fill=\"#fff\"/><path d=\"M74 126h70M82 116V73h54v43M91 73V57h36v16\" fill=\"none\" stroke=\"#2d6cdf\" stroke-width=\"9\" stroke-linecap=\"round\"/>
<text x=\"109\" y=\"177\" text-anchor=\"middle\" font-family=\"Arial,Microsoft YaHei\" font-size=\"18\" fill=\"#fff\">母体 104</text>
<path d=\"M225 110h125\" stroke=\"#5b708a\" stroke-width=\"5\"/><path d=\"m335 93 22 17-22 17\" fill=\"none\" stroke=\"#5b708a\" stroke-width=\"5\"/>
<rect x=\"390\" y=\"43\" width=\"180\" height=\"135\" rx=\"20\" fill=\"#fff\" stroke=\"#91aac7\" stroke-width=\"4\"/><circle cx=\"480\" cy=\"95\" r=\"36\" fill=\"#f5bd45\"/><path d=\"M455 95h50M480 70v50\" stroke=\"#fff\" stroke-width=\"8\" stroke-linecap=\"round\"/><text x=\"480\" y=\"157\" text-anchor=\"middle\" font-family=\"Arial,Microsoft YaHei\" font-size=\"18\" fill=\"#25364a\">产出 201</text>
<text x=\"610\" y=\"74\" font-family=\"Arial,Microsoft YaHei\" font-size=\"19\" fill=\"#25364a\">配置级案例示意</text><text x=\"610\" y=\"107\" font-family=\"Arial,Microsoft YaHei\" font-size=\"16\" fill=\"#526579\">Fixed：201-100</text><text x=\"610\" y=\"136\" font-family=\"Arial,Microsoft YaHei\" font-size=\"16\" fill=\"#526579\">每次消耗能量 1</text><text x=\"610\" y=\"165\" font-family=\"Arial,Microsoft YaHei\" font-size=\"14\" fill=\"#7b8794\">非原版截图；用于说明案例输入和结果</text>
</svg>""", encoding="utf-8")
    MERGE_ASSET.write_text("""<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"900\" height=\"250\"><rect width=\"900\" height=\"250\" rx=\"18\" fill=\"#fff8ef\"/><g fill=\"#e7963e\" stroke=\"#fff\" stroke-width=\"5\"><rect x=\"70\" y=\"65\" width=\"120\" height=\"120\" rx=\"22\"/><rect x=\"245\" y=\"65\" width=\"120\" height=\"120\" rx=\"22\"/></g><path d=\"M410 125h120m-22-18 22 18-22 18\" fill=\"none\" stroke=\"#98631f\" stroke-width=\"7\"/><rect x=\"585\" y=\"45\" width=\"180\" height=\"160\" rx=\"26\" fill=\"#f4bf55\" stroke=\"#fff\" stroke-width=\"5\"/><text x=\"130\" y=\"215\" font-family=\"Arial,Microsoft YaHei\" font-size=\"18\" text-anchor=\"middle\" fill=\"#68471d\">201</text><text x=\"305\" y=\"215\" font-family=\"Arial,Microsoft YaHei\" font-size=\"18\" text-anchor=\"middle\" fill=\"#68471d\">201</text><text x=\"675\" y=\"135\" font-family=\"Arial,Microsoft YaHei\" font-size=\"22\" text-anchor=\"middle\" fill=\"#68471d\">合成 202</text></svg>""", encoding="utf-8")
    ORDER_ASSET.write_text("""<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"900\" height=\"250\"><rect width=\"900\" height=\"250\" rx=\"18\" fill=\"#f1fbf6\"/><rect x=\"90\" y=\"42\" width=\"330\" height=\"166\" rx=\"20\" fill=\"#fff\" stroke=\"#75ad8a\" stroke-width=\"5\"/><circle cx=\"165\" cy=\"105\" r=\"28\" fill=\"#f0b546\"/><text x=\"220\" y=\"112\" font-family=\"Arial,Microsoft YaHei\" font-size=\"22\" fill=\"#28563b\">订单：需要 201 × 1</text><path d=\"M480 125h125m-22-18 22 18-22 18\" fill=\"none\" stroke=\"#3f825d\" stroke-width=\"7\"/><rect x=\"670\" y=\"65\" width=\"130\" height=\"120\" rx=\"22\" fill=\"#55a878\"/><text x=\"735\" y=\"135\" font-family=\"Arial,Microsoft YaHei\" font-size=\"20\" text-anchor=\"middle\" fill=\"#fff\">提交成功</text></svg>""", encoding="utf-8")
    (CASE_ASSET.parent / "case_asset_manifest.json").write_text(json.dumps({
        "scope": "stage3 leadership examples",
        "assets": [
            {"file": "generator-fixed-104.svg", "operation": "generator", "status": "explanatory-composition", "source": "recovered ItemModelConfig 104/201 values", "runtime_sprite_mapping": "runtime-pending"},
            {"file": "merge-201-to-202.svg", "operation": "merge", "status": "explanatory-composition", "source": "recovered ItemModelConfig 201.MergedType=202", "runtime_sprite_mapping": "runtime-pending"},
            {"file": "order-submit.svg", "operation": "order", "status": "explanatory-composition", "source": "operation case input, reward values not asserted", "runtime_sprite_mapping": "runtime-pending"}
        ],
        "note": "These cached visuals are deliberately labelled explanatory compositions until opaque Unity Sprite addressables are mapped to item codes."
    }, ensure_ascii=False, indent=2), encoding="utf-8")


def generator_case(path: str) -> str:
    """Return the same representative case at the appropriate detail level."""
    rel = "/assets/cases/generator-fixed-104.svg"
    if not path.startswith("operations/generator/"):
        return ""
    lower = path.lower()
    detail = """

### 本页的具体输入与状态

| 项目 | 案例值 | 口径 |
|---|---:|---|
| 母体代码 | `104` | 配置确认 |
| 产出配置 | `201-100` | 配置确认，Fixed |
| `Spread_CostEnergy` | `1` | 配置确认，本次基础消耗 1 |
| `Spread_ItemMaxNumber` | `80` | 配置确认 |
| `Spread_ItemRecoveryDuration` | `2` | 配置确认 |
| `Spread_StorageMaxNumber` | `240` | 配置确认 |
| `Spread_StorageRecoveryDuration` | `30` | 配置确认 |
| `MergedType` | `105` | 配置确认 |

本页对应的执行结果："""
    if any(x in lower for x in ("/lucky/", "/state/", "/position/", "/energy/", "/output/", "/lifecycle/", "events.md")):
        detail += "本案例沿用 `104` 的输入；本页所涉及的判断只在前置条件通过后执行。页面中的随机数是演示输入，不是原版运行时采样记录。"
    else:
        detail += "状态为 Opened、棋盘存在空位、能量余额至少为 1 时，Fixed 分支直接产出 `201`；若 Lucky 分支命中，则本次会先走 Lucky 产物，故本案例的普通产出结论仅在 Lucky 未命中演示路径下成立。"
    if "/lucky/" in lower:
        detail += """

#### 本案例的 Lucky 演示输入（非运行时回放）

为展示执行顺序，假设当前 `sourceType` 的机会池为 `totalLeftSpreadCount=60`、`luckyLeftSpreadCount=1`，演示随机抽样 `index=60`。因为 `1 >= 60` 不成立，普通 Lucky 未命中；若免费阈值队列也未命中，则回到普通 Fixed 产出 `201`。这组 `index` 是人为指定的可复现演示输入，不能当作原版客户端本次真实随机值。
"""
    return f"""
---

## 本案例：点击母体 104

![母体 104 到产出 201 的配置级案例示意]({rel})

**案例目的**：用一个最容易复核的 Fixed 母体，把“玩家点击 → 前置判断 → 产出 → 资源与次数变化”串成一条可读路径。图像是根据已确认配置绘制的说明素材，不声称是原版运行时截图。

**证据状态**：代码和本地配置为 `source-confirmed`；具体账号、活动开关、服务端动态配置和随机序列为 `runtime-pending`。{detail}
"""


def operation_case(path: str) -> str:
    if path.startswith("operations/generator/"):
        return generator_case(path)
    if path.startswith("operations/merge/"):
        return """
---

## 本案例：拖拽两个 201 合成 202

![两个 201 合成为 202 的配置级案例示意](/assets/cases/merge-201-to-202.svg)

**案例目的**：用最小的普通合成链说明玩家拖拽后的目标检查、合成映射和棋盘状态变化。`ItemModelConfig` 确认 `201.MergedType=202`；素材为解释性构图，不是原版运行时截图。

### 本页的案例位置

本页只展示与当前层级对应的部分：同类目标可合成时消耗两个 `201`，在目标格写入一个 `202`；特殊棋子、气泡和副产物由对应子页面继续展开。**证据状态**：映射为 `source-confirmed`，具体拖拽坐标、动画时序和服务端事件为 `runtime-pending`。
"""
    if path.startswith("operations/orders/"):
        return """
---

## 本案例：提交一个 201 订单

![订单需求与提交结果的配置级案例示意](/assets/cases/order-submit.svg)

**案例目的**：用一个单需求订单说明玩家点击提交后的需求匹配、扣除和奖励链。案例输入是“订单需要 `201 × 1`，棋盘中存在一件 `201`”；提交后需求归零，订单进入完成处理。

### 本页的案例位置

上层页面描述本次操作在整条订单链中的位置，底层页面再填写需求数组、消耗数量、奖励配置和事件字段。订单具体奖励、补位、网络同步和活动分支没有运行时快照时均标为 `runtime-pending`，不会把演示值当作服务器事实。
"""
    return ""


def write(path: str, content: str) -> None:
    target = DOCS / path
    target.parent.mkdir(parents=True, exist_ok=True)
    body = inspect.cleandoc(content).lstrip()
    body += render_case(path)
    target.write_text(body, encoding="utf-8")


def stats() -> str:
    def load(name: str) -> list:
        p = ROOT / "analysis_data" / "json" / name
        return json.loads(p.read_text(encoding="utf-8")) if p.exists() else []
    items, orders = load("ItemModelConfig.json"), load("OrderItemConfig.json")
    spread = sum(any(k.startswith("Spread_") for k in x) for x in items)
    merged = sum(x.get("MergedType") not in (None, "", 0) for x in items)
    bubbles = sum(float(x.get("BubbleChance", 0) or 0) > 0 for x in items)
    lo = min((x.get("DiffScore", 0) for x in orders), default=0)
    hi = max((x.get("DiffScore", 0) for x in orders), default=0)
    return f"`ItemModelConfig`: {len(items)} 行，Spread {spread} 行，MergedType {merged} 行，BubbleChance>0 {bubbles} 行；`OrderItemConfig`: {len(orders)} 行，DiffScore {lo}–{hi}。"


def main() -> None:
    if SITE.exists():
        shutil.rmtree(SITE)
    DOCS.mkdir(parents=True)
    prepare_assets(DOCS)
    s = stats()

    write("index.md", f"""# Gossip Harbor 棋盘逻辑

    本站采用逻辑树组织，不按真实源文件排列。左侧树的每一层代表游戏逻辑的一层：根节点是玩家操作，下一层是操作中的主要判断，再下一层是判断内部的机制分支，最底层页面直接给出算法、配表、状态和源码证据。

    ## 三个根操作

    - [母体点击](operations/generator/index.md)：状态、空位、能量、Lucky、五类普通产出、次数、CD 和后续事件。
    - [棋子拖拽与合成](operations/merge/index.md)：移动、交换、特殊棋子、普通合成和副产物。
    - [订单提交](operations/orders/index.md)：可交付判断、需求扣除、奖励、订单完成和补位。

    ## 阅读方法

    展开左侧树，父页面只解释当前层级的作用、顺序和子节点；子页面继续向下展开。底层节点页面同时展示算法、配表、状态字段、源码位置和证据等级，不把证据从机制中拆走。

    参考入口：[配置索引](reference/configuration.md)、[证据分级](reference/evidence.md)、[验收矩阵](verification/acceptance.md)、[当前状态](verification/status.md)。这些页面不占用左侧一级逻辑树。

    ## 当前规模

    Lua 模块 3,415 个，Lua 原型 33,272 个，Android 类 43,784 个，Android 方法 254,729 个。{s}
    """)

    write("operations/generator/index.md", """# 母体点击

    入口：`ItemSpread:OnTap`。一次点击不是“直接生成一个棋子”，而是按下面的顺序逐关检查；前置检查失败时，后面的阶段不会执行。

    | 顺序 | 检查/处理 | 不满足时的结果 | 通过后进入 |
    |---|---|---|---|
    | 1 | 状态检查 | Recharging / ItemClosed / ItemOpening | 空位检查 |
    | 2 | 空位检查 | BoardFull；不扣能量、不改次数 | 能量检查 |
    | 3 | 能量检查 | LackEnergy；不产出 | 产出代码计算 |
    | 4 | Lucky 判断 | 未命中则进入普通产出 | Lucky 物品或普通产出 |
    | 5 | 普通产出分派 | 根据 WeightType 选择算法 | 能量扣除 |
    | 6 | 能量扣除与落子 | 资源不足时失败 | 次数处理 |
    | 7 | 次数、变换与销毁 | 可能 Transform 或 CollapseItem | CD/恢复 |
    | 8 | CD 与恢复 | 记录服务器时间和恢复状态 | 本次点击结束 |

    本页只解释整条判断链；左侧子节点分别解释每个阶段。产出计算内部再分为 Lucky 判断和五种普通产出模式，不能概括成一个随机函数。

    **源码证据**：[Board_Model_Item_ItemSpread.lua](/C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua)。入口及主调用顺序为 `source-confirmed`；服务端开关和动态对象身份为 `runtime-pending`。
    """)
    write("operations/generator/entry.md", """# 点击入口与测试循环

    `ItemSpread:OnTap` 是玩家点击母体的入口。正常点击只执行一次 `_TrySpread`；测试模式同时开启 `TestSuperTap` 时把循环次数改为 10，教程棋盘又把它强制改回 1。每轮只要 `_TrySpread` 返回 false 就立即停止，不会为了凑满次数继续消耗资源。

    点击循环结束后，非一次性母体如果仍有冷却且剩余时间至少 1200 秒、同时当前次数为 0，会尝试打开系统通知窗口。这个通知发生在产出链之后，不参与产出判定。

    **源码**：`ItemSpread:OnTap`、`_TrySpread`、`CanAccelerate`、`GetTimerDuration`。`TestSuperTap` 的正式包可用性和通知权限属于 `runtime-pending`。
    """)
    write("operations/generator/entry_detail.md", """# OnTap、测试十连和通知判定

    入口先令 `spreadCount=1`。只有 `GameConfig.IsTestMode()` 为真且 `PlayerPrefs[TestSuperTap] == 1` 时改为 10；如果 `BoardType == Tutorial`，又把它改回 1。随后执行 `for i=1..spreadCount`：每轮调用 `_TrySpread()`，返回 false 立即 `break`，所以棋盘满、能量不足、状态错误或母体变换都能截断测试十连。

    循环结束后，代码只在 `not IsDisposable()` 且 `CanAccelerate()` 时计算 `restDuration = GetTimerDuration() + GetStartTimer() - serverTime`。当 `restDuration >= 1200` 且 `m_itemRestNumber == 0`，调用 `NotificationModel:TryOpenIOSNotificationWindow(ItemCoolDown)`。通知不扣资源、不改变计时，只是把长期冷却转为系统提醒。

    **证据**：`ItemSpread:OnTap` 的测试分支、循环短路和通知阈值为 `source-confirmed`；系统权限和实际弹窗展示为 `runtime-pending`。
    """)
    write("operations/generator/state/index.md", """# 状态检查

    状态检查是 `OnTap → _TrySpread` 的第一道闸门。代码按固定顺序读取同一个 `ItemSpread` 实例：先处理明确的关闭/开启状态，再处理初始化或次数耗尽，只有全部通过才允许寻找落点。

    ## 实际执行顺序

    1. `Closed`：派发 `SpreadFailed(ItemClosed)`，立即结束。
    2. `Opening`：派发 `SpreadFailed(ItemOpening)`，立即结束。
    3. `Initializing`，或 `m_itemRestNumber == 0`：可恢复母体派发 `SpreadFailed(ItemRecharging)`；一次性母体在耗尽时静默返回 false，因为它会在成功落子后销毁。
    4. 其它情况视为 `Opened`，进入空位检查。

    这里的“状态”不是独立布尔值：`m_state` 与 `m_itemRestNumber`、`m_startTimer` 共同决定点击结果。`UpdatePerSecond` 依据服务器时间把 Initializing/Opening 推进到 Opened，或把可恢复母体的次数补回；它不会改变本次点击的检查顺序。

    左侧每个状态页继续说明进入条件、计时字段、失败事件和边界行为；底层页给出对应源码分支。

    **源码入口**：`ItemSpread:CheckSpreadState`、`ItemSpread:UpdatePerSecond`、`ItemSpread:_UpdateRecoveryState`。**证据**：分支顺序 `source-confirmed`；实际账号计时、活动覆盖和前后台回放 `runtime-pending`。
    """)
    write("operations/generator/state/initializing.md", """# Initializing：初始化中

    母体拥有 `Spread_InitDuration` 且初始化计时未完成时处于此状态。点击不会产出棋子，也不会扣能量或次数，返回非一次性错误 `Recharging`。

    **字段/配表**：`m_initDuration`、`ItemModelConfig.Spread_InitDuration`、服务器时间起点。**源码**：`CheckSpreadState`、`UpdatePerSecond`。计时完成后转为 Opened；实际离线补时需运行时确认。
    """)
    write("operations/generator/state/closed.md", """# Closed：关闭

    只有配置了开启时长的母体可能以 Closed 初始。点击直接返回 `ItemClosed`，不进入空位和能量检查。

    **字段/配表**：`Spread_OpenDuration`、开启状态字段。**源码**：`CheckSpreadState`。不同母体活动的初始状态覆盖 `runtime-pending`。
    """)
    write("operations/generator/state/opening.md", """# Opening：开启中

    `OnOpen` 启动开启计时后进入 Opening。计时未完成时点击返回 `ItemOpening`，不会产出；完成后转为 Opened。

    **字段/配表**：`m_openDuration`、`Spread_OpenDuration`、服务器时间。**源码**：`OnOpen`、`CheckSpreadState`、`UpdatePerSecond`。边界时刻和前后台切换需回放。
    """)
    write("operations/generator/state/opened.md", """# Opened：可产出

    初始化或开启计时完成后，母体进入 Opened，才允许继续检查棋盘空位和能量。若剩余产出数不足，后续会启动 `m_itemRecoveryDuration` 或 `m_storageRecoveryDuration` 的恢复逻辑。

    **字段**：`m_itemRestNumber`、`m_storageRestNumber`、恢复时长字段。**源码**：`UpdatePerSecond`、恢复处理。恢复补充的精确时机和服务器时间漂移属于 `runtime-pending`。
    """)
    write("operations/generator/state/timing.md", """# 开启、加速与时间跳过

    这组流程处理母体从关闭到可产出的等待，以及玩家用宝石、广告或活动 Buff 跳过等待的行为。它不生成棋子；它只改变 `m_startTimer`，再让统一的 `UpdatePerSecond` 重新结算状态。

    ## 执行顺序

    1. `OnOpen` 把状态置为 `Opening`，立即调用 `UpdatePerSecond`，并通知棋盘当前有正在开启的母体。
    2. 玩家点击加速时进入 `OnSpeedUp → _SpeedUp`。非免费加速先读取 `GetSpeedUpCost`，再检查宝石余额；不足只发送 `LackGem`，不改计时。
    3. 宝石扣除或免费资格通过后，`OnTimeSkip` 把 `m_startTimer` 向服务器时间方向提前，并保存母体属性。
    4. `UpdatePerSecond` 重新计算进度；进度达到 1 时由 `_UpdateRecoveryState` 转为 `Opened` 或补回恢复次数。
    5. 点击链成功消耗完可恢复母体次数后，`TryUseCDBuff` 可能用 CD Buff、GeneratorBoost CD Buff 或测试免费开关再次跳过等待。

    左侧的具体页给出费用、时间字段、事件和每个分支的精确副作用。

    **源码**：`ItemSpread:OnOpen`、`OnSpeedUp`、`_SpeedUp`、`OnTimeSkip`、`TryUseCDBuff`、`OnTimeSkipInZeroRestNumber`。动态广告和活动对象身份标记为 `runtime-pending`。
    """)
    write("operations/generator/state/model.md", """# 状态字段与计时模型

    `ItemSpread:Init` 把 `ItemModelConfig` 的 Spread 字段复制到实例，建立运行时状态：自动标记、初始化/开启/恢复时长、各阶段加速费用、能量开关、次数上限、储备上限、变换次数和权重池。次数和储备从各自最大值开始，`m_spreadCount` 从 0 开始。

    初始状态由配置决定：有 `Spread_InitDuration` 就是 `Initializing`；否则有 `Spread_OpenDuration` 就是 `Closed`；两者都没有就是 `Opened`。教程强制时长只替换非空字段，不会凭空给母体增加一个计时阶段。`IsDisposable()` 的定义是没有 `Spread_ItemRecoveryDuration`，它决定耗尽后删除还是进入恢复。

    **源码**：`ItemSpread:Create`、`Init`、`IsDisposable`、`GetState`、`GetItemRestNumber`、`GetStorageRestNumber`、`GetWeightType`、`GetTransformNumber`。字段来源为 `ItemModelConfig`；教程覆盖为 `runtime-pending`。
    """)
    write("operations/generator/position/index.md", """# 空位检查

    空位检查发生在状态检查之后、能量检查之前。它只负责回答“本次产出能否找到目标格”，不负责决定产出代码。主动点击和自动产出在这里分流：自动母体先尝试自动落子；手动路径随后统一使用以母体为中心的扩散扫描。

    ## 分支顺序

    1. `Spread_Auto == 1` 的母体先调用 `FindSpreadPosition`；已经找到自动落点时，本次 `OnTap` 不再重复手动落子。
    2. 其余手动路径调用 `FindEmptyPositionInSpreadOrder(sourcePosition)`，返回扫描到的第一个空格。
    3. 没有位置时派发 `SpreadFailed(BoardFull)`，在能量、产出代码、扣能量和扣次数前结束。
    4. 自动循环由 `_TryAutoSpread` 单独处理；一次性 Decremental 母体在满足服务端开关时可以把剩余代码写入缓存。

    - [一次性母体落点](disposable/index.md)
    - [可恢复母体落点](recoverable/index.md)
    - [自动产出与缓存](auto/index.md)
    - [棋盘满失败](full/index.md)
    """)
    write("operations/generator/position/disposable.md", """# 一次性母体落点

    这一页回答“一次性母体点击后，落点阶段先做什么、为什么这样做”。一次性描述的是耗尽后的生命周期，不是每次点击都随机找格子。正式点击链的顺序是：

    1. `OnTap` 进入 `_TrySpread`，先过状态门槛；关闭、开启中、初始化中或次数为零时直接失败返回。
    2. `CheckSpreadPosAndAuto` 先判断是否为自动母体。手动一次性母体调用 `FindEmptyPositionInSpreadOrder(母体坐标)`，按固定方形环取第一个合法空格。
    3. 只有 `Spread_Auto == 1` 的自动路径才先调用 `FindSpreadPosition`；一次性母体在这里调用 `FindRandomPosition`，从当前全盘空位中均匀抽一个。自动路径已经找到位置时，手动点击不会再执行第二次扩散扫描。
    4. 找不到位置时，手动路径发送 `SpreadFailed(BoardFull)`，流程在能量检查之前结束；因此这次不生成产物、不扣能量、不扣次数。自动路径只会返回 false，另有满足条件的缓存分支。
    5. 找到位置后才进入能量检查、Lucky/普通产出、落子和次数扣除。一次性母体成功落子且剩余次数归零时，`TryRemoveSelf` 删除母体并派发 `CollapseItem`。

    ## 这一层要掌握的结论

    - **手动点击位置是确定性的**：同一母体坐标和同一棋盘占用状态得到同一格，不调用随机数。
    - **自动位置是当前集合上的均匀抽样**：每次 `FindRandomPosition` 都重新扫描空位并重新抽样，不保存已经抽过的格子集合。因此抽样本身是有放回语义；只有某格真正写入棋盘后，它才从下一次候选集合消失。
    - **一次性判定由缺失字段实现**：`IsDisposable()` 等价于 `m_itemRecoveryDuration == nil`。它影响耗尽后的删除/缓存和 CD 恢复，不改变手动落点算法。

    **源码证据**：`ItemSpread:OnTap`、`_TrySpread`、`CheckSpreadState`、`CheckSpreadPosAndAuto`、`TryRemoveSelf`、`_TryAutoSpread`、`MainBoardModel:FindSpreadPosition`、`BaseItemLayerModel:FindEmptyPositionInSpreadOrder`、`BaseItemLayerModel:FindRandomPosition`。配置字段来自 `ItemModelConfig`。确定的代码分支标为 `source-confirmed`；服务端缓存开关、实际账号棋盘和运行时随机种子仍标为 `runtime-pending`，不能由静态代码假定。
    """)
    write("operations/generator/position/recoverable.md", """# 可恢复母体落点

    调用 `FindEmptyPositionInCircleOrder(sourcePosition)`，从母体所在位置向外按圆周顺序寻找空位。它不是全棋盘随机选择，因此同一棋盘状态下通常具有稳定的优先落点。

    **源码**：`ItemSpread:CheckSpreadPosAndAuto`。**证据**：圆周扫描顺序 `source-confirmed`；边界棋盘的具体坐标序列需回放。
    """)
    write("operations/generator/position/auto.md", """# 自动产出与缓存

    自动母体先用 `FindSpreadPosition` 寻找自动落点；没有位置时，只有 `AutoSpreadToCache` 开启且满足一次性母体条件，才可能把剩余代码放入缓存。

    **配置/状态**：`AutoSpreadToCache`、缓存代码列表、母体剩余次数。**源码**：`CheckSpreadPosAndAuto`。开关的实际生效来源 `runtime-pending`。
    """)
    write("operations/generator/position/full.md", """# 棋盘满失败

    主动点击没有有效落点时触发 `SpreadFailed(BoardFull)`，停止后续能量扣除、产出落子和次数处理。这个失败点必须和“能量不足”区分：棋盘满不消耗能量。

    **源码**：`CheckSpreadPosAndAuto`、`SpreadItem`。**证据**：失败顺序 `source-confirmed`；UI 展示和重复点击行为 `runtime-pending`。
    """)
    write("operations/generator/energy/index.md", """# 能量检查

    能量检查决定“这次点击是否有资格进入产出”，但实际扣除发生在产出代码已经确定之后。这个先检查、后扣除的顺序很关键：代码先用能量模型返回最大消耗档和可用增益比率，生成器产出后再由 `EnergyBoostModel.GetBoostCostNum` 算最终扣除量。

    1. 读取 `Spread_CostEnergy`；Disco 支持当前母体时把本次消耗强制改为 0。
    2. 若免能量，直接返回 `(true, 0, false)`，仍然保留前面的空位检查。
    3. 若需能量，调用 `GetCostEnergyNum(itemType)` 得到余额检查用的最大消耗档和 `maxEnergyBoostRatio`。
    4. 余额不足派发 `BoardEventType.LackEnergy` 并结束，不生成代码、不扣次数。
    5. 余额足够才进入 `GenerateItemCode`；随后 `SpreadCostEnergy` 将最终消耗写入属性系统。

    - [是否需要能量](cost/index.md)
    - [基础消耗与增益](boost/index.md)
    - [余额不足与实际扣除](consume/index.md)
    """)
    write("operations/generator/energy/cost.md", """# 是否需要能量

    `costEnergy = (Spread_CostEnergy == 1)`；若 Disco 对当前母体生效则强制改为 false。免能量时返回允许产出和 0 消耗，但仍需完成空位检查。

    **配表**：`ItemModelConfig.Spread_CostEnergy`。**源码**：`CheckEnergy`。Disco 的活动来源 `runtime-pending`。
    """)
    write("operations/generator/energy/boost.md", """# 基础消耗与增益

    `GetCostEnergyNum(itemType)` 返回基础 `nCostNum` 和最大 `nEnergyBoostRatio`；最终扣除由 `EnergyBoostModel.GetBoostCostNum(energyBoostRatio)` 计算。

    **配置/状态**：EnergyBoost 字段、母体类型、当前增益索引。**源码**：`CheckEnergy`、`SpreadCostEnergy`。不同母体的实际增益覆盖 `runtime-pending`。
    """)
    write("operations/generator/energy/consume.md", """# 余额不足与实际扣除

    余额不足返回 `LackEnergy`，停止产出，不改母体次数。余额足够时调用 `PropertyDataManager:Consume` 扣除，并记录 `EBIType.SpreadItem`。

    **源码**：`CheckEnergy`、`SpreadCostEnergy`。**证据**：失败和扣除顺序 `source-confirmed`；UI 提示和 BI 网络上报时机 `runtime-pending`。
    """)

    write("operations/generator/lucky/index.md", """# Lucky 判断

    Lucky 判断的目的不是直接从 `lucky_items` 抽一个物品，而是先回答“这次点击是否获得 Lucky 资格”，再回答“如果获得，产出哪一个 Lucky 物品”。两问使用不同状态和不同随机语义。

    ## 实际执行顺序

    1. **确认 Lucky 是否可用**：检查 Lucky 活动是否处于 Started，并根据母体类型和玩家等级选择适用配置；没有配置就结束 Lucky 分支。
    2. **优先处理已有连续 Lucky**：如果数据库中记录的连续 Lucky 目标类型、次数和有效期仍匹配当前母体，直接沿用连续 Lucky，不重新抽周期机会。
    3. **检查 GeneratorBoost 特殊入口**：活动持有额外 Lucky 且空位条件允许时，直接走 Lucky 物品选择；空位不足时保存延迟状态并结束。
    4. **读取周期机会池**：读取总机会和 Lucky 配额；总机会为 0 时用配置重新装填。
    5. **进行机会判定**：在 `1..total` 中抽一个整数，比较是否落入 Lucky 配额；这一步决定是否有普通 Lucky 资格。
    6. **机会未命中时检查免费 Lucky**：只有普通机会未命中，才检查免费阈值队列；命中免费阈值会把本次改为 Lucky，但不消耗普通总机会。
    7. **写回机会池计数**：普通 Lucky 消耗 Lucky 配额；非免费 Lucky 消耗总机会。机会池处理完后，才进入产物选择。
    8. **尝试触发下一次连续 Lucky**：根据当前能量段配置依次判断三连和二连，并写入连续 Lucky 状态。
    9. **选择 Lucky 物品**：按普通或 Smart Produce 权重池累计选择一个物品，再根据是否 Super/Free 设置产出类型。

    ## 设计含义

    机会池控制 Lucky 的“资格”，物品池控制 Lucky 的“内容”；免费 Lucky 是对机会判定失败后的补救入口；连续 Lucky 是对本次 Lucky 结果设置的后续状态。把它们合并成一个概率表会丢失计数扣减、免费机会和连续状态。

    左侧四个子节点是第三层机制；继续展开后才进入第四层的读取、判断、写回和抽样细节。

    **源码**：[LuckyProduceModel.lua](/C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua)，主入口 `Try2ProduceLuckyItem`。
    """)
    write("operations/generator/lucky/chance/index.md", """# Lucky 机会池

    机会池负责决定“本次普通机会是否成为 Lucky”。它是第三层机制页面；第四层按源码顺序拆成读取/重装、随机比较、计数写回三个步骤。

    - [读取与周期重装](load.md)
    - [随机比较](roll.md)
    - [计数扣减与保存](commit.md)

    机会池的关键语义是：总机会和 Lucky 配额都会被消耗，因此是有限配额的无放回抽取。
    """)
    write("operations/generator/lucky/chance/load.md", """# 读取与周期重装

    每种 `sourceType` 从数据库读取 `tl_<sourceType>`（剩余总机会）和 `ll_<sourceType>`（剩余 Lucky 机会）。如果 `totalLeftSpreadCount == 0`，使用 `lucky_chance[1]` 作为总机会、`lucky_chance[2]` 作为 Lucky 配额，并先保存 Lucky 配额。

    **源码**：`Try2ProduceLuckyItem`、`_GetTotalLeftSpreadCount`、`_GetLuckyLeftSpreadCount`。**配置**：`LuckyProduceConfig.lucky_chance[1]`、`[2]`。周期何时被清空和重新进入需运行时确认。
    """)
    write("operations/generator/lucky/chance/roll.md", """# 随机比较

    使用 `MathUtil.Random(totalLeftSpreadCount)`，等价于 `Random(1,total)`，两端包含。若 `luckyLeftSpreadCount >= index`，本次获得普通 Lucky；测试模式的强制 Lucky 开关可以额外改变结果。

    **源码**：`Try2ProduceLuckyItem`。**随机语义**：从当前有限机会数中抽取位置，而不是每次调用固定概率。测试开关 `TestLuckyProduce` 的正式账号可用性为 `runtime-pending`。
    """)
    write("operations/generator/lucky/chance/commit.md", """# 计数扣减与保存

    普通 Lucky 命中时，`luckyLeftSpreadCount -= 1` 并保存；只要不是免费 Lucky，`totalLeftSpreadCount -= 1` 并保存。免费 Lucky 不走总机会扣减。

    **结论**：下一次抽样使用已经改变的分母和配额，所以不能复刻为独立伯努利概率。**源码**：`Try2ProduceLuckyItem`、`_SetLuckyLeftSpreadCount`、`_SetTotalLeftSpreadCount`。证据 `source-confirmed`。
    """)
    write("operations/generator/lucky/items/index.md", """# Lucky 物品权重

    只有在 Lucky 资格已经确定后才选择物品。该机制不再决定“是否 Lucky”，而是从 `lucky_items` 中决定产出内容，随后判断是否属于 `super_items` 并设置产出类型。

    - [候选与累计权重选择](select.md)
    - [Smart Produce 权重修正](smart.md)
    - [Super/Free 产出类型](type.md)
    """)
    write("operations/generator/lucky/items/select.md", """# 候选与累计权重选择

    调用 `Table.ListWeightSelectOne(config.lucky_items)`，按累计权重选择一个对象；该调用不删除候选、不减少原始 `Weight`，因此物品池是有放回语义。

    **配置**：`LuckyProduceConfig.lucky_items` 的 `Item` 和 `Weight`。**源码**：`_GetGenerateLuckyItem`、`Table.ListWeightSelectOne`。连续点击出现同一物品是允许结果。
    """)
    write("operations/generator/lucky/items/smart.md", """# Smart Produce 权重修正

    `_UseSmartProduce()` 为真时，先根据订单缺口和能量增益等级调用 `_UpdateSpreadConfigSmartWeight`，再使用 `SpreadSmartWeightKey` 进行累计权重选择；原始配置权重与本次临时修正权重需分开保存。

    **字段**：`m_smartProduceRatio`、Smart 权重字段、订单缺口映射。**源码**：`_UseSmartProduce`、`_UpdateSpreadConfigSmartWeight`。服务端 Smart Produce 开关和值 `runtime-pending`。
    """)
    write("operations/generator/lucky/items/type.md", """# Super/Free 产出类型

    选中物品后检查它是否存在于 `config.super_items`。普通 Lucky 产生 `SuperLucky` 或 `Lucky`；免费 Lucky 产生 `FreeSuperLucky` 或 `FreeLucky`。这是产出类型标记，不会改变前面机会池是否扣减的结果。

    **配置**：`LuckyProduceConfig.super_items`。**源码**：`_GetGenerateLuckyItem`。活动配置覆盖 `runtime-pending`。
    """)
    write("operations/generator/lucky/free/index.md", """# 免费 Lucky

    免费 Lucky 是机会判定未命中后的第二条资格路径。它不重新抽 `lucky_items`，而是检查能量消耗计数是否达到预先生成的阈值；达到后把本次改成 Lucky，并消费一个阈值。

    - [阈值队列生成](generate.md)
    - [阈值检查与消费](consume.md)
    """)
    write("operations/generator/lucky/free/generate.md", """# 阈值队列生成

    特殊模式按能量区间配置生成阈值。每个区间调用 `MathUtil.RandomN(rangeSize, min(rangeSize, extra_lucky))`，得到互不重复的位置，排序后加上区间起点并追加到 `elpec` 队列。

    **状态**：`elpec`、能量区间索引。**配置**：`energy_cost.range_entry`、`extra_lucky`。**源码**：`_AddFreeLuckyProduceEnergyCostCount`。`RandomN` 不放回位置语义 `source-confirmed`。
    """)
    write("operations/generator/lucky/free/consume.md", """# 阈值检查与消费

    `_CanFreeLuckyProduce` 检查队首阈值是否已被当前能量消耗计数达到；命中后 `_PostProcessOnFreeLuckyProduce` 移除队首并保存队列。本次不减少 `tl_<sourceType>`。

    **源码**：`_CanFreeLuckyProduce`、`_PostProcessOnFreeLuckyProduce`。**状态**：`elpec`、EnergyCostCount。每日重置和实际能量计数来源 `runtime-pending`。
    """)
    write("operations/generator/lucky/continuous/index.md", """# 连续 Lucky

    连续 Lucky 是本次 Lucky 结果产生的后续状态。它不替代本次物品选择，而是为接下来的点击设置同类型连续产出资格，并在每次连续产出时延长有效期。

    - [三连/二连触发判断](trigger.md)
    - [连续状态写入](state.md)
    - [连续状态消费与失效](consume.md)
    """)
    write("operations/generator/lucky/continuous/trigger.md", """# 三连/二连触发判断

    当前特殊模式配置存在时，先以 `Random(1,10000)` 判断三连；三连未命中才以同范围随机判断二连。三连写入最大连续次数 2，二连写入最大连续次数 1。

    **配置**：`triple_lucky_chance`、`double_lucky_chance`。**源码**：`_Try2TriggerContiLuckyProduce`。两个判断不是并列独立同时执行，而是二连只在三连失败后执行。
    """)
    write("operations/generator/lucky/continuous/state.md", """# 连续状态写入

    `_TriggerContiLuckyProduce` 写入 `clpit`（目标类型）、`clpmc`（最大次数）、`clpc=0`（当前次数），并把 `clpeet` 设置为服务器时间加 10 秒。

    **源码**：`_TriggerContiLuckyProduce`。**状态**：`clpit`、`clpmc`、`clpc`、`clpeet`。期限使用服务器时间，不能用客户端本地时间替代。
    """)
    write("operations/generator/lucky/continuous/consume.md", """# 连续状态消费与失效

    `_CanContiLuckyProduce` 要求目标类型相同、当前次数小于最大次数且服务器时间未超过 `clpeet`；任一条件不满足就清除四个连续字段。命中后递增 `clpc` 并把有效期重新延长 10 秒。

    **源码**：`_CanContiLuckyProduce`、`_PostProcessOnContiLuckyProduce`、`_CLearContiLuckyProduceData`。对象类型变化、超时和次数用尽均属于不同失效原因，应在回放中分开验证。
    """)

    write("operations/generator/output/index.md", """# 普通产出

    Lucky 未命中（或 Lucky 活动不适用）后，`GenerateItemCode` 才进入普通产出。它先保存当前状态并调用 `_GenerateItemCode` 按 `Spread_WeightType` 分派；拿到原始代码后，再经过能量增益升级、活动改写、次数扣除和保存。也就是说，下面的五类页面解释的是“原始代码如何选”，不是最终落子代码的全部来源。

    统一顺序是：

    1. 教程强制代码（有值时直接返回）。
    2. 按 `Fixed / Decremental / OrderItem / ChestCustomItem / SmartItem` 选择原始代码。
    3. `SpreadCheckEnergyRatioAndCode` 根据订单缺口、棋盘已有数量和链等级决定能量增益次数，并沿 `MergedType` 链升级代码。
    4. Disco 等活动执行 `DealActivityLimit`，可能改写代码并把次数消耗设为 0。
    5. `CosetRestNumber` 扣母体次数，`UpdatePerSecond`、事件和存档随后执行。

    分支页面：

    - [Fixed](fixed/index.md)
    - [Decremental](decremental/index.md)
    - [OrderItem](order/index.md)
    - [ChestCustomItem](chest/index.md)
    - [SmartItem](smart/index.md)

    能量升级、Lucky 产物和活动改写都可能使“原始候选”和“最终代码”不同；实现复刻时必须按上述顺序串接，不能只复刻五个候选池。
    """)
    write("operations/generator/output/fixed.md", """# Fixed

    Fixed 不是一次点击固定一个代码，而是把母体类型（或 ItemStateCollection 状态）交给 `ItemFixedSpreadModel` 的固定池模型。`_GenerateItemCode` 先检查 GeneratorBoost SmartProduce 和 Smart Buff；智能产出有结果时优先采用，否则才进入固定池。固定池的候选不会因点击从 `m_codeWeightPairs` 删除，和 Decremental 的可变池不同。

    **配表**：`Spread_WeightType=1`；食品袋 105 的普通池为 `201×35、202×2、301×5`。**源码**：`ItemSpread:_GenerateItemCode`、`_FixedGenerateItemCode`、`ItemFixedSpreadModel:GenerateItemCode`。活动对象和实际 SmartProduce 命中标记 `runtime-pending`。
    """)
    write("operations/generator/output/decremental.md", """# Decremental

    Decremental 把配置中的每个 `Weight` 当作可消耗的剩余份数。每次用当前权重做一次加权整数选择，选中项减 1，减到 0 就从列表移除并保存；因此候选池随点击变化，等价于按权重展开后逐份无放回抽取。它与 Lucky 机会池的计数状态分开维护。

    **配表**：`Spread_WeightType=2`、候选代码与 `Weight`，当前 54 行。**源码**：`ItemSpread:_GenerateItemCode`、`Table.ListWeightSelectOne`、`GetAutoSpreadDecrementalRemainTypes`。
    """)
    write("operations/generator/output/order.md", """# OrderItem

    用 `CalculateOrderCodeLackNumMap(false,true,false)` 得到订单缺口；候选权重为 `min(DiffScore,300)`，OrderBoost 缺口再乘 1000。尝试后删除候选，再尝试同链低等级输出，最后回退到已解锁且生成器有效的候选。

    **配表**：`OrderItemConfig.DiffScore`、`Spread_StorageMaxNumber`；当前 74 行，DiffScore 2–3000。**语义**：候选显式移除，属于不放回。**源码**：`ItemSpread` OrderItem 分支、`MainOrderModel` 缺口计算。OrderBoost 激活 `runtime-pending`。
    """)
    write("operations/generator/output/chest.md", """# ChestCustomItem

    调用 `GenerateChestCustomCodeRule` 生成代码，失败回退 `205`；消耗按选中代码的 `DiffScore` 计算。

    **配表**：箱子自定义规则、代码 `OrderItemConfig.DiffScore`；当前 1 行。**源码**：`GenerateChestCustomCodeRule` 调用链。活动箱子覆盖 `runtime-pending`。
    """)
    write("operations/generator/output/smart.md", """# SmartItem

    收集订单棋子候选，数量上限由 `Spread_StorageMaxNumber` 控制，调用 `SmartRewardHelper.GetCodesFor_ItemSpread`；消耗选中代码的 `DiffScore`，缺失时使用 1。

    **配表**：`Spread_StorageMaxNumber`、订单候选和 `DiffScore`；当前 5 行。**源码**：`ItemSpread` SmartItem、`SmartRewardHelper`。FishNetProduceSmart `runtime-pending`。
    """)
    write("operations/generator/lifecycle/index.md", """# 扣除次数与 CD 恢复

    产出代码确定后，点击链按“扣次数 → 写入棋盘 → 尝试变换/销毁 → 尝试 CD Buff”的顺序收尾。可恢复母体的剩余次数不足会启动服务器时间计时；一次性母体耗尽则在成功落子后移除自身。

    - [次数扣除、变换与销毁](count/index.md)
    - [CD、加速与恢复](cooldown/index.md)
    """)
    write("operations/generator/lifecycle/count.md", """# 次数扣除、变换与销毁

    `CosetRestNumber` 先增加 `m_spreadCount`。一次性母体默认扣除 `floor(2 ^ energyBoostRatio)`；普通母体调用 `EnergyBoostModel:NextEnergyBoostCostIndex`；OrderItem 使用命中代码权重。

    `TryRemoveSelf` 先检查 `m_transformNumber == m_spreadCount` 并 Transform；否则剩余次数为 0 且不可恢复时删除并发送 `CollapseItem`。

    **字段/配表**：`m_spreadCount`、`m_transformNumber`、EnergyBoost 索引、TransformNumber。**源码**：`CosetRestNumber`、`TryRemoveSelf`。**证据**：扣除顺序 `source-confirmed`。
    """)
    write("operations/generator/lifecycle/cooldown.md", """# CD、加速与恢复

    CD 使用服务器时间字段 `m_startTimer`。加速费用按剩余时长比例向上取整，最低 1 宝石；恢复分支补回 `m_itemRestNumber` 并减少 `m_storageRestNumber`。

    **字段/配表**：`m_startTimer`、`m_itemRecoveryDuration`、`m_storageRecoveryDuration`、`Spread_ItemRecoveryDuration`、`Spread_StorageRecoveryDuration`。**源码**：`UpdatePerSecond`、CD Buff 处理。Buff 叠加顺序和离线补时 `runtime-pending`。
    """)
    write("operations/generator/events.md", """# 事件与后续影响

    事件不是另一套成功判定，而是把已经完成的状态变化通知给棋盘、活动、统计和界面。失败事件在对应闸门立即发送；成功事件要等产出代码、能量、落子和母体收尾参数都已准备好。

    **失败**：`_NotifySpreadFailed` 同时调用棋盘事件 `SpreadFailed`、全局 `EEventType.SpreadFailed` 和重震动 `VibrationHeavy`。

    **成功**：`BaseBoardModel:SpreadItem` 生成新棋子并发送 `BoardEventType.SpreadItem`；`MainBoardModel:SpreadItem` 再派发 `EEventType.ItemSpread`、写 BI `LogSpread`，点击链随后发送 `VibrationLight`。

    **状态持久化**：产出代码和次数处理过程中会调用 `SaveItemProperty`；变换走 `ItemTransform:Transform`，一次性耗尽走 `RemoveItem` 和 `BoardEventType.CollapseItem`。具体监听对象和异步网络上传仍按证据等级标记。
    """)
    write("operations/generator/overrides/index.md", """# 产出改写与安全边界

    产出代码确定前后还有三类会改变最终结果的逻辑：活动可以替换代码或费用，能量增益可以沿合成链升级代码，安全修正会把异常次数限制在配表上限内。它们分别发生在 `GenerateItemCode` 的不同位置，不能合并成一个“加成”字段。

    - [Lucky、Disco 与产出改写](activity/index.md)
    - [能量增益与链升级](boost/index.md)
    - [数值安全修正](safety/index.md)
    """)
    write("operations/generator/overrides/activity.md", """# Lucky、Disco 与产出改写

    `GenerateItemCode` 的入口优先检查 Lucky；Lucky 成功就直接返回 Lucky 代码。未命中时，如果 Disco 支持当前母体，先尝试直接提供 Disco 代码；没有直接代码时仍标记 Disco 场景并把最大能量增益档提升到 3。普通产出生成后，`DealActivityLimit` 还可以再次由 Disco 改写代码和增益倍率，并把本次 `costCount` 改为 0。

    这解释了为什么同一个母体在不同活动状态下可能出现不同代码、不同扣费和不同 BI 产出类型。

    **源码**：`CheckLuckyProduce`、`TryGenerateLuckyItem`、`TryGenerateDiscoItem`、`DealActivityLimit`、`GenerateItemCode`。Lucky 的机会池和物品池见左侧 Lucky 分支；本页只说明它们在普通产出入口的执行优先级。
    """)
    write("operations/generator/overrides/boost.md", """# 能量增益与链升级

    能量增益不是简单把一个数乘大。`SpreadCheckEnergyRatioAndCode` 先保存原始代码，再根据最大增益档和订单缺口检查同一合成链上的更高等级；找到订单缺口或特定奇数缺口时提前截断增益档，然后沿 `MergedType` 逐级替换代码。FishNetProduceSmart 仅在服务端开关开启、代码属于生鱼链且缺口恰好满足二进制等级条件时再次替换到目标等级。

    该流程发生在普通代码选择之后、次数扣除之前；最终 `energyBoostRatio` 同时影响代码等级和一次性母体的扣除量。

    **源码**：`SpreadCheckEnergyRatioAndCode`、`CosetRestNumber`。订单缺口和服务端开关的实时值属于 `runtime-pending`。
    """)
    write("operations/generator/overrides/safety.md", """# 数值安全修正

    `SafeSpreadItem` 在真正生成代码前检查两组持久化数值：`m_itemRestNumber` 不能大于 `m_itemMaxNumber`，`m_storageRestNumber` 不能大于 `m_storageMaxNumber`。超过上限时先记录对应 BI 错误，再把数值截回上限；它不会补次数，也不会改变权重池。

    自动缓存完成后调用 `EmptySpreadCount`，把剩余次数和储备同时置零；Decremental 母体还会清空 `m_codeWeightPairs`。因此“异常上限修正”和“正常耗尽清空”是两个不同阶段。

    **源码**：`SafeSpreadItem`、`EmptySpreadCount`。**字段**：`m_itemRestNumber`、`m_itemMaxNumber`、`m_storageRestNumber`、`m_storageMaxNumber`、`m_codeWeightPairs`。
    """)

    # Non-Lucky generator branches use the same four-level contract as Lucky:
    # stage overview -> branch overview -> directly reproducible detail page.
    fourth_pages = {
        "entry_detail.md": ("OnTap、测试十连和通知判定", "`OnTap` 每次先把 `spreadCount` 设为 1；测试模式且 `PlayerPrefs.TestSuperTap==1` 时改为 10，但 Tutorial 棋盘再次限制为 1。循环逐次调用 `_TrySpread`，任何 false 结果立即终止，因此测试十连不会绕过状态、空位或能量门禁。循环后，非一次性且存在冷却计时的母体才计算 `GetTimerDuration()+GetStartTimer()-serverTime`；剩余时间至少 1200 秒并且 `m_itemRestNumber==0` 时调用 `TryOpenIOSNotificationWindow(ItemCoolDown)`。"),
        "state/initializing_detail.md": ("初始化计时的具体判定", "`Init` 先把 `Spread_InitDuration` 复制到 `m_initDuration`；存在该字段就把 `m_state` 设为 `Initializing`，随后立即调用 `UpdatePerSecond` 写入服务器时间 `m_startTimer`。点击时 `CheckSpreadState` 先排除 Closed/Opening，再因 Initializing 派发 `ItemRecharging`（可恢复母体）并返回 false；因此不会扫描空位，也不会读取能量。计时达到 `GetTimerDuration()` 后 `_UpdateRecoveryState` 清空计时、改为 Opened、派发 `EEventType.ItemOpened` 并刷新棋盘开启列表。"),
        "state/closed_detail.md": ("关闭状态的具体判定", "`Init` 在没有初始化时，如果 `Spread_OpenDuration` 非空就把 `m_state` 设为 `Closed`，但不启动计时。`OnTap` 进入 `CheckSpreadState` 后首先命中 Closed 分支，调用 `_NotifySpreadFailed(ItemClosed)`，依次发送棋盘失败事件、全局失败事件和重震动，然后返回 false；空位、能量和产出函数均不会执行。`OnOpen` 才把状态改为 Opening 并开始计时。"),
        "state/opening_detail.md": ("开启中状态的具体判定", "`OnOpen` 写入 `m_state=Opening`，`UpdatePerSecond` 为 `m_startTimer` 记录服务器时间并发送 `StateChanged`。计时未完成时，`CheckSpreadState` 命中 Opening，发送 `ItemOpening` 失败链并停止；到期由 `_UpdateRecoveryState` 将状态改为 Opened、清空 `m_startTimer`、派发 `ItemOpened` 和 `UpdateOpeningItem`。`GetSpeedUpCost` 在此阶段使用 `m_openSpeedUpCost`，不是恢复时长费用。"),
        "state/opened_detail.md": ("可产出状态的具体判定", "`CheckSpreadState` 没有显式的 `Opened` 分支；只要不是 Closed/Opening/Initializing，且 `m_itemRestNumber` 不为 0，就返回 true。可恢复母体在次数耗尽时走同一个 `ItemRecharging` 分支；一次性母体耗尽则不发 Recharging，等待成功落子后的 `TryRemoveSelf` 删除。`GetTimerDuration` 在 Opened 状态根据 `m_storageRestNumber == 0` 选择储备恢复时长或单轮恢复时长。"),
        "state/timing_detail.md": ("开启、加速和时间跳过的具体结算", "`OnOpen` 只写入 `m_state=Opening`，随后由 `UpdatePerSecond` 决定是否建立 `m_startTimer`；它还发送 `ItemOpening` 并调用 `UpdateOpeningItem`。`_SpeedUp(false)` 先读取 `GetSpeedUpCost` 和宝石余额，不足时发 `BoardEventType.LackGem`（场景 `TimeSkip`）并立即返回；足够时调用 `PropertyDataManager:Consume(Gem,cost,SpeedUp,sourceCode)`。免费路径跳过宝石扣除。两条路径最后都调用 `OnTimeSkip`：没有显式 duration 时先把起点重置为当前服务器时间，再减去整个阶段时长，保存属性、播放音效、重新 `UpdatePerSecond`，并按 `Gem`/`ad`/`Buff` 写加速 BI。`TryUseCDBuff` 只有在支持 CD Buff、GeneratorBoost CD Buff 或测试免费开关之一成立，且 `m_itemRestNumber==0` 时才调用同一时间跳过；`OnTimeSkipInZeroRestNumber` 还要求对象是生成器、使用能量且属于主棋盘。"),
        "state/model_detail.md": ("初始化字段、进度公式和恢复重置", "`Init` 先深拷贝 `Spread_Weight`，再把次数和储备初始化为各自最大值。`Spread_InitDuration` 非空时状态为 `Initializing` 并立即 `UpdatePerSecond`；否则 `Spread_OpenDuration` 非空时状态为 `Closed`；否则直接 `Opened`。教程强制时长只对原本存在的 init/open/item-recovery/storage-recovery 字段替换。计时进度由 `elapsed = serverTime - m_startTimer`、`amount=min(elapsed/duration,1)` 得到；没有 duration 时记录完整字段诊断并把起点清空，duration 为 0 直接视为完成。`GetTimerDuration` 在 Initializing/Opening 读取对应阶段时长，在 Opened 依据 `m_storageRestNumber==0` 选择储备恢复或单轮恢复。完成后 `_UpdateRecoveryState` 要么转为 Opened，要么补满次数并扣除储备；储备耗尽时把起点推进一个 item recovery duration 再递归重算。"),
        "position/disposable_detail.md": ("一次性落点的具体算法", "### 1. 手动点击：确定性的方形环扫描\n\n`_TrySpread` 先通过 `CheckSpreadPosAndAuto` 取落点。一次性母体通常 `Spread_Auto != 1`，因此直接调用 `FindEmptyPositionInSpreadOrder(centerPosition)`。底层实现先令 `currentPosition=centerPosition`，令 `maxTiles=max(HorizontalTiles,VerticalTiles)`；对 `i=1..maxTiles-1`，先把当前位置移到左下角方向的 `(-1,-1)`，形成边长 `2*i` 的方形环，再按 `dir=1..4`、每个方向走 `2*i` 格。每到一格先调用 `PositionIsValid`，再调用 `GetItem==nil`；第一个合法空格立即返回。扫描完所有环后返回传入的 `openedPosition`，本次调用没有传该参数所以结果为 nil。\n\n这意味着手动一次性母体不是随机选位置：同一棋盘占用状态和同一母体坐标下，返回位置完全由扫描顺序决定。\n\n### 2. 自动产出：随机空位与自动循环\n\n`Update` 对 `Spread_Auto==1` 的母体反复调用 `_TryAutoSpread`。该函数先检查 `m_itemRestNumber != 0` 且 `m_state == Opened`，再通过 `_GetAutoSpreadPosition → MainBoardModel:FindSpreadPosition` 选位置。`FindSpreadPosition` 对 `IsDisposable()` 为真时调用 `FindRandomPosition`；可恢复母体则调用八邻域 `FindEmptyPositionInCircleOrder`。位置成功后才生成代码并写入棋盘，循环继续直到无次数、无位置或触发变换。\n\n### 3. `FindRandomPosition` 的每一次抽样\n\n`BaseItemLayerModel:FindRandomPosition` 每次调用都新建 `positions` 临时数组，从 `GetValidPositionIterator()` 的有效位置迭代器开始。迭代器从 `(1,1)` 逐格走：x 递增，x 超过棋盘宽度时换到下一 y；每格读取 `GetItem`，只把空格插入数组。空数组交给 `Table.ListRandomSelectOne` 返回 nil；非空数组由 `MathUtil.Random(#positions)` 生成 1 到候选数的整数下标并返回该项。它没有保存“已抽过的位置”集合，也没有在抽样后从棋盘写入前修改候选数组；下一次调用重新扫描当前棋盘。因此它是“每次基于当前空位集合的独立均匀抽样”，从概率语义上属于有放回抽样；真正落子后该格才会从下一次候选集合消失。\n\n### 4. 满盘、缓存与最终写入\n\n手动扫描返回 nil 时，`CheckSpreadPosAndAuto` 立即调用 `_NotifySpreadFailed(BoardFull)`；该函数同时发 `BoardEventType.SpreadFailed`、`EEventType.SpreadFailed` 和 `VibrationHeavy`，随后 `_TrySpread` 返回，能量、产出代码、扣除次数、落子均不执行。自动路径无位置时，若 `IsDisposable()`、`m_weightType==Decremental`、`CacheItemFromSpread` 方法存在且 `AutoSpreadToCache` 服务端开关开启，则把 `GetAutoSpreadDecrementalRemainTypes()` 展开的剩余代码列表写入缓存，递增 `m_spreadCount`，调用 `EmptySpreadCount` 清空次数和 Decremental 权重，并通过缓存事件通知；否则 `_TryAutoSpread` 返回 false。\n\n**源码证据**：`ItemSpread:_TrySpread`（约 896 行）、`CheckSpreadPosAndAuto`（847 行）、`_TryAutoSpread`（798 行）、`MainBoardModel:FindSpreadPosition`（230 行）、`BaseItemLayerModel:FindEmptyPositionInSpreadOrder`（解码源码 25-38 行）、`FindRandomPosition`（解码源码 99-108 行）、`Table.ListRandomSelectOne`（解码源码 95-100 行）。"),
        "position/recoverable_detail.md": ("可恢复落点的具体算法", "手动点击仍由 `CheckSpreadPosAndAuto` 调用 `FindEmptyPositionInSpreadOrder`，算法是从母体坐标向外扩大的方形环扫描；“可恢复”只影响 `IsDisposable()`、次数耗尽和恢复计时，不改变手动落点函数。自动产出才走 `FindEmptyPositionInCircleOrder`：按 `dir=1..8` 检查母体八个相邻格，先通过 `PositionIsValid` 再检查为空，返回第一个空位；八邻域全部占用时返回 nil。"),
        "position/auto_detail.md": ("自动产出与缓存的具体条件", "`Update` 只有在 `m_auto==1` 时进入 while 循环；每轮 `_TryAutoSpread` 先要求 `m_itemRestNumber != 0` 且 `m_state==Opened`。落点由 `FindSpreadPosition` 决定：一次性母体调用全盘 `FindRandomPosition`，可恢复母体调用八邻域圆周顺序。无位置时，仅当 `IsDisposable()`、`m_weightType==Decremental`、棋盘实现 `CacheItemFromSpread` 且 `AutoSpreadToCache` 服务端开关为真才缓存剩余代码；缓存后 `m_spreadCount += #remainTypes`，`EmptySpreadCount` 将次数和 Decremental 权重清空。"),
        "position/full_detail.md": ("棋盘满失败的具体副作用", "手动路径的落点函数返回 nil 后立即调用 `_NotifySpreadFailed(BoardFull)`，不调用 `GenerateItemCode`、`SpreadCostEnergy`、`SpreadItem` 或 `CosetRestNumber`。通知函数发送棋盘事件 `BoardEventType.SpreadFailed`、全局事件 `EEventType.SpreadFailed` 和 `VibrationHeavy`。自动路径棋盘满不发送这个主动点击失败链，而是让 `_TryAutoSpread` 返回 false；只有缓存条件全部满足时才转入 `CacheItemFromSpread`。"),
        "energy/cost_detail.md": ("能量需求布尔值的具体来源", "`CheckEnergy` 首先调用 `CostEnergy()`；它返回初始化时读入的 `m_costEnergy`（来自 `Spread_CostEnergy == 1`），但教程可由 `TutorialBoardHelper.GetForcedCostEnergy()` 覆盖。随后 `CanSupportBoostDisco()` 若当前主棋盘的 Disco 支持该母体，就把局部变量 `costEnergy` 强制设为 false。这个布尔值只控制后续是否扣能量，不跳过状态和落点检查。"),
        "energy/boost_detail.md": ("基础消耗和倍增比率", "需要能量时，`ItemSpread.GetCostEnergyNum(itemType)` 默认返回 `nCostNum=1,nEnergyBoostRatio=0`；若 `EnergyBoostModel:CanEnergyBoost(itemType)` 为真，则改读当前增益档的消耗和最大比率。这个最大消耗只用于 `HasEnoughEnergy` 的余额检查，并不等于最终扣除。`GenerateItemCode` 可能进一步改写比率，之后 `EnergyBoostModel.GetBoostCostNum(energyBoostRatio)` 才得到最终整数消耗。\n\n`SpreadCheckEnergyRatioAndCode(code,maxEnergyBoostRatio,bCanEnergyBoost)` 只有在比率大于 0、分支允许增益且代码不是特殊前缀时执行。它先把比率设为最大值；若棋盘能提供订单缺口图，就从 `i=0` 到最大比率检查同一链上更高等级：只要目标等级存在订单缺口，或在“已有数量减订单需求”后为奇数且仍在可升级范围，就把比率截断为当前 `i` 并停止。随后循环 `i=1..energyBoostRatio`，每次把代码替换为其 `MergedType`，所以一次点击最多沿合成链升级指定次数。服务端 `FishNetProduceSmart` 还可能针对生鱼链按二进制等级缺口替换为更合适的等级；该动态开关与实际命中标记为 `runtime-pending`。"),
        "energy/consume_detail.md": ("能量余额比较与扣除", "`CheckEnergy` 先用 `GetCostEnergyNum` 返回的最大档调用 `HasEnoughEnergy(boardModel:GetCostEnergyType(), maxCostCount)`；不足时设置 `popupBundleEnergyWindowForLackingEnergy=true`，发送 `BoardEventType.LackEnergy`，返回 false，次数和权重池都不变。通过时先把标记清 false，随后 `_TrySpread` 生成最终代码；`SpreadCostEnergy` 将棋盘能量类型映射为属性类型，按 `EnergyBoostModel.GetBoostCostNum(energyBoostRatio)` 调用 `PropertyDataManager:Consume(..., EBIType.SpreadItem, sourceCode)`，并记录实际扣除数。"),
        "output/fixed_detail.md": ("Fixed 的具体选择", "`_GenerateItemCode` 在 `m_weightType==Fixed` 时先检查 GeneratorBoost SmartProduce 或 Smart Buff；若智能产出返回代码，就直接采用并记录 `spreadType`。否则调用 `_FixedGenerateItemCode`，按 `ItemStateCollection` 状态或母体类型进入 `ItemFixedSpreadModel:GenerateItemCode`。105 的配置池为 `201×35、202×2、301×5`，总权重 42；Fixed 本身不在 `m_codeWeightPairs` 上扣权重，下一次仍使用同一配置。"),
        "output/decremental_detail.md": ("Decremental 的具体选择", "`m_weightType==Decremental` 时调用 `Table.ListWeightSelectOne(m_codeWeightPairs)`，按当前 `Weight` 总和做加权整数抽取；抽中后立即 `Weight -= 1`，减到 0 就 `table.remove`，并保存母体属性。因此候选池会在每次成功生成代码时变化，这是配置级的递减池；它与 Lucky 机会池是两个独立状态。自动缓存时，`GetAutoSpreadDecrementalRemainTypes` 会把每条剩余权重展开成代码列表。"),
        "output/order_detail.md": ("OrderItem 的具体选择", "`GetOrderItemCode` 先取当前订单缺口 `CalculateOrderCodeLackNumMap(false,true,false)`，读取订单加成缺口和 `OrderItemConfig.DiffScore`。每个缺口代码权重为 `min(DiffScore,300)`，处于 OrderBoost 的代码再乘 1000。先加权选一个目标订单代码并从候选表移除，再在 `m_codeWeightPairs` 中筛同链且等级低于该目标的代码，用 `ListRandomSelectOne` 均匀选具体产物；失败时尝试其它订单代码，最后回退到所有已解锁母体链。`CosetRestNumber` 对 OrderItem 使用选中配置项的 `Weight` 作为消耗次数。"),
        "output/chest_detail.md": ("ChestCustomItem 的具体选择", "`m_weightType==ChestCustomItem` 时调用 `RandomGenerateCodeHelper.GenerateChestCustomCodeRule(m_itemRestNumber,1,false)`；返回列表为空时使用错误兜底代码 `205` 并记录错误，正常时取列表第一个代码。随后读取 Slot 订单代码配置，把选中代码的 `DiffScore` 写为 `costCount`，因此次数消耗不是固定 1；测试模式会打印候选过程和最终代码。"),
        "output/smart_detail.md": ("SmartItem 的具体选择", "首次进入 SmartItem 时，以 `m_storageMaxNumber` 为分值上限遍历 Slot 订单代码配置，只保留 `DiffScore <= m_storageMaxNumber` 的代码，缓存为 `m_SmarOrderConfig`。之后调用 `SmartRewardHelper.GetCodesFor_ItemSpread(config, m_itemRestNumber, \"itemSpread\")[1]` 取得代码，以该代码的 DiffScore 作为 `costCount`（缺失时为 1）。它不是普通 `m_codeWeightPairs` 池。"),
        "lifecycle/count_detail.md": ("次数扣除、变换和销毁顺序", "`GenerateItemCode` 在普通路径内调用 `CosetRestNumber`：`m_spreadCount += 1`；若算法返回 `costCount` 就扣该值，否则一次性母体扣 `floor(2 ^ energyBoostRatio)`，可恢复母体调用 `EnergyBoostModel:NextEnergyBoostCostIndex`，OrderItem 查找选中代码的 `Weight`。扣减下限为 0，并调用 `UpdatePerSecond`、`StateChanged`、`SaveItemProperty`。成功落子后 `TryRemoveSelf` 先判断 `m_transformNumber == m_spreadCount`，成立则 `ItemTransform:Transform()` 并停止；否则若一次性母体次数为 0，移除母体并发送 `CollapseItem`；两者都不满足才尝试 CD Buff。"),
        "lifecycle/cooldown_detail.md": ("CD、加速和恢复结算", "`UpdatePerSecond` 在 Initializing、Opening，或 Opened 且（次数不足/储备为 0）且非一次性时写入服务器时间 `m_startTimer` 并保存属性。已有计时期间，`ItemAccelerateTime` 生效会修正计时起点；`GetTimerAmount()==1` 才调用 `_UpdateRecoveryState`。初始化/开启到期转 Opened；储备为 0 时先把储备和次数补满；普通恢复把次数补满并扣除相同数量储备，储备耗尽则继续以 `m_itemRecoveryDuration` 计时。加速费用按 `(1-timerAmount)*阶段SpeedUpCost` 向上取整且至少 1，`OnTimeSkip` 修改 `m_startTimer`、保存属性并记录 BI。"),
        "events/index.md": ("事件与后续影响总览", "事件阶段位于产出、扣能量、落子和母体状态更新之后；继续按资源事件、棋盘事件、活动/UI副作用阅读。事件不是另一个成功判定。"),
        "events/resource.md": ("资源与属性事件", "成功扣能量通过 `PropertyDataManager:Consume` 进入 `PropertyConsumed` 链，Lucky 和 Boost 模型可监听并更新统计。源码为 `SpreadCostEnergy`、`LuckyProduceModel:_OnPropertyConsumed`。"),
        "events/board.md": ("棋盘事件", "`BoardModel:SpreadItem` 写入新棋子和来源信息；成功后发送 `VibrationLight`，母体状态通过 `ItemSpreadEventType.StateChanged` 通知视图。"),
        "events/side_effects.md": ("活动、日志和 UI 副作用", "产出后记录 EnergyBoost 比率调整数据，可能进入 Disco、GeneratorBoost、SmartProduce 或测试日志。副作用可能改变下一次点击状态，但不改变本次主流程顺序。"),
        "events/resource_detail.md": ("资源事件的具体监听链", "通过能量检查后，`SpreadCostEnergy` 将棋盘能量类型映射为属性类型，调用 `PropertyDataManager:Consume(propertyType,costCount,EBIType.SpreadItem,sourceCode)`。这一步在 `GenerateItemCode` 之后、`BaseBoardModel:SpreadItem` 之前；`RecordBoostRatioAdjustData` 同时记录最终能量增益比率、产出类型、是否消耗能量和母体类型。属性系统的全局监听与上传目标在当前静态快照中未能确认，不能写成必然回调。"),
        "events/board_detail.md": ("棋盘事件的具体写入顺序", "`BaseBoardModel:SpreadItem` 先调用 `GenerateItem(newItemPosition,newItemCode,...)` 创建并放入目标格，再构造 `{Source,New,EnergyBoostRatio,CostEnergy,BoardSpreadType}` 发送 `BoardEventType.SpreadItem`。`MainBoardModel:SpreadItem` 随后派发 `EEventType.ItemSpread`；若 `logSpread` 则组装 `eb/md/st/oriEle/sc/ab` 写 `BIManager:LogSpread`，最后检查棋盘满。点击链再发送 `VibrationLight`，发生在落子之后。"),
        "events/side_effects_detail.md": ("副作用的具体字段", "`GenerateItemCode` 可能被 SmartProduce、Disco、FishNetProduceSmart 改写，并返回 `spreadType`、原始代码和扩展场景；`DealActivityLimit` 在 Disco 生效时把最终 `costCount` 改为 0。成功落子时 BI 扩展字段包括 `eb`（最终能量增益比率）、`md`（能量增益类型）、`st`（产出来源类型）、`oriEle`（原始代码）和 `sc`（扩展场景）；GeneratorBoost 活动文本写入 `ab`。动态活动实例仍标为 `runtime-pending`。"),
        "overrides/activity_detail.md": ("活动改写的具体顺序", "`GenerateItemCode` 先调用 `CheckLuckyProduce`；教程棋盘和 Disco 支持时直接跳过 Lucky。Lucky 命中后调用 `TryGenerateLuckyItem`，按活动调整后的最大增益档沿 `MergedType` 升级并立即返回。Lucky 未命中且 Disco 支持时调用 `TryGenerateDiscoItem`：有直接代码返回 `(code, Disco, 0)`；没有直接代码则继续普通生成，但把 `spreadType` 设为 Disco、最大增益档设为 3。普通代码经 `SpreadCheckEnergyRatioAndCode` 后，再调用 `DealActivityLimit`；该函数可由 Disco 再次替换代码和倍率，并把 `costCount` 归零。"),
        "overrides/boost_detail.md": ("链升级和 FishNet 具体算法", "`SpreadCheckEnergyRatioAndCode` 先把 `energyBoostRatio` 设为最大档。若棋盘提供订单缺口图，就按 `i=0..maxRatio` 检查同链更高等级：目标等级存在缺口，或目标等级库存减订单需求后为正奇数且仍在允许范围时，把比率截断为 `i` 并停止。之后按 `i=1..energyBoostRatio` 重复读取当前代码的 `MergedType`，得到最终代码。服务端 `FishNetProduceSmart` 打开且代码属于 RwaFish 时，再把各等级按 `2^(level-1)` 换算为一级鱼数量；当缺口是一个严格小于满链的二次幂，并且目标等级位于 `origin+1` 到 `origin+3` 范围内，才替换为匹配等级并记录 `FishNetProduceSmart` 场景。"),
        "overrides/safety_detail.md": ("次数与储备上限修正", "`SafeSpreadItem` 在 `_GenerateItemCode` 前执行。若 `m_itemRestNumber > m_itemMaxNumber`，记录 `{rest,max}` 的 `ItemRestNumberOverflowError` 后截回最大值；若储备存在且 `m_storageRestNumber > m_storageMaxNumber`，同样记录 `StorageRestNumberOverflowError` 并截回。它不改变 `m_spreadCount` 或权重。自动缓存的另一条路径随后调用 `EmptySpreadCount`：次数、储备都置零，Decremental 的 `m_codeWeightPairs` 置为空表，更新计时、派发 `StateChanged` 并保存属性。"),
    }
    for rel, (title, body) in fourth_pages.items():
        clean_body = textwrap.dedent(body).strip()
        write(
            "operations/generator/" + rel,
            f"# {title}\n\n{clean_body}\n\n**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。\n",
        )

    # Keep the algorithm page genuinely bottom-level: it describes the two
    # position algorithms, their candidate construction, and the exact point
    # where the rest of the click chain is allowed to continue.
    write("operations/generator/position/disposable_detail.md", """# 一次性落点的具体算法

## 1. 手动路径：`FindEmptyPositionInSpreadOrder`

`CheckSpreadPosAndAuto` 把母体坐标作为 `centerPosition` 传给 `FindEmptyPositionInSpreadOrder`。实现先令 `currentPosition = centerPosition`，令 `maxTiles = max(HorizontalTiles, VerticalTiles)`；对 `i = 1 .. maxTiles - 1`，先把当前位置移动到本层左下角方向的 `(-1,-1)`，得到边长为 `2*i` 的方形环，再按四个方向依次走 `2*i` 格。每走一格先调用 `PositionIsValid`，越界格跳过；合法格再调用 `GetItem(position)`，只有返回 `nil` 才是候选格。遇到第一个合法空位立即返回。

所有环都没有空位时返回传入的 `openedPosition`；本调用没有传该参数，因此最终是 `nil`。这一步没有随机接口，也没有写棋盘，只产生一个待使用坐标。

## 2. 自动路径：分流和循环

`Update` 仅在 `IsAutoSpread()`（`m_auto == 1`）为真时进入循环。每轮 `_TryAutoSpread` 先要求 `m_itemRestNumber ~= 0` 且 `m_state == Opened`，再经 `_GetAutoSpreadPosition → MainBoardModel:FindSpreadPosition` 选择位置。`FindSpreadPosition` 的分支是：一次性母体（`IsDisposable() == true`）调用 `FindRandomPosition`；可恢复母体调用八邻域 `FindEmptyPositionInCircleOrder`。位置成功后才调用 `GenerateItemCode` 和 `SpreadItem` 写入棋盘。

## 3. `FindRandomPosition`：候选表和随机范围

底层每次调用都新建局部数组 `positions = {}`。`GetValidPositionIterator()` 按棋盘坐标遍历：从 `(1,1)` 开始，x 递增，超过棋盘宽度后换到下一行 y。每个位置读取 `GetItem`；空位才插入 `positions`，被占用和无效格都不进入候选。

- 候选数为 `N = #positions`；`N == 0` 时 `Table.ListRandomSelectOne` 返回 `nil`。
- `N > 0` 时调用 `MathUtil.Random(N)`，本版本接口返回整数 `1..N`（含两端），用作数组下标；每个当前空位概率均为 `1/N`。
- 函数不保存历史位置、不删除已选项，也不在返回前写入棋盘。下一轮重新扫描当时的棋盘状态，因此在“抽样后尚未落子”的窗口内可以再次选中同一格；落子成功后该格才从下一轮候选表消失。这是当前实现的**有放回抽样语义**，与 Decremental 产物权重池的扣减/移除不是同一件事。

## 4. 自动满盘和缓存

位置为空时，`_TryAutoSpread` 计算 `bAllowAutoSpreadToCache`。必须同时满足 `IsDisposable()`、`m_weightType == Decremental`、棋盘实现 `CacheItemFromSpread`，以及 `IsServerControlOpen(AutoSpreadToCache)`。条件不全满足就返回 `false`，不会消耗次数。

条件全部满足时，调用 `GetAutoSpreadDecrementalRemainTypes()`，把当前每个 `{Code, Weight}` 展开为重复代码数组；写入 `CacheItemFromSpread`，将 `m_spreadCount` 增加数组长度，再调用 `EmptySpreadCount` 把次数、储备和 Decremental 权重清空，并保存属性、派发状态变化。

## 5. 失败和销毁的精确边界

`CheckSpreadPosAndAuto` 返回位置后，`_TrySpread` 才调用 `CheckEnergy`。若棋盘满，`_NotifySpreadFailed` 同时派发 `BoardEventType.SpreadFailed`、`EEventType.SpreadFailed` 和 `VibrationHeavy`；后续 `GenerateItemCode`、`SpreadCostEnergy`、`SpreadItem`、`CosetRestNumber` 都不会发生。

成功落子后，点击链才执行 `TryRemoveSelf`：一次性母体的 `m_itemRestNumber == 0` 时调用 `RemoveItem` 并派发 `CollapseItem`。所以母体不会在“准备找位置”时删除，而是在产物已写入棋盘、次数已扣减后才销毁。

## 6. 落点成功后，哪些逻辑才会继续

落点函数只负责坐标，调用链的后续顺序仍然固定：

1. `CheckEnergy` 读取 `Spread_CostEnergy`；一次性样本 `main_t_chest_new_1` 的值为 `0`，所以这条样本不扣能量，但仍然必须先有合法空位。
2. `GenerateItemCode` 先尝试 Lucky，再尝试 Disco，最后按 `Spread_WeightType` 进入 Fixed、Decremental、OrderItem、ChestCustomItem 或 SmartItem。一次性落点算法不改变产物池；它只把 `position` 传给后续写入。
3. 普通 Decremental 分支调用 `Table.ListWeightSelectOne(m_codeWeightPairs)`，选中后立即把对应 `Weight` 减 1，减到 0 就从 `m_codeWeightPairs` 删除，并保存母体属性。这是产物权重池的无放回式耗尽过程，和自动落点的有放回位置抽样是两套独立状态。
4. `CosetRestNumber` 先把 `m_spreadCount` 加 1；一次性母体默认扣 `floor(2 ^ energyBoostRatio)` 次数，结果下限为 0。之后 `SpreadItem` 才把新棋子写入已选位置。
5. 写入成功后 `TryRemoveSelf` 检查变换次数，再检查一次性剩余次数是否为 0；满足后删除母体并发送 `CollapseItem`，否则才有机会进入 CD Buff。

因此复刻时必须保存两类不同的状态：`m_codeWeightPairs`（产物权重剩余）和棋盘占用集合（位置候选）。前者会因抽到某个代码而扣减，后者只在棋子真正落盘后改变。

## 7. 可直接复刻的伪代码

```text
function manual_position(board, center):
    for ring = 1 .. max(board.width, board.height)-1:
        p = center + (-ring, -ring)
        for direction in [right, up, left, down]:
            repeat 2*ring times:
                if board.valid(p) and board.item_at(p) == nil:
                    return p
                p = step(p, direction)
    return nil

function random_position(board):
    candidates = [p for p in board.valid_positions() if board.item_at(p) == nil]
    if candidates is empty: return nil
    return candidates[random_integer_inclusive(1, len(candidates))]

function auto_spread_once(generator):
    if generator.rest == 0 or generator.state != Opened: return false
    p = random_position(board) if generator.disposable else circle_position(board, generator.position)
    if p is nil: maybe_cache_remaining_decremental(generator); return false
    code = generate_code()
    board.spread_item(generator, p, code)
    return true
```

**底层证据位置**：`ItemSpread.lua` 的 `CheckSpreadPosAndAuto`（847-862）、`_TryAutoSpread`（798-828）、`_TrySpread`（864-928）、`TryRemoveSelf`（930-944）；`MainBoardModel.lua` 的 `FindSpreadPosition`（230-237）；解码 `BaseItemLayerModel` 的 `FindEmptyPositionInSpreadOrder` 和 `FindRandomPosition`；`Table.ListRandomSelectOne`。`MathUtil.Random` 的种子来源、实际棋盘尺寸和服务端 `AutoSpreadToCache` 开关仍是 `runtime-pending`，不能从客户端静态代码推出。
""")

    # Give every third-level mechanism its own index page.  MkDocs only makes a
    # tree label clickable when the section has an index document; the previous
    # flat `mechanism.md` + `mechanism_detail.md` layout made the label expand
    # without opening the mechanism explanation.
    branch_pages = {
        "entry": ("entry.md", "entry_detail.md"),
        "state/initializing": ("state/initializing.md", "state/initializing_detail.md"),
        "state/closed": ("state/closed.md", "state/closed_detail.md"),
        "state/opening": ("state/opening.md", "state/opening_detail.md"),
        "state/opened": ("state/opened.md", "state/opened_detail.md"),
        "state/timing": ("state/timing.md", "state/timing_detail.md"),
        "state/model": ("state/model.md", "state/model_detail.md"),
        "position/disposable": ("position/disposable.md", "position/disposable_detail.md"),
        "position/recoverable": ("position/recoverable.md", "position/recoverable_detail.md"),
        "position/auto": ("position/auto.md", "position/auto_detail.md"),
        "position/full": ("position/full.md", "position/full_detail.md"),
        "energy/cost": ("energy/cost.md", "energy/cost_detail.md"),
        "energy/boost": ("energy/boost.md", "energy/boost_detail.md"),
        "energy/consume": ("energy/consume.md", "energy/consume_detail.md"),
        "output/fixed": ("output/fixed.md", "output/fixed_detail.md"),
        "output/decremental": ("output/decremental.md", "output/decremental_detail.md"),
        "output/order": ("output/order.md", "output/order_detail.md"),
        "output/chest": ("output/chest.md", "output/chest_detail.md"),
        "output/smart": ("output/smart.md", "output/smart_detail.md"),
        "lifecycle/count": ("lifecycle/count.md", "lifecycle/count_detail.md"),
        "lifecycle/cooldown": ("lifecycle/cooldown.md", "lifecycle/cooldown_detail.md"),
        "events/resource": ("events/resource.md", "events/resource_detail.md"),
        "events/board": ("events/board.md", "events/board_detail.md"),
        "events/side_effects": ("events/side_effects.md", "events/side_effects_detail.md"),
        "overrides/activity": ("overrides/activity.md", "overrides/activity_detail.md"),
        "overrides/boost": ("overrides/boost.md", "overrides/boost_detail.md"),
        "overrides/safety": ("overrides/safety.md", "overrides/safety_detail.md"),
    }

    def clone_without_case(source: str, target: str) -> None:
        source_text = (DOCS / source).read_text(encoding="utf-8")
        case_marker = "\n\n---\n\n## 贯穿案例"
        body = source_text.split(case_marker, 1)[0]
        write(target, body)

    for stem, (overview, detail) in branch_pages.items():
        clone_without_case("operations/generator/" + overview,
                           "operations/generator/" + stem + "/index.md")
        clone_without_case("operations/generator/" + detail,
                           "operations/generator/" + stem + "/detail.md")
    clone_without_case("operations/generator/events.md", "operations/generator/events/index.md")

    # The flat files are staging inputs for the directory pages above. Remove
    # them before the build so an old URL cannot appear as a second, unindexed
    # version of the same mechanism.
    legacy_pages = {"operations/generator/events.md"}
    legacy_pages.update("operations/generator/" + pair for pair in
                        (path for pair in branch_pages.values() for path in pair))
    for rel in legacy_pages:
        legacy = DOCS / rel
        if legacy.exists():
            legacy.unlink()

    write("operations/merge/index.md", """# 棋子拖拽与合成

    入口 `MainBoardModel:DragItem` 的优先级是：非法目标、源身份、空位移动、特殊影响、普通合成、吞噬、不可移动目标、交换。

    - [拖拽分派与移动](dispatch/index.md)
    - [普通合成](normal/index.md)
    - [特殊棋子与吞噬](special/index.md)
    - [合成副产物](effects/index.md)
    """)
    write("operations/merge/dispatch.md", """# 拖拽分派与移动

    ```text
    目标非法 -> 恢复原位
    源身份不符 -> 恢复原位
    目标为空 -> 移动并发送 ItemMoveEnd
    CanItemAffect -> LevelUp / LevelDown
    CanItemMerge -> 普通合成
    ItemSwallow -> 吞噬
    目标不可移动 -> 恢复原位
    否则 -> 交换
    ```

    **源码**：`MainBoardModel:DragItem`、`CanItemMerge`。每个恢复路径需要独立回放验证。
    """)
    write("operations/merge/dispatch_detail.md", """# 分支顺序与移动交换算法

    `DragItem` 先用 `PositionIsValid` 检查目标格，再从源坐标重新读取棋子并确认仍是拖动对象；这是防止视图过期或重复拖动覆盖棋盘的身份门禁。随后按以下顺序短路：目标为空则移动；有目标时先尝试 `CanItemAffect`（升级/降级），再尝试 `CanItemMerge`，再尝试 `ItemSwallow:CanSwallow`，目标不可移动则复位，否则交换。

    空位移动的原子写入是 `_SetItem(source,nil,false)` → `_SetItem(target,item,false)` → `_LogMove` → `SetPosition` → `_UpdateAccelerate` → `ItemMoveEnd`。交换则清空源格、写入拖入物、写回原目标物，分别记录两条 Move 日志，再更新两个位置；所有 `_SetItem` 都传 `false`，所以移动/交换不在中间刷新订单状态。

    **源码**：`MainBoardModel:DragItem`、`BaseBoardModel:_SetItem`、`MainBoardModel:_UpdateAccelerate`。`CanItemMove` 会拒绝纸箱、蜘蛛网、锁定组件，吞噬棋子还必须允许点击；这些资格检查不能简化成“目标为空/不为空”。
    """)
    write("operations/merge/normal.md", """# 普通合成

    `CanItemMerge` 要求类型相同、至少一方有 `MergedType`，且已使用的一次性箱子不能合成。`_DoMergeItem` 将目标替换为 `MergedType`，移除源棋子，保存新属性，发送 `BoardEventType.MergeItem` 和 `EEventType.ItemMerged`。

    **配表**：`ItemModelConfig.MergedType`，当前 370 行。**源码**：`BaseBoardModel:_DoMergeItem`、`MainBoardModel:_DoMergeItem`。活动监听器静态已定位，动态对象身份 `runtime-pending`。
    """)
    write("operations/merge/normal_detail.md", """# 合成原子操作与事件顺序

    基础合成先 `RemoveItem(item,false)` 删除拖入物，再决定输出代码：普通物品取拖入物的 `MergedType`，临时物品取目标物的 `MergedType`。生成前查询是否首次解锁，然后 `ReplaceItem` 删除目标并在原目标位置创建新棋子、写入 ItemManager 和棋盘。之后构造包含 Source、Target、New、原始 code 和首次解锁标记的 `MergeItem` 消息，依次发送 `BoardEventType.MergeItem` 与 `EEventType.ItemMerged`，最后震动四个正交邻格并发送 `ItemShocked`。

    MainBoardModel 后处理再按 `TempItem` → `CardItem` → `EnergyBubble` → 普通气泡的顺序寻找一种主副产物；任何一种成功都会阻止后续三种。金币检查独立于这个互斥标记，仍可能在同一次合成后生成。最后调用 `CheckMoreUpload`。

    **证据**：`BaseBoardModel:_DoMergeItem`、`MainBoardModel:_DoMergeItem`。`MergedType` 是实例初始化时从 `ItemModelConfig` 复制的直接字段，不是运行时按等级推导。
    """)
    write("operations/merge/special.md", """# 特殊棋子与吞噬

    LevelUp 将目标替换为 `MergedType`；LevelDown 拆成两个前一级棋子；ItemSwallow 按两个 `Swallow_Weight` 生成目标代码并保存进度，两个目标数量都达标才 Transform；吞噬扫描按有效棋盘位置顺序，不随机打乱。

    **配表**：`Swallow_Weight`、吞噬数量、Transform 字段。**源码**：[ItemSwallow.lua](/C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSwallow.lua)、`ItemTransform`。
    """)
    write("operations/merge/special_detail.md", """# 升级、降级和吞噬的具体算法

    特殊棋子在普通合成前处理。LevelUp 确认窗口通过二次 `CanItemAffect` 校验后，删除升级棋、用目标的 `MergedType` 替换目标并发送合成/邻格震动事件；确认等待期间拖入物先复位。LevelDown 对普通目标读取目标链的前一级，消耗剪刀次数，删除目标并在目标位置和扩散扫描得到的第二空位各生成一个前一级；两把剪刀相遇时删除两者，生成一把新剪刀，并把两者剩余使用次数相加。

    吞噬资格要求两个配置槽中存在相同 code 且该槽 `Swallowed < Count`。成功后先增加对应槽进度并保存目标属性，再移除拖入物、发送 `SwallowItem` 事件和 BI；两个槽都达到 Count 才 `ItemTransform:Transform`。目标 code 的选择不是每次独立随机：`ItemFixedSwallowModel` 把每槽权重展开为 `[1..W]`，用从 W 到 1 的 Fisher-Yates 洗牌持久化序列，取出序列头并按累计权重映射 code，消费后立即写回剩余序列；序列耗尽才重建。因此同一 code 可按 Weight 出现多次，但在一轮序列内属于无放回抽样。

    **源码**：`MainBoardModel:_AffectItem`、`ItemSwallow:CanSwallow`、`ItemSwallow:Swallow`、`ItemFixedSwallowModel` 反汇编。权重数值以当前配置快照为准。
    """)
    write("operations/merge/effects/index.md", """# 合成副产物

    顺序是 `TempItem.GenerateType` → `CardItem.TryGenerateItem` → `EnergyBubble.CanSpreadEnergyBubble` → `_TrySpreadBubbleByMerge` → 独立金币检查。前四类用 `hasCreateItem` 互斥，金币检查在之后单独执行，均需有效空位。

    - [普通气泡](bubble.md)
    - [卡牌、能量气泡和临时棋子](activity.md)
    - [金币](coin.md)
    """)
    write("operations/merge/effects/bubble.md", """# 普通气泡

    ```text
    功能关闭 -> 结束
    p = newItem.BubbleChance
    已有相同 inner bubble -> 取消
    购买加成或订单加成 -> p = 100
    否则依次乘高等级衰减、订单缺口衰减、BubbleDecrease 全局衰减
    p = max(p,1); 测试开关 -> p=100
    r = Random(100); p >= r -> 生成 Bubble + newItem.Type
    ```

    **配表**：`ItemModelConfig.BubbleChance`，当前 138 行大于 0；服务端 BubbleDecrease 和购买/订单修正。**源码**：`_TrySpreadBubbleByMerge`。基础顺序 `source-confirmed`，服务端值 `runtime-pending`。
    """)
    write("operations/merge/effects/bubble_detail.md", """# 概率修正与随机判定

    棋盘满或气泡功能关闭时不调用随机数；已有相同 inner code 的气泡也直接取消。否则先读新棋子的 `BubbleChance`，购买加成或订单加成成立时把概率置为 100%；普通路径依次乘订单衰减、高等级气泡链衰减和 `BubbleDecreaseModel` 的全局倍率，最后把概率下限限制为 1。测试开关 `TestBubbleMustSpread` 在随机前强制 100%。

    最终调用 `MathUtil.Random(100)`，源码实现为 `floor(math.random()*100)+1`，取值 1..100（含端点）；条件是 `p >= R`。通过后把新棋子 code 加上 Bubble 前缀，并使用 `FindEmptyPositionInSpreadOrder` 找气泡落点，再派发 `BubbleSpread`。这是独立阈值判定，不是候选池抽样，也不保存历史抽样状态。

    **源码**：`MainBoardModel:_TrySpreadBubbleByMerge`、`_GetDecreaseBubbleChanceRatio`、`_GetDecreaseBubbleChanceRatio2`、`MathUtil.Random`。
    """)
    write("operations/merge/effects/activity.md", """# 卡牌、能量气泡和临时棋子

    Temp 先于 Card，Card 先于 EnergyBubble；某一步创建成功后，后续两类不再创建，棋盘满时跳过。

    **源码**：`MainBoardModel:_DoMergeItem` 及 Temp/Card/EnergyBubble 调用。**配置**：对应类型字段。活动开关、动态对象身份和真实概率 `runtime-pending`。
    """)
    write("operations/merge/effects/activity_detail.md", """# 互斥顺序与落点算法

    合成完成且棋盘未满时，先调用 `TempItem:GenerateType`；成功就从合成物周围按 `FindEmptyPositionInSpreadOrder` 生成临时棋子并停止。没有临时棋子才调用 `CardItem:TryGenerateItem`，成功后生成卡牌并派发 `CardItemGenerate`。再没有卡牌才检查 `EnergyBubble:CanSpreadEnergyBubble` 并按其 `GetBubbleInfo().Code` 生成。前三类都通过 `hasCreateItem` 互斥，普通气泡位于其后。

    每一步都必须有合法空位；满盘会跳过该副产物，不会把它改成随机落点。金币不受 `hasCreateItem` 互斥限制，独立在之后检查。
    """)
    write("operations/merge/effects/coin.md", """# 金币

    合成链等级达到 `SystemConfig.SpreadCoinMinChainLevel` 后进入金币检查。金币检查位于互斥副产物流程之后，独立判断，但同样需要空位。

    **配表**：`SystemConfig.SpreadCoinMinChainLevel`。**源码**：`MainBoardModel:_DoMergeItem` 金币分支。活动修正 `runtime-pending`。
    """)
    write("operations/merge/effects/coin_detail.md", """# 合成等级与金币落点

    主副产物流程完成后，若新棋子的合成链等级达到 `SystemConfig.SpreadCoinMinChainLevel` 且棋盘仍有空位，独立寻找扩散顺序中的第一个空格并生成 `ItemType.Coin01`。金币不是四类主副产物的竞争候选，不会因为临时棋子、卡牌或气泡已经生成而自动取消；只有棋盘无有效落点才跳过。
    """)

    write("operations/orders/index.md", """# 订单提交

    UI 入口 `BaseOrderCell:OnGoButtonClicked` 先获取代码数量并调用 `BaseOrder:CanDeliver`；不足时进入确认流程，足够时调用 `MainBoardModel:FinishOrder`。

    - [可交付判断](check/index.md)
    - [库存确认与补交](inventory/index.md)
    - [奖励结算](rewards/index.md)
    - [需求扣除](remove/index.md)
    - [特殊与分支订单](special/index.md)
    - [订单完成、补位与同步](finish/index.md)
    - [订单创建与配置选择](creation/index.md)
    """)
    write("operations/orders/check.md", """# 可交付判断

    `CanDeliver` 按需求出现位置计数，不做集合去重；`[203,203]` 需要两份 203。按钮调用 `GetCodeCountMap(true,false,false)` 后进入判断，不足时展示确认窗口，取消不会扣除。

    **配表**：订单需求来自 `OrderItemConfig` 和当前订单对象。**源码**：`BaseOrderCell:OnGoButtonClicked`、`BaseOrder:CanDeliver`。重复需求语义 `source-confirmed`，确认窗口时序 `runtime-pending`。
    """)
    write("operations/orders/check_detail.md", """# 重复需求与计数来源

    普通订单按钮先要求 `m_bGoButtonEnabled`，再调用 `GetCodeCountMap(true,false,false)`；这三个参数的含义是只计棋盘，不计缓存和仓库。`BaseOrder:CanDeliver` 按需求原始顺序逐项检查：第 i 项先统计它在前 i 项中出现了几次，再要求代码数量至少达到这个序号。因此 `[203,203,204]` 要求 203 两个、204 一个，不能转成去重集合。

    棋盘不足时入口打开仓库确认窗口；普通成功路径才进入 `FinishOrder`。显示层的 `CanDeliver` 状态只来自订单状态刷新，不能当作扣除已经完成的证明。

    **源码**：`BaseOrderCell:OnGoButtonClicked`、`BaseOrder:CanDeliver`、`BaseBoardModel:GetCodeCountMap`。重复需求和入口计数口径为 `source-confirmed`。
    """)
    write("operations/orders/inventory.md", """# 库存确认与补交

    棋盘计数不足时，`BaseOrderCell:OnGoButtonClicked` 不会直接完成订单，而是打开 `UseInventoryItemConfirmWindow`，并传入 `boardModel` 与订单对象。这个页面代表“玩家决定是否把仓库物品用于订单”的中层机制；确认窗口本身不是奖励或扣除实现。

    入口已确认，窗口内的确认、取消、仓库扣除及再次进入 `FinishOrder` 尚未在当前静态材料中闭合，因此后续步骤标为 `runtime-pending`，不能把“打开窗口”解释为已经消耗仓库。

    **源码**：`BaseOrderCell:OnGoButtonClicked`。**证据**：窗口调用 `source-confirmed`；确认回调和服务端失败/重试 `runtime-pending`。
    """)
    write("operations/orders/inventory_detail.md", """# 确认窗口的边界与待追踪调用

    点击入口始终以 `GetCodeCountMap(true,false,false)` 检查棋盘，不计缓存和仓库。只有 `CanDeliver` 返回假才打开 `UseInventoryItemConfirmWindow`；取消路径在入口没有扣除、奖励或状态写入。

    需要继续从窗口 prefab 对应 Lua 入口追踪：确认按钮是否将缺口映射转换为仓库索引、是否先删除仓库物品再重新调用 `MainBoardModel:FinishOrder`、取消/关闭是否只销毁窗口、网络失败是否回滚。当前报告不填入推测实现。

    **源码证据**：`Board_View_Order_BaseOrderCell.lua:22-33`；**证据状态**：入口 `source-confirmed`，窗口内部调用链 `runtime-pending`。
    """)
    write("operations/orders/rewards.md", """# 奖励结算

    顺序是特殊/分支订单处理 → 主奖励 → 亲密度礼物 → Buff 奖励 → OrderBoost/CookingFrenzy/ChestCustomer 副作用 → 需求移除 → 延迟奖励。

    **配表**：订单奖励、亲密度、Buff、OrderBoost、CookingFrenzy。**源码**：`MainBoardModel:FinishOrder`、`GetOrderRewardByFinishOrder`。服务端奖励覆盖和失败回滚 `runtime-pending`。
    """)
    write("operations/orders/rewards_detail.md", """# 奖励、价格和活动副作用顺序

    普通订单完成时先读取并深拷贝完成瞬间的奖励快照，再依次发放主奖励、亲密度礼物、Buff 奖励；之后处理 OrderBoost 分数/标记，写入订单 Finished 状态，才扣需求棋子。扣除之后再尝试 CookingFrenzy、ChestCustomer 副作用和延迟奖励。

    `MainOrder:GetPrice` 按需求顺序读取 `OrderItemConfig.Price` 并累加，重复需求重复计价；基准订单在配置有 `RecommendedPrice` 时使用推荐价。金币数量为 `ceil(price * multiplier)`，BuffGold 将倍率设为 2；特定亲密度订单可能改发其它奖励属性。奖励发放在需求扣除之前，源码没有事务回滚，扣除异常只记录错误。

    **源码**：`MainBoardModel:FinishOrder`、`MainOrder:GetPrice`、`MainOrder:GetRewards`、`GetOrderRewardByFinishOrder`。活动实际奖励值标记为 `runtime-pending`。
    """)
    write("operations/orders/rewards_sources.md", """# 奖励来源与配置字段

    `MainOrder:GetRewards` 按固定代码顺序追加奖励：主装饰活动代币、FloatRace 分数、TimedOrder 专属奖励/相册跳过标记、Album 奖励（相册 Buff 可翻倍）、Avenue、Upward、Road、HitBricks、Ring、Combo、`ActivityModuleManager:GetRewardsByOrder`、ChestCustomer 延迟奖励标记，最后才追加 Gold 或 BakeOutToken。

    价格逐条读取 `OrderItemConfig.Price`；基准订单若存在 `RecommendedPrice` 则使用该字段。涉及的配置字段包括 `Code`、`Price`、`RecommendedPrice`、`DiffScore`、`RecommendedNumber`、活动 token property type，以及各活动模型自己的 `GetAddScoreByOrder` 配置。缺失 Code 配置时记录 `cfg_err` 并把价格返回为 0。

    `GetOrderRewardByFinishOrder` 将 `ChestCustomerModel.RewardKey` 前缀奖励移到延迟映射；它们在需求扣除后另行发放。奖励快照在完成前深拷贝，订单完成后从 `m_cacheRewards` 读取。

    **源码**：`Board_Model_Order_MainOrder.lua:106-271`、`Board_Model_Board_MainBoardModel.lua:1109-1144`。奖励具体数值受活动状态影响，标为 `runtime-pending`。
    """)
    write("operations/orders/rewards_sources_detail.md", """# 奖励来源的底层追加顺序

    复刻时应保持 `MainOrder:GetRewards` 的追加顺序，因为 `GetOrderRewardByFinishOrder` 会按奖励属性前缀再拆成即时和延迟两组。主装饰、FloatRace、Album、Avenue、Upward、Road、HitBricks、Ring、Combo 等活动都通过当前活动模型查询订单；返回 `nil` 或非正值时不追加。`ActivityModuleManager:GetRewardsByOrder` 的数组则整体追加，不应当按普通货币合并。

    金币分支最后执行：`_HasGoldReward` 过滤亲密度随机订单，`GetFirstRewardPropertyType` 在 BakeOut 可领取代币时返回 BakeOutToken，否则返回 Gold，数量为 `ceil(GetPrice() * (BuffGold and 2 or 1))`，并写入 `Crypt.CryptCurrency`。缺少 `OrderItemConfig` 代码时 `GetPrice` 记录 `cfg_err` 并返回 0。

    **源码**：`Board_Model_Order_MainOrder.lua:136-254`、`257-271`、`337-342`；**证据**：追加顺序和公式 `source-confirmed`，活动模型具体数值 `runtime-pending`。
    """)
    write("operations/orders/remove.md", """# 需求扣除

    每条需求先按棋盘有效位置顺序找相同代码；找不到才扫描仓库；两处都找不到记录 `FinishOrderRemoveItemError`。每项之后重新统计代码数量并 `UpdateOrderState`。

    **状态**：`RemovedFromBoard`、`RemovedFromInventory`、订单代码计数。**源码**：`MainBoardModel:RemoveOrderRequirementItems`。**配置**：订单需求代码和数量。
    """)
    write("operations/orders/remove_detail.md", """# 棋盘优先与仓库兜底

    `RemoveOrderRequirementItems` 按需求原始顺序逐项处理。每项先用 `GetValidPositionIterator` 扫描棋盘，遇到第一个 code 相同的棋子就 `RemoveItem(item,false)`；棋盘没有匹配项时才按仓库索引从 1 开始扫描并删除第一个匹配物。每项删除后立即重新 `CountItemsCode` 和 `UpdateOrderState`，所以重复需求会看到前一项已经扣除后的数量。

    两处都找不到时记录 `FinishOrderRemoveItemError`，不会抛异常，也没有静态证据表明前面已发奖励会回滚。返回结果分别记录 `RemovedFromBoard` 对象列表和 `RemovedFromInventory` 代码列表。

    **源码**：`MainBoardModel:RemoveOrderRequirementItems`、`GetValidPositionIterator`、`GetCodeCountMap`。棋盘/仓库混合扣除的运行时动画和网络时序仍需回放确认。
    """)
    write("operations/orders/special.md", """# 特殊与分支订单

    `MainBoardModel:FinishOrder` 先检查 `order:GetInnerType()`。`Special` 进入 `_FinishSpecialOrder`，`Branch` 进入 `_FinishBranchOrder`，两者都会立即返回，不执行普通订单的奖励快照、亲密度礼物和逐项需求扣除链。

    特殊订单按 `OrderSpecialConfig` 的 `Requirement1..3` 链和 `GeneratorChain` 批量清除棋盘相关物品，发放专用 `Rewards`，写入 `EndTimeline` 地图进度并派发 `BoardEventType.FinishSpecialOrder`。分支订单按单条 `Requirement` 链清除相关物品，然后对 `Rewards` 权重列表循环抽取并把结果落到空位；空位不足和尾部事件需要运行时复核。

    **源码**：`MainBoardModel.lua:1101-1108`、`1258-1305`。Special/Branch 配置完整生效值当前未导出，标为 `runtime-pending`。
    """)
    write("operations/orders/special_detail.md", """# 特殊与分支的底层算法

    Special 的链判断先取每个 Requirement 的 `GetChainId`，再把 `GeneratorChain` 也转成链 ID；棋盘棋子若本体代码或 `ItemBubble` 内部代码属于任一需求链/生成器链，就交给 `_BatchRemoveItems` 删除。完成后调用 `RewardApi.AcquireRewardsLogic(orderConfig.Rewards, Give, SpecialTaskComplete, Main, Type2)`，设置 `MapDataModel:SetSlot(orderConfig.EndTimeline,"1")`，最后发 `FinishSpecialOrder`。

    Branch 使用单个 Requirement 的链 ID和 GeneratorChain组成清除条件；随后构造 `ItemModelFactory.GetCodeAndWeightPairs(orderConfig.Rewards)`，只要权重列表非空就调用 `Table.ListWeightSelectOne` 取一个 Code，并寻找有效空位生成奖励棋子。源码明确是循环消耗候选列表，但奖励列表为空、棋盘无空位和后续事件的完整处理需要运行时样本确认。

    **证据状态**：Special 清除、奖励、时间线和事件 `source-confirmed`；Branch 落点失败和配置实际值 `runtime-pending`。**源码**：`Board_Model_Board_MainBoardModel.lua:1258-1310`。
    """)
    write("operations/orders/finish.md", """# 订单完成、补位与同步

    需求和延迟奖励后，订单模型执行 `FinishOrder`，尝试补位，更新状态，发送完成事件并上传同步。订单 `LuckyTriggerChance` 与母体 LuckyProduce 独立；Lucky 订单可直接允许 Lucky 行为。

    **配置**：`OrderFixedConfig`、`OrderRandomConfig`、订单类型和 `LuckyTriggerChance`。**源码**：`MainOrderModel:FinishOrder`、`SlotOrderModel:FinishOrder`、`BoardEventType.FinishOrder`。网络回调、补位失败重试和异步 UI `runtime-pending`。
    """)
    write("operations/orders/finish_detail.md", """# 完成状态、补位循环和事件顺序

    普通订单由 `MainBoardModel:FinishOrder` 发放奖励并调用一次 `order:SetFinished()`；随后所属 `OrderModel:FinishOrder` 会再次调用 `SetFinished`，写完成日志并进入 `_TryFillOrders`。第二次调用复用已缓存奖励，这是源码中的双写顺序。

    `_TryFillOrders` 用 `repeat` 扫描所有空槽或 Finished 槽，只要本轮成功创建过订单就再扫一轮，直到整轮没有新订单；最后更新订单状态并记录新订单 unlock 日志。主订单模型在补位前还处理分支完成、亲密度、下一单 Lucky 资格和 `RepeatWeightDecrease` 重置。尾部顺序是 `UpdateOrderState` → OrderBoost 微笑事件（条件满足时）→ `CheckMoreUpload` → `BoardEventType.FinishOrder`；`EEventType.OrderFinished` 在槽位模型补位完成后更早发送。

    特殊订单和分支订单在 `FinishOrder` 入口直接分流到专用函数，不进入普通奖励/扣除链。订单 Lucky 使用 `LuckyTriggerChance`，与母体 LuckyProduce 机会池独立。

    **源码**：`MainBoardModel:FinishOrder`、`MainOrderModel:FinishOrder`、`SlotOrderModel:FinishOrder`、`_TryFillOrders`。
    """)
    write("operations/orders/creation.md", """# 订单创建与配置选择

    每次订单槽位为空或订单已完成时，`MainOrderModel:_TryCreateOrder` 按固定优先级尝试：Fixed、ReturnFreeOrder、Tutorial、Contiorders、ExtraCustomer、LuckyOrder，最后才是普通 Random。前一个 creator 返回非空后不会继续尝试；成功的 Random 订单若没有 ID 才由 `DBIdGenerator` 补 ID，并派发 `MainOrderCreated`。

    随机订单按 `OrderRandomConfig.Type` 选择过滤器，读取玩家等级、`DiffSum`、`First/Second/Third Min/Max`、`RefreshTime` 和 `ItemAmounts`；物品候选还要经过解锁等级、进度、禁用槽位、生成器、其它订单和上一个订单排除。`OrderItemConfig` 提供 `Code`、`DiffScore`、`Price`、`RecommendedPrice`、`UnlockLevel`、`ProgressUnlock`、`ForbiddenSlot`、`Weight`、`WeightMultiple`、`RepeatWeightDecrease`、`RecommendedNumber`、`DifficultyLevel`。

    **源码**：`MainOrderModel.lua:527-558`、`LoadFileConfig:31-86`、`MainOrderCreatorRandom.luac.txt` 原始行 119-1208。创建优先级的静态顺序 `source-confirmed`；活动/账号实际命中 `runtime-pending`。
    """)
    write("operations/orders/creation_detail.md", """# 随机订单过滤与抽取细节

    Random creator 首先读取类型计时器；首次创建写入服务器时间，之后要求 `serverTime - startTimer >= RefreshTime`。过滤器选择后，分别按第一、第二、第三需求的难度上下限筛候选。候选必须通过 `_CheckItemCode`，并在 `Weight > 0` 时进入累计权重池。

    需求数量从 `ItemAmounts` 的 `OneItemWeight`、`TwoItemsWeight`、`ThreeItemsWeight` 中抽取；当前 JSON 的常见类型为 50/50/0。候选代码按 `Table.ListWeightSelectOne` 选择，重复链衰减通过 `RepeatWeightDecreaseChain` 元数据改变权重；这不是永久删除全局配置项。订单完成后，涉及 `RepeatWeightDecrease > 0` 的链会重置衰减状态。

    当前本地快照：`OrderItemConfig.json` 74 行，`DiffScore` 2–3000；`OrderRandomConfig.json` 9 个 Type（1、2、3、4、9、12、15、16、21）；`OrderFixedConfig.json` 16 行。Special/Branch 配置由 Lua 配置装载，但没有完整 JSON 快照。

    **源码**：`MainOrderCreatorRandom.luac.txt` 的 `CanCreate` 119-168、`Create` 185-309、`GetAvailableItems` 671-824、`FilterByLevel` 1087-1117、`FilterByChainId` 1122-1131；**证据**：配置字段和选择顺序 `source-confirmed`，随机接口端点和运行时筛选结果 `runtime-pending`。
    """)

    # Convert merge and order mechanisms to the same clickable four-level tree
    # used by generator pages. The flat files above are staging inputs.
    operation_branches = {
        "operations/merge/dispatch": ("dispatch.md", "dispatch_detail.md"),
        "operations/merge/normal": ("normal.md", "normal_detail.md"),
        "operations/merge/special": ("special.md", "special_detail.md"),
        "operations/merge/effects/bubble": ("bubble.md", "bubble_detail.md"),
        "operations/merge/effects/activity": ("activity.md", "activity_detail.md"),
        "operations/merge/effects/coin": ("coin.md", "coin_detail.md"),
        "operations/orders/check": ("check.md", "check_detail.md"),
        "operations/orders/inventory": ("inventory.md", "inventory_detail.md"),
        "operations/orders/rewards": ("rewards.md", "rewards_detail.md"),
        "operations/orders/rewards_sources": ("rewards_sources.md", "rewards_sources_detail.md"),
        "operations/orders/remove": ("remove.md", "remove_detail.md"),
        "operations/orders/special": ("special.md", "special_detail.md"),
        "operations/orders/finish": ("finish.md", "finish_detail.md"),
        "operations/orders/creation": ("creation.md", "creation_detail.md"),
    }
    for stem, (overview_name, detail_name) in operation_branches.items():
        parent = "/".join(stem.split("/")[:-1])
        overview = DOCS / parent / overview_name
        detail = DOCS / parent / detail_name
        case_marker = "\n\n---\n\n## 贯穿案例"
        overview_text = overview.read_text(encoding="utf-8").split(case_marker, 1)[0]
        detail_text = detail.read_text(encoding="utf-8").split(case_marker, 1)[0]
        write(stem + "/index.md", overview_text)
        write(stem + "/detail.md", detail_text)
        overview.unlink()
        detail.unlink()

    effects_index = DOCS / "operations/merge/effects/index.md"
    effects_text = effects_index.read_text(encoding="utf-8")
    effects_text = effects_text.replace("(bubble.md)", "(bubble/index.md)")
    effects_text = effects_text.replace("(activity.md)", "(activity/index.md)")
    effects_text = effects_text.replace("(coin.md)", "(coin/index.md)")
    effects_index.write_text(effects_text, encoding="utf-8")

    # Effects already has a directory index; its child pages are converted by
    # the same mechanism, while the parent index remains in place.

    write("reference/evidence.md", """# 证据分级

    - `source-confirmed`：解密/反编译源码或本地配置直接确认。
    - `runtime-confirmed`：运行时回放已经确认对象身份、配置值、时序或结果。
    - `runtime-pending`：静态代码已定位，但需真实运行时、服务端配置或动态对象证据。
    - `unavailable`：当前资源没有提供且无法可靠推导，必须说明原因。

    底层节点页面必须在算法和配表旁边保留证据状态。
    """)
    write("reference/configuration.md", f"""# 配置索引

    本页只提供全局反向入口；具体配置解释放在对应底层逻辑节点中。

    {s}

    主要配置表：`ItemModelConfig`、`OrderItemConfig`、`OrderFixedConfig`、`OrderRandomConfig`、`LuckyProduceConfig`、`SystemConfig`。服务端字段没有本地实际值时，在对应机制页面标为 `runtime-pending`。
    """)
    write("verification/acceptance.md", """# 三类操作验收矩阵

    母体点击必须覆盖五种 WeightType、Lucky 机会池耗尽、Lucky 物品重复抽取、免费/二连/三连、能量不足、棋盘满、初始化/关闭/开启/CD/恢复、EnergyBoost、GeneratorBoost、Disco、SmartProduce、一次性耗尽和可恢复储备耗尽。

    拖拽与合成必须覆盖空位移动、交换、不可移动目标、普通合成、特殊棋子、ItemSwallow、Temp、Card、EnergyBubble、Bubble、Coin 和棋盘满跳过。

    订单提交必须覆盖单需求、多需求、重复需求、棋盘/库存混合、不足需求、确认窗口、奖励、Special/Branch/Lucky/Timed/Contiorder、补位、状态更新、事件和同步上传。

    每条场景保存输入、随机序列、配置快照、状态快照、事件顺序、网络交互和 UI 结果，并与复刻版逐字段比较。
    """)
    write("verification/status.md", """# 当前状态

    已完成静态入口、调用顺序、主要状态变化、随机语义和本地配置索引；三类操作已按逻辑树拆分页面。

    尚未完成最终运行时验收：服务端配置实际值、动态活动对象身份、异步回调时序、网络失败分支，以及原版与复刻版逐字段差分仍需第三阶段回放确认。
    """)

    config = """site_name: Gossip Harbor 棋盘逻辑分析
site_description: Gossip Harbor 3.98.10 board logic reverse engineering
theme:
  name: material
  language: zh
  features:
    - navigation.sections
    - navigation.indexes
    - navigation.top
    - search.suggest
    - search.highlight
    - content.code.copy
  palette:
    - scheme: default
      primary: indigo
      accent: blue
      toggle:
        icon: material/weather-night
        name: 深色模式
    - scheme: slate
      primary: indigo
      accent: blue
      toggle:
        icon: material/weather-sunny
        name: 浅色模式
markdown_extensions:
  - admonition
  - attr_list
  - pymdownx.details
  - pymdownx.superfences
  - tables
nav:
  - 母体点击:
      - 总览: operations/generator/index.md
      - 点击入口与测试循环:
          - 机制说明: operations/generator/entry/index.md
          - OnTap、测试十连和通知判定: operations/generator/entry/detail.md
      - 状态检查:
          - 总览: operations/generator/state/index.md
          - Initializing：初始化中:
              - 机制说明: operations/generator/state/initializing.md
              - 初始化计时的具体判定: operations/generator/state/initializing_detail.md
          - Closed：关闭:
              - 机制说明: operations/generator/state/closed.md
              - 关闭状态的具体判定: operations/generator/state/closed_detail.md
          - Opening：开启中:
              - 机制说明: operations/generator/state/opening.md
              - 开启中状态的具体判定: operations/generator/state/opening_detail.md
          - Opened：可产出:
              - 机制说明: operations/generator/state/opened.md
              - 可产出状态的具体判定: operations/generator/state/opened_detail.md
          - 开启、加速与时间跳过:
              - 机制说明: operations/generator/state/timing.md
              - 开启、加速和时间跳过的具体结算: operations/generator/state/timing_detail.md
          - 状态字段与计时模型:
              - 机制说明: operations/generator/state/model.md
              - 初始化字段、进度公式和恢复重置: operations/generator/state/model_detail.md
      - 空位检查:
          - 总览: operations/generator/position/index.md
          - 一次性母体落点:
              - 机制说明: operations/generator/position/disposable.md
              - 一次性落点的具体算法: operations/generator/position/disposable_detail.md
          - 可恢复母体落点:
              - 机制说明: operations/generator/position/recoverable.md
              - 可恢复落点的具体算法: operations/generator/position/recoverable_detail.md
          - 自动产出与缓存:
              - 机制说明: operations/generator/position/auto.md
              - 自动产出与缓存的具体条件: operations/generator/position/auto_detail.md
          - 棋盘满失败:
              - 机制说明: operations/generator/position/full.md
              - 棋盘满失败的具体副作用: operations/generator/position/full_detail.md
      - 能量检查:
          - 总览: operations/generator/energy/index.md
          - 是否需要能量:
              - 机制说明: operations/generator/energy/cost.md
              - 能量需求布尔值的具体来源: operations/generator/energy/cost_detail.md
          - 基础消耗与增益:
              - 机制说明: operations/generator/energy/boost.md
              - 基础消耗和倍增比率: operations/generator/energy/boost_detail.md
          - 余额不足与实际扣除:
              - 机制说明: operations/generator/energy/consume.md
              - 能量余额比较与扣除: operations/generator/energy/consume_detail.md
      - Lucky 判断:
          - 总览: operations/generator/lucky/index.md
          - Lucky 机会池:
              - 总览: operations/generator/lucky/chance/index.md
              - 读取与周期重装: operations/generator/lucky/chance/load.md
              - 随机比较: operations/generator/lucky/chance/roll.md
              - 计数扣减与保存: operations/generator/lucky/chance/commit.md
          - Lucky 物品权重:
              - 总览: operations/generator/lucky/items/index.md
              - 候选与累计权重选择: operations/generator/lucky/items/select.md
              - Smart Produce 权重修正: operations/generator/lucky/items/smart.md
              - Super/Free 产出类型: operations/generator/lucky/items/type.md
          - 免费 Lucky:
              - 总览: operations/generator/lucky/free/index.md
              - 阈值队列生成: operations/generator/lucky/free/generate.md
              - 阈值检查与消费: operations/generator/lucky/free/consume.md
          - 连续 Lucky:
              - 总览: operations/generator/lucky/continuous/index.md
              - 三连/二连触发判断: operations/generator/lucky/continuous/trigger.md
              - 连续状态写入: operations/generator/lucky/continuous/state.md
              - 连续状态消费与失效: operations/generator/lucky/continuous/consume.md
      - 普通产出:
          - 总览: operations/generator/output/index.md
          - Fixed:
              - 机制说明: operations/generator/output/fixed.md
              - Fixed 的具体选择: operations/generator/output/fixed_detail.md
          - Decremental:
              - 机制说明: operations/generator/output/decremental.md
              - Decremental 的具体选择: operations/generator/output/decremental_detail.md
          - OrderItem:
              - 机制说明: operations/generator/output/order.md
              - OrderItem 的具体选择: operations/generator/output/order_detail.md
          - ChestCustomItem:
              - 机制说明: operations/generator/output/chest.md
              - ChestCustomItem 的具体选择: operations/generator/output/chest_detail.md
          - SmartItem:
              - 机制说明: operations/generator/output/smart.md
              - SmartItem 的具体选择: operations/generator/output/smart_detail.md
      - 扣除次数与 CD 恢复:
          - 总览: operations/generator/lifecycle/index.md
          - 次数扣除、变换与销毁:
              - 机制说明: operations/generator/lifecycle/count.md
              - 次数扣除、变换和销毁顺序: operations/generator/lifecycle/count_detail.md
          - CD、加速与恢复:
              - 机制说明: operations/generator/lifecycle/cooldown.md
              - CD、加速和恢复结算: operations/generator/lifecycle/cooldown_detail.md
      - 事件与后续影响:
          - 总览: operations/generator/events.md
          - 资源与属性事件:
              - 机制说明: operations/generator/events/resource.md
              - 资源事件的具体监听链: operations/generator/events/resource_detail.md
          - 棋盘事件:
              - 机制说明: operations/generator/events/board.md
              - 棋盘事件的具体写入顺序: operations/generator/events/board_detail.md
          - 活动、日志和 UI 副作用:
              - 机制说明: operations/generator/events/side_effects.md
              - 副作用的具体字段: operations/generator/events/side_effects_detail.md
      - 产出改写与安全边界:
          - 总览: operations/generator/overrides/index.md
          - Lucky、Disco 与产出改写:
              - 机制说明: operations/generator/overrides/activity/index.md
              - 活动改写的具体顺序: operations/generator/overrides/activity/detail.md
          - 能量增益与链升级:
              - 机制说明: operations/generator/overrides/boost/index.md
              - 链升级和 FishNet 具体算法: operations/generator/overrides/boost/detail.md
          - 数值安全修正:
              - 机制说明: operations/generator/overrides/safety/index.md
              - 次数与储备上限修正: operations/generator/overrides/safety/detail.md
  - 棋子拖拽与合成:
      - 总览: operations/merge/index.md
      - 拖拽分派与移动:
          - 机制说明: operations/merge/dispatch.md
          - 分支顺序与移动交换算法: operations/merge/dispatch_detail.md
      - 普通合成:
          - 机制说明: operations/merge/normal.md
          - 合成原子操作与事件顺序: operations/merge/normal_detail.md
      - 特殊棋子与吞噬:
          - 机制说明: operations/merge/special.md
          - 升级、降级和吞噬的具体算法: operations/merge/special_detail.md
      - 合成副产物:
          - 总览: operations/merge/effects/index.md
          - 普通气泡:
              - 机制说明: operations/merge/effects/bubble.md
              - 概率修正与随机判定: operations/merge/effects/bubble_detail.md
          - 卡牌、能量气泡和临时棋子:
              - 机制说明: operations/merge/effects/activity.md
              - 互斥顺序与落点算法: operations/merge/effects/activity_detail.md
          - 金币:
              - 机制说明: operations/merge/effects/coin.md
              - 合成等级与金币落点: operations/merge/effects/coin_detail.md
  - 订单提交:
      - 总览: operations/orders/index.md
      - 可交付判断:
          - 机制说明: operations/orders/check.md
          - 重复需求与计数来源: operations/orders/check_detail.md
      - 库存确认与补交:
          - 机制说明: operations/orders/inventory.md
          - 确认窗口的边界与待追踪调用: operations/orders/inventory_detail.md
      - 奖励结算:
          - 机制说明: operations/orders/rewards.md
          - 奖励、价格和活动副作用顺序: operations/orders/rewards_detail.md
      - 奖励来源与配置字段:
          - 机制说明: operations/orders/rewards_sources.md
          - 奖励来源的底层追加顺序: operations/orders/rewards_sources_detail.md
      - 需求扣除:
          - 机制说明: operations/orders/remove.md
          - 棋盘优先与仓库兜底: operations/orders/remove_detail.md
      - 特殊与分支订单:
          - 机制说明: operations/orders/special.md
          - 特殊与分支的底层算法: operations/orders/special_detail.md
      - 订单完成、补位与同步:
          - 机制说明: operations/orders/finish.md
          - 完成状态、补位循环和事件顺序: operations/orders/finish_detail.md
      - 订单创建与配置选择:
          - 机制说明: operations/orders/creation.md
          - 随机订单过滤与抽取细节: operations/orders/creation_detail.md
"""
    # Point branch labels at their new index pages while keeping the readable
    # mechanism/detail labels beneath them.
    for stem in branch_pages:
        old_overview, old_detail = branch_pages[stem]
        config = config.replace(
            "operations/generator/" + old_overview,
            "operations/generator/" + stem + "/index.md",
        ).replace(
            "operations/generator/" + old_detail,
            "operations/generator/" + stem + "/detail.md",
        )
    for stem, (old_overview, old_detail) in operation_branches.items():
        parent = "/".join(stem.split("/")[:-1])
        config = config.replace(
            parent + "/" + old_overview,
            stem + "/index.md",
        ).replace(
            parent + "/" + old_detail,
            stem + "/detail.md",
        )
    config = config.replace(
        "operations/generator/events.md",
        "operations/generator/events/index.md",
    )
    # Material's navigation.indexes makes a section title a real link when
    # its first child is the section's index document.  The old labels
    # ("机制说明"/"总览") made every branch expand-only, so the reader could
    # not open the mechanism page by clicking the tree node itself.
    config = config.replace("机制说明: operations/", "operations/")
    config = config.replace("总览: operations/", "operations/")
    (SITE / "mkdocs.yml").write_text(textwrap.dedent(config).lstrip(), encoding="utf-8")
    subprocess.run(["mkdocs", "build", "--clean", "--config-file", str(SITE / "mkdocs.yml")], cwd=SITE, check=True)
    print(f"built {SITE / 'site'}")


if __name__ == "__main__":
    main()
