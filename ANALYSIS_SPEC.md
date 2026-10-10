# Gossip Harbor 分析项目规范

## 目标

后续每个分析项目都应形成一条可复核链路：原始提取数据 -> 标准化数据 -> 分析脚本 -> 独立 HTML 报告 -> 结论与证据边界。HTML 是面向阅读和复查的交付物，JSON/CSV 是面向复算和复用的中间产物。

## 已有分析项

### 1. 棋子机制

- 构建脚本：`tools/build_pricing_analysis.py`、`tools/build_html_report.py`
- 数据产物：`analysis_output/diamond_pricing_analysis.json`、`analysis_output/diamond_pricing_analysis.csv`
- HTML：`analysis_output/gossip_harbor_piece_mechanics.html`
- 主题：棋子商店价格、普通气泡价格、母体 CD 加速成本、标准订单金币、产出池概率与状态机。
- 现有可视化：棋子明细筛选、母体 CD 模拟器、气泡机制说明、订单金币口径、桌面/移动端布局。

### 2. 剧情金币需求数据

- 构建脚本：`tools/build_f2p_progress_analysis.py`
- 数据产物：`analysis_output/f2p_progress_data.json`
- 展示位置：`analysis_output/gossip_harbor_terminal_simulation.html` 的“剧情金币需求” tab
- 主题：配置剧情任务的逐日与逐任务金币需求。
- 现有可视化：剧情日金币分布、逐日成本、任务金币查询。

### 3. 订单机制

- 构建脚本：`tools/build_order_refresh_html.py`
- 数据输入：`analysis_data/json/OrderRandomConfig.json`、`OrderFixedConfig.json`、`OrderItemConfig.json`
- HTML：`analysis_output/gossip_harbor_order_mechanics.html`
- 主题：订单类型、槽位独立 CD、解锁等级、过滤档、物品权重、固定/活动/基线订单机制。
- 定量产物：`analysis_output/order_quant_analysis.json`，按 Filter 计算首/二/三级等级范围、候选数量、数量权重、期望金币、期望体力和金币/体力。
- 现有可视化：刷新矩阵筛选、定量期望表、活动/特殊订单触发表、生成流程、固定订单表、证据边界说明。

### 4. 主棋盘终极模拟

- 模拟脚本：`tools/run_terminal_simulation.py`
- 报告脚本：`tools/build_terminal_simulation_report.py`
- 数据产物：`analysis_output/terminal_simulation_results.json`、`analysis_output/terminal_simulation_daily.csv`
- HTML：`analysis_output/gossip_harbor_terminal_simulation.html`
- 数据依赖：`analysis_output/f2p_progress_data.json`；先运行 `tools/build_f2p_progress_analysis.py`，再运行报告脚本。
- 主题：0 氪、中氪、顶氪三类钻石消费策略在全解锁、无限棋盘条件下完成全部主线的时间、资源和最终库存对比。
- 现有可视化：模拟结果、模拟设定、剧情金币需求三个 tab；结果含日期-累计金币、日期-主线完成次数、钻石分类账、30 局明细和最终库存汇总/逐局明细。

### 5. 第一阶段：全量资源恢复与验收

- 方案：`GH_LOGIC_RECOVERY_PLAN.md`
- 构建脚本：`tools/audit_gh_resources.py`、`tools/build_stage1_report.py`；独立核验：`tools/verify_gh_stage1.py`
- 证据索引：`analysis_data/logic_index/`，保留资源、对象、Lua 模块与函数、原生类型、数据库和失败项索引。
- 报告：`analysis_output/logic_recovery/STAGE1_REPORT.md`、`stage1_inventory.html`、`stage1_report_data.json`
- 范围：3.98.10 四个 APK 与保存的 2026-09-22 远端 catalog；不代表服务端与所有账号资源。
- 状态：已达到当前样本的恢复边界；严格全量验收尚未通过，唯一资源阻断项为 318 个分离动画缺少匹配骨架（逐项穷尽检查全部 1,115 个骨架）。555 个动画均已完整解析原始编码并逐字节回编码。
- 本轮补齐：4 个 AppsFlyer 载荷内的 4 个 DEX/15 个类、assets/dic 的 x86 ELF、最后 5 个 Unity 对象布局、9 处 Lua 源码差异；全部 3,415 个 Lua 内容块结构一致。
- 后续可分析项：原生方法高层解释、Java 报错处高层重建、两份 SDK 配置字段语义、版本生效规则与全部玩法调用链；底层代码已取得，不宣称无法解决。
- 口径：生成源码行数不是原始代码行数；C# 声明不计为恢复实现；完整保留与完整解码分开验收。

## 文件层级结构

```text
Gossip_Harbor_Analysis/
├─ analysis_data/
│  ├─ json/                 # 已标准化、可直接分析的配置数据
│  ├─ bundles/              # Unity Addressables 原始/中间 bundle
│  └─ lua_modules/          # 解密/提取后的 Lua 字节码
├─ apk_extract/             # APK 解包、运行时文件、配置索引与提取结果
├─ tools/                   # 提取、解析、计算、HTML 构建脚本
├─ analysis_output/         # 最终 JSON/CSV/HTML/截图，不放业务逻辑
├─ ANALYSIS_SPEC.md         # 本规范文档
└─ luac.out                 # 临时/人工检查产物，不能作为正式数据源
```

### 职责边界

- `analysis_data`：只放可复用的输入数据，不在这里写结论。
- `tools`：完成解析、清洗、计算和 HTML 构建；脚本应可重复运行。
- `analysis_output`：只放可交付结果；文件名要能表达主题和版本。
- `apk_extract`：保留原始证据，分析脚本不要直接修改它。
- 新分析项目至少应有一个构建脚本、一个结构化数据产物和一个独立 HTML。

## 新分析项简要规范

### 1. 命名

- 脚本：`tools/build_<topic>_analysis.py` 或 `tools/build_<topic>_html.py`。
- 数据：`analysis_output/<topic>_data.json`，明细可另存 `<topic>.csv`。
- 页面：`analysis_output/gossip_harbor_<topic>.html`。
- 截图：`analysis_output/<topic>-desktop.png`、`<topic>-mobile.png`。

### 2. 数据与口径

- 所有来源路径、版本号、提取日期和单位必须写入 JSON 元数据或 HTML 页脚。
- 原始字段与派生字段分开命名；派生指标注明公式、聚合方式和过滤条件。
- 对“配置确认”“代码确认”“合理推断”“无法确认”分级，不把推断写成确定事实。
- 时间统一使用秒或明确的时区；金币、钻石、概率、价格不要混用单位。
- 缺失值使用 `null`，页面显示为“—”，不能用 0 代替未知。
- 定量分析必须给出计算公式、权重归一化方式、样本/候选池范围和未计入因素；“期望”必须注明是配置级理论值、状态条件值还是实测值。
- 体力性价比类分析统一支持以下基线：基础子体=1体力，等级 `L` 棋子消耗 `2^(L-1)` 个基础子体；订单金币使用对应配置的 `Price`，指标为 `期望金币 / 期望体力`。
- 订单类定量分析至少输出：每个类型、每个 Filter 的首/二/三级等级范围、每个位置候选数与权重、1/2/3件数量权重、期望金币、期望体力、金币/体力。
- 数量期望必须按订单结构展开：First 永远计入；Second 在 2 件或 3 件订单中计入；Third 仅在 3 件订单中计入，不能把三件订单误算成独立的第二/第三概率。
- 对没有显式 `ItemAmounts` 的类型，必须标出数量权重的实际来源（例如 `OrderItemNumberWeightConfig` 的适用等级行），不能把回退值写成配置字段。
- 对动态排除、库存、重复权重、免费生成器和活动远端配置，必须单列“未计入因素”，不能把理论期望写成玩家实际期望。

### 3. HTML 结构

每个报告至少包含：

1. 标题、数据版本、数据源和分析范围；
2. 3-5 个摘要指标；
3. 首屏结论或注意事项；
4. 可筛选的明细表；
5. 至少一个能解释机制或比较关系的图表/流程；
6. 口径、公式、限制和证据边界；
7. 移动端响应式布局。

定量报告还必须包含：

- 一个可复算的中间 JSON/CSV；
- 至少一个按分段/类型展开的定量明细表；
- 关键公式和数量权重；
- 极值、均值或分位数的定义；
- 活动订单的触发条件、开放条件、时间/CD 入口和奖励是否计入指标的说明。
- 订单机制分析必须说明：逻辑槽位总数与实际普通随机槽位的区别、单槽同时订单数、订单完成后的补位循环、候选为空时的失败/回退行为，以及跨槽位需求占用和上一完成订单重复抑制的边界。
- 补位扫描必须单列“触发来源清单”：初始化/LateInit、订单完成、等级升级、OrderBoostFillOrder、ForceTryFillOrders，以及任何仅在异常/未初始化状态下存在的每秒兜底调用；必须明确扫描不等于生成，且不得把 Baseline 的资格 CD 写成后台扫描定时器。
- 补位扫描必须同时说明“单轮”和“完整补位事件”：单轮是否遍历全部槽位、成功创建一张后是否继续、何时从 Slot1 重扫、以什么条件终止；至少给出一个同轮多槽成功与失败并存的逐槽例子。
- 定量期望表必须与刷新矩阵合并到 Filter 粒度：每行包含类型、实际槽位、UnlockLevel、RefreshTime/CD、Filter 编号、Player/DiffSum/MonthPay 条件、First/Second/Third 范围、数量权重、候选数、期望金币、期望体力和金币/体力；不得只给按类型汇总值。
- 对 Player、DiffSum、MonthPay 条件必须单列“值的来源、计算/更新方式、刷新时机和区间边界”；若只能确认客户端读取入口而不能确认服务端统计口径，必须明确标注证据边界。
- 机制说明至少提供一个带玩家等级、DiffSum、当前订单占用、上一单需求和候选筛选结果的逐步推演例子；示例中的“排除”必须区分硬排除、降权/分类和唯一候选回退。
- 若创建器代码支持 `sMonthPay/eMonthPay`（或等价的 MonthPayMin/Max）条件，逐步推演例子必须同时给出 Player、DiffSum、MonthPay 的具体值、每个 Filter 的边界判断和最终命中档；若当前导出配置缺少 MonthPay 字段，必须明确标注为“机制演示配置”，不得把演示数字写成实测配置。
- 非 Random 特殊订单必须按类型说明：触发事件、开放/资格模型、实际槽位、StartTimer/RefreshTime 或非计时触发器、需求来源、完成/失败后的状态变化和补位入口；至少提供固定任务型、动态棋盘型、活动模型型各一个从触发到落地/失败的逐步推演例子。对活动远端配置缺失的类型，必须明确写出可推演的最后一步和无法确认的字段，不能用普通 Random 规则代替。
- 对 Baseline、回归免费单等动态库存型订单，“可用候选”不得作为未解释术语。必须逐项写明库存统计范围（主棋盘/仓库）、配置资格字段、其它订单需求扣减、数量门槛、抽取是否加权、最终需求数量、奖励字段、候选为空后的状态，并提供至少一个含“持有量 - 已预占量”的数字例子。
- 活动订单必须先给玩家可感知的活动名称、主题外观、入口/弹窗、选择项、倒计时、奖励方向及完成后的体验链，再解释内部 Type、Slot 和模型判定；不能只用代码类型名描述活动。无法从客户端确认的活动频率、轮数、单次时限必须明确标为未知。
- 报告首屏必须先给“玩家定位层”：每种主要订单用一句话说明用途（福利、平衡、资源消耗、剧情进度、活动冲刺、补位等），同时给出触发时机、理论最多尝试次数/天、金币/体力或奖励口径；理论次数必须明确不是保证生成次数。底层反编译流程和字段解释放在后续章节，不能让读者读完机制仍无法判断订单定位。

推荐使用“数据 JSON 内嵌到 HTML”的单文件交付方式，避免用户打开报告时依赖本地服务器或网络请求。构建阶段可以从 JSON/CSV 读取数据，但页面运行阶段不应 `fetch()` 外部文件。

### 4. 可视化规范

- 风格：浅色背景、白色内容面、细边框、低阴影、绿色作为主强调色，橙色只用于警告/口径提示。
- 布局：桌面端最大宽度约 1400-1500px；移动端单列；表格允许横向滚动但不压缩关键字段。
- 交互：筛选器要有明确标签，结果数量要实时更新；Tab/折叠区要能键盘操作。
- 图表：标题必须写清指标与单位；多系列必须有图例；图表下方注明来源、时间范围和变换方式。
- 表格：数值右对齐，单位写在表头或同一列，长文本允许换行，表头固定，缺失值统一显示“—”。
- 不使用大面积渐变、装饰性气泡、彩虹色、过度圆角或没有解释的 KPI 卡片。
- 不用巨大标题替代内容；分析工具应把实际数据和筛选入口放在首屏附近。

### 5. 验证清单

- 重新运行构建脚本，确认输出文件时间和数据版本更新。
- 用浏览器打开 HTML，检查桌面和移动宽度下无溢出、重叠、空白图表。
- 抽查至少 3 个页面值与 JSON/CSV 原始值一致。
- 对 CD、概率、价格等关键指标做边界值测试。
- 在报告中留下“已确认/未确认”说明，不隐藏数据缺口。

## 推荐的新增项目流程

1. 在 `analysis_data/json` 找到或生成标准化配置。
2. 在 `tools` 写纯数据转换和指标计算，不把业务逻辑散落到 HTML 字符串中。
3. 输出 JSON/CSV，并为派生指标写公式或字段说明。
4. 生成独立 HTML，加入筛选、明细、结论和证据边界。
5. 运行脚本并做桌面/移动端检查。
6. 更新本文件的“已有分析项”清单。
