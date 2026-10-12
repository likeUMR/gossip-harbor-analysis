# GH 阶段二进度：逻辑定位与可复跑分析

版本：Gossip Harbor 3.98.10。本文记录阶段二的工具、覆盖范围、证据边界和当前验收状态。

## 目标

阶段二的目标是建立“从玩家操作到后续逻辑”的可追踪索引，为阶段三按交互场景还原完整调用链提供入口。静态索引可以证明文件、符号、调用点和配置访问已被扫描，不能单独证明运行时分支、服务端行为或动态反射目标。

## 已完成的结构化索引

- 主逻辑索引：413,738 个符号实体。
- Lua：3,415 个模块、33,272 个原型；反编译字节码 round-trip 结构校验 3,415/3,415 通过。
- Android/Java：43,784 个类、254,729 个方法；DEX invoke 919,992 个调用点，其中 533,475 个解析到包内目标。
- IL2CPP：78,516 个方法映射，22 个原生库；所有方法地址均有原生入口记录。
- ARM64：5,394,661 条纳入函数的指令、712,596 个直接 BL、223,770 个精确命中元数据方法入口；另统计 45,301 个间接 BLR。
- Lua require：2,209 个引用，51 个当前未解析目标。

## Lua 关系索引修正

工具：`tools/build_stage2_lua_relations.py`。

- 3,415/3,415 Lua 源文件可由 Tree-sitter Lua 解析，解析状态写入 `stage2_lua_relations_summary.json`。
- 扫描前屏蔽字符串和注释，避免注释示例、字符串内容成为假调用。
- 用 AST 识别函数声明名范围，排除 `function Foo:Bar()` 被误识别为调用的假边。
- 当前索引包含 24,736 个命名函数、18,816 个 self 调用候选、49,801 个冒号限定调用候选、17,892 个裸函数调用候选、31,136 个点调用候选、1,190 个事件派发点和 1,188 个事件回调候选。
- 这些关系仍是静态候选；动态接收者、继承/混入、裸函数调用、匿名闭包、动态索引和 C#/Lua 桥接还需在场景分析中继续解析。

## 配置、状态与数据库访问

配置/状态访问索引共 3,478 个访问候选：configuration_read 163、configuration_control_or_metadata 225、resource_config_read 261、database_table 2,089、player_prefs 661、model_api_candidate 37、model_config_accessor 42。

键表共 2,117 条，覆盖 LocalConfigKey、ServerConfigKey、EGeneralConfType、EPlayerPrefKey、SystemConfigKey、UIPrefabConfigName、ScenePrefabConfigName。动态计算或未解析键表达式已单独标记，不能当作不存在。

## 玩家交互触发索引

工具：tools/build_stage2_interaction_triggers.py，数据库：interaction_triggers.sqlite3。

当前记录 7,572 个触发点：事件 3,088 个（AddListener 1,612、DispatchEvent 1,443、RemoveListener 33），异步/回调 1,673 个，Lua/C# 或模块桥接 2,811 个。3,328 个位置出现内联函数回调，2,800 个位置使用命名或表达式回调。每条记录保留模块、函数、行号、调用名和源码行，供第三阶段从玩家入口反查后续链条。

事件图进一步解析了 3,088 个事件调用点，归一化出 424 个静态事件名；686 个事件表达式和 254 个回调无法唯一静态解析，已进入未解析表并保留源码证据。工具为 tools/build_stage2_event_graph.py，数据库为 event_graph.sqlite3。

事件覆盖矩阵显示：381 个事件同时存在注册和派发点，33 个目前只有派发点，10 个目前只有注册点。矩阵文件为 stage2_event_coverage.json；这些不平衡项是第三阶段优先验证清单，不直接等同于逻辑错误。

玩家输入入口索引目前记录 2,036 个候选入口：1,657 个输入注册 API、182 个命名输入方法、197 个内联输入回调。工具为 tools/build_stage2_input_entries.py，数据库为 input_entries.sqlite3；它们还需要结合 prefab 绑定和 Unity EventSystem 确认实际可达性。

输入路径索引已将这些入口按模块、函数和源码顺序连接到 Lua 调用、事件与状态访问：2,036 个入口中 2,020 个存在静态证据，共形成 23,874 个路径项（Lua 调用 18,148、事件 4,741、状态访问 985）。工具为 tools/build_stage2_input_paths.py，数据库为 input_paths.sqlite3。当前仍属于候选路径，跨函数和跨语言边需要继续展开。

跨函数可达性索引已沿唯一解析的 Lua 调用边展开到固定点：1,010 个输入函数根、33,723 个可达函数记录；实际最大路径深度 15，允许上限 24，未触及上限；867 个根可到达事件函数，422 个根可到达状态访问函数。另通过同模块唯一方法名解析恢复了 905 条 `self:Method` 动态函数边。工具为 tools/build_stage2_input_call_reachability.py，数据库为 input_call_reachability.sqlite3。动态接收者、跨语言桥接和未解析候选仍单独保留为语义验收项。

Lua/C# 桥接索引从 2,811 个桥接触发候选中提取出 602 个明确的 CS.* 表达式，覆盖 245 个不同桥接名。表达式已细分为 18 个唯一成员方法、36 个多候选成员方法、60 个构造器候选、39 个未解析构造器，以及 449 个静态/实例字段或属性访问；后者不应误报为“方法缺失”。工具为 tools/build_stage2_lua_bridge_index.py，数据库为 lua_bridge.sqlite3。参数、对象类型、继承实现和运行时 overload 仍需在场景分析中继续确认。

网络/API 调用索引记录 15,527 个 API 或 GM 模型/管理器调用，989 个字面请求名，8,003 个内联回调和 1,575 个回调表达式。显式 ApiMessage 调用与 GM 封装调用保留在同一张表中，以免漏掉业务层网络封装；工具为 tools/build_stage2_network_calls.py，数据库为 network_calls.sqlite3。

网络回调 AST 索引已对可识别的匿名回调建立体内副作用记录：16 个回调、14 个 UI 副作用，另有 55 个回调需要继续解析。工具为 tools/build_stage2_network_callback_effects.py，数据库为 network_callback_effects.sqlite3；网络调用表中的“回调候选”仍包含命名回调和宽松 API 候选，不能直接当作实际匿名回调数量。

命名网络回调索引按 callback/cb/onSuccess/onError/handler、self.Method 等形态筛出 2,317 个候选表达式，其中 113 个能唯一对应 Lua 方法，44 个有多个同名候选；26 个唯一方法已关联到事件或状态副作用。工具为 tools/build_stage2_named_network_callbacks.py，数据库为 named_network_callbacks.sqlite3。该表保留候选口径，避免把普通参数误报成确定回调。

回调变量赋值传播进一步扫描出 5,095 个简单赋值，发现 212 个网络调用参数可由同函数变量回溯到方法表达式；其中 78 个唯一、51 个多候选、83 个未解析。工具为 tools/build_stage2_callback_assignments.py，数据库为 callback_assignments.sqlite3。

## IL2CPP Dumper 与原生索引

已对当前 `libil2cpp.so` 与 `global-metadata.dat` 成对运行 Il2CppDumper，保存 `dump.cs`、`script.json`、`il2cpp.h`、字符串表和 DummyDll。输入哈希、版本、映射哈希均写入 `stage2_il2cpp_dumper_run.json`。

原生索引由 ARM64 汇编构建，能把方法元数据入口、汇编范围和直接 BL 目标关联起来。shared generic、thunk、间接调用和优化后的高层语义仍需反编译器或运行时证据确认。

## 调试工具发现

详见 [STAGE2_DEBUG_TOOLS.md](STAGE2_DEBUG_TOOLS.md)。静态证据确认客户端内置 LuaPanda 和 EmmyLua 集成：`LuaManager.Initialize` 调用 `LuaDebugHelper.AddDefaultDebugger`；`lua.debugger` 默认值为 2，映射到 LuaPanda，EmmyLua 使用 9966 端口，LuaPanda 使用 8818 端口并读取 `TestDebugAddress`。包内还包含 LuaDebugTool、XLua 检查接口、Lua profiler 相关程序集。

目前没有设备连接或 IDE 会话证据，因此不能宣称默认偏好在目标设备上实际启用，也不能把静态存在等同于运行时可用。

## 当前验收状态

动态包装器直接效果索引：`tools/build_stage2_dynamic_wrapper_index.py`，数据库 `dynamic_wrapper_effects.sqlite3`。针对语义覆盖矩阵中的动态回调缺口，定位到 82 个相关函数包装器、17 个直接证据和 188 个动态调用候选；其中 4 个是明确空实现或保护性返回，13 个是 UI/网络操作。其中 5 个输入根可确认包装器自身已经执行 UI/网络等效果，但被转交的对象或配置回调目标仍未唯一确定，因此单独标为 `direct_wrapper_effect_unresolved_target`，不把它们冒充为完整调用链。该索引补充了“已知效果”和“未知目标”的边界证据。

动态对象字段转发索引：`tools/build_stage2_dynamic_forwarding.py`，数据库 `dynamic_forwarding.sqlite3`。对全部 24,736 个 Lua 函数扫描对象字段方法调用，建立 25,039 个字段转发调用、16,936 个字段赋值和 10,711 个同模块字段候选连接；方法名层面有 6,989 个唯一候选、15,476 个多候选、2,574 个未解析。该索引覆盖 `self.m_window:OnStarClicked(...)`、`self.m_chooseWindow:OnCellClicked(...)`、`self.m_tipButton:OnClicked()` 等之前未进入 Lua 关系图的调用形式，并明确保留对象身份与继承分派的不确定性。

输入语义覆盖矩阵：`tools/build_stage2_semantic_coverage.py`，数据库 `semantic_coverage.sqlite3`。按源文件和函数符号严格连接后，1,010 个输入根中 993 个在静态可达链上出现事件、状态、网络或桥接后续证据；另有 4 个根已确认是空实现或保护性返回，5 个根有包装器直接效果但动态目标未唯一确定，3 个根已发现动态对象字段转发，3 个动态回调已有字段候选连接，2 个已有函数值副作用候选，合计 17 个非完整链条根已导出到 `stage2_semantic_gaps.json`。872 个可达事件，874 个可达状态（包含直接对象字段变更），684 个可达网络调用，926 个可达桥接表达式，344 个可达随机机制，369 个可达配置访问。该矩阵是逐根验收清单，不能把“有静态证据”替代运行时分支验证。

当前静态验收：所有 1,010 个输入根均已落入明确分类，没有 `dynamic_callback_unresolved`、`no_reachable_function` 或 `logic_only_no_indexed_effect`。结构验收工具因此将语义状态标记为 `static_candidate_complete_runtime_unverified`：这表示每个入口都有源码级证据或明确的候选链条，但不宣称服务端下发分支、运行时对象身份、继承分派和实际设备调试行为已经完成验证。这些运行时验证属于阶段三的交互回放验收，不再是阶段二的“未知入口”缺口。

动态回调字段索引：`tools/build_stage2_dynamic_callbacks.py`，数据库 `dynamic_callbacks.sqlite3`。共发现 411 个字段调用、633 个字段赋值候选，其中 264 个字段候选可连接，204 个调用仍未连接。连接只说明同模块字段名或末端字段名相同，不证明同一个对象、赋值时序或实际活动目标；这 204 个未连接调用是场景验证优先项。

动态 `self:Method` 修复：`tools/fix_stage2_dynamic_self_calls.py`。在同一模块内找到唯一方法时恢复 905 条调用边，另标记 29 条多候选边；这使输入可达函数从 32,315 增至 33,723，直接状态变更索引接入后动态回调入口缺口从 96 个降至 30 个。该修复不跨模块猜测类继承，也不把多候选边当作确定调用。

直接状态变更索引：`tools/build_stage2_state_mutations.py`，数据库 `state_mutations.sqlite3`。记录 18,731 个直接状态赋值，其中 18,670 个对象字段变更、61 个全局模型赋值；这补上了 `self.m_startPos = eventData.position` 这类不经过 Set/Save API 的玩家操作后果。

动态回调函数值副作用索引：`tools/build_stage2_dynamic_callback_effects.py`，数据库 `dynamic_callback_effects.sqlite3`。发现 131 个函数值定义、186 个副作用位置和 347 个字段名候选连接，其中状态赋值 66、UI 调用 117、事件派发 3。字段名连接仍是候选，不能替代对象身份和赋值时序证明。

## 随机、权重与抽样机制索引

工具：`tools/build_stage2_random_mechanisms.py`；数据库：`random_mechanisms.sqlite3`。

扫描全部 3,415 个 Lua 模块后记录 1,967 个候选机制：262 个普通随机调用、62 个权重选择调用、150 个明确的 `table.remove` 候选删除点，以及 1,493 个候选集合修改点；另记录 5,857 个 `Weight`/`Spread_Weight` 等配置字段出现位置。每条记录保留模块、函数、行号、调用参数、候选集合、数量/权重表达式和源码行。

判定采用证据分级。共享工具实现已恢复：`ListRandomSelectN` 在数量小于候选数时对传入列表原地执行“随机索引 + `table.remove`”，属于无放回抽样；`ListAlwaysRandomSelectN` 先深拷贝候选，再在拷贝上删除，属于无放回但不修改调用方列表；`MathUtil.RandomN` 通过已选索引映射校正位置，也返回不重复索引；`ListRandomSelectOne` 不删除候选，重复调用可重复；`ListWeightSelectOne` 按默认 `Weight` 或传入字段的累计权重区间抽取。`MathUtil.Random` 的单参数结果为 `floor(math.random()*l)+1`，双参数结果为 `l+floor(math.random()*(r-l+1))`，整数端点包含；测试模式可由 `TestModel` 改变浮点随机区间。当前卡牌生成逻辑也具备明确证据：随机索引从 `lackCardIds`/`cardIds` 取元素后立即删除，后续抽取使用缩短后的集合。权重调用还需把每个配置表的字段值、零权重和动态权重来源逐项关联，才能形成具体概率报告。

权重数值索引：`tools/build_stage2_weight_config_index.py`；数据库：`weight_config.sqlite3`。当前提取 3,830 个可见数值记录（Lua 2,868、JSON 962）、62 个权重选择调用、28 个字段分组；零值 528 个、负值 0 个。该表把字段、数值、文件、行号和上下文保留下来，用于计算具体概率；服务器下发或运行时重写的权重仍单独标记为待追踪项。

结构验收：通过。阶段二纳入的全部索引数据库完整性、源码位置、IL2CPP 方法/入口覆盖和 Dumper/native 输入一致性均通过 `tools/verify_stage2_index.py`。

语义验收：未通过。剩余工作包括场景驱动的跨 Lua/C# 调用链、异步回调与定时器生命周期、数据库字段读写传播、未解析配置表达式、IL2CPP 间接调用和运行时调试验证。

阶段二只有在每类核心玩家操作都能从入口追踪到状态变化、持久化/网络副作用和 UI 结果，并且每个断点都有源码、字节码或运行时证据时，才可进入阶段三。
